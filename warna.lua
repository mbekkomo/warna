local warna = {}

local on_windows = package.config:sub(1, 1) == "\\"

---@param cmd string
---@return integer
local function execute_cmd(cmd)
    local code
    if _VERSION == "Lua 5.1" and not jit then
        code = os.execute(cmd)
    else
        _, _, code = os.execute(cmd)
    end
    return code ---@diagnostic disable-line:return-type-mismatch
end

---@param cmd string
---@param raw boolean?
---@return string?
local function cmd_output(cmd, raw)
    local fd, err = io.popen(cmd, "r")
    local output
    if fd and not err then
        output = fd:read("*a")
        fd:close()
    else
        return
    end
    if raw then
        return output
    end

    output = output:gsub("^%s+", ""):gsub("%s+$", "")

    return output
end

--- Patch the Windows SGR sequences problem.
---
--- Requires Windows 10 build after 14393 (Anniversary update) and `ffi` or [`cffi`](https://github.com/q66/cffi-lua) to patch.
--- If not fallbacks to editing registry.
---
--- For Windows 10 before build 14393 (Anniversary update) or before Windows 10, requires [ANSICON](https://github.com/adoxa/ansicon) to patch.
---@param skip_registry boolean Skip method where editing registry is necesarry
---@return boolean # Wether it successfully enable SGR
---@return string # A short message with which method of the function is using
function warna.windows_enable_sequences(skip_registry)
    local ok, ffi = pcall(require, "ffi")
    if not ok and ffi then
        ok, ffi = pcall(require, "cffi")
    end

    if not (ok and on_windows) or (ok and ffi.os ~= "Windows") then
        return false, "not windows"
    end

    local _, ver = (cmd_output("ver") or ""):match("(%[Version (.+)%])$")
    local winver, buildver = ver:match("^(%d+%.%d+)%.(%d+)")

    if ver and (tonumber(winver) >= 10 and not buildver >= "14393") or tonumber(winver) < 10 then
        return execute_cmd((os.getenv("ANSICON") or "ansicon") .. " -p 2>1 1>NUL") == 0, "ansicon method"
    end

    if not ok and on_windows then
        if skip_registry then
            return false, "registry method"
        end

        if execute_cmd("reg query HKCU\\CONSOLE /v VirtualTerminalLevel 2>1 1>NUL") == 0 then
            return true, "registry method"
        end

        io.stderr:write("This script will attempt to edit Registry to enable SGR, allow? [Yy/n...]")
        local yn = io.read(1)

        return yn:lower() == "y"
                and execute_cmd("reg add HKCU\\CONSOLE /f /v VirtualTerminalLevel /t REG_DWORD /d 1 2>1 1>NUL") == 0
            or false, "registry method"
    end

    -- stylua: ignore
    ffi.cdef[[
    /* borrowed from https://github.com/malkia/luajit-winapi */

    typedef uintptr_t UINT_PTR;

    typedef int32_t BOOL;
    typedef uint32_t DWORD;

    typedef UINT_PTR HANDLE;
    typedef HANDLE WINAPI_FILE_HANDLE;
    typedef DWORD WINAPI_ConsoleModeFlags;
    typedef DWORD WINAPI_StdHandle;

    BOOL SetConsoleMode(HANDLE hConsoleHandle, WINAPI_ConsoleModeFlags dwMode);
    WINAPI_FILE_HANDLE GetStdHandle(WINAPI_StdHandle nStdHandle);
    ]]

    local winapi = ffi.load("kernel32.dll")

    return winapi.SetConsoleMode(winapi.GetStdHandle(-11), 7) ~= 0
        and winapi.SetConsoleMode(winapi.GetStdHandle(-12), 7) ~= 0, "winapi method"
end

return warna
