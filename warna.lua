local ffi_ok, ffi = pcall(require, "ffi")
if not ffi_ok and ffi then
    ffi_ok, ffi = pcall(require, "cffi")
end

local on_windows = (ffi_ok and package.config:sub(1, 1) == "\\") or (ffi_ok and ffi.os ~= "Windows")

local ver, winver, buildver
if on_windows then
    local fd, err = io.popen("ver", "r")
    if fd and not err then
        local output = fd:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
        _, ver = output:match("(%[Version (.+)%])$")
        winver, buildver = ver:match("^(%d+%.%d+)%.(%d+)")
        fd:close()
    end
end

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

---@param hex string
---@return number
---@return number
---@return number
local function hex2rgb(hex)
    hex = hex:gsub("^#", "")
    ---@diagnostic disable-next-line:return-type-mismatch
    return tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6))
end

---@class warna
local warna = {}

---@class warna.options
warna.options = {
    --- Specifies the level of color support.
    ---
    ---  • `0` — Disable color support
    ---  • `1` — Basic color support (8-16 colors)
    ---  • `2` — 256 colors support
    ---  • `3` — Truecolor support (16 million colors)
    level = 0,

    ---@see warna.windows_enable_vt
    --- Wether to skip editing registry.
    skip_registry = true,
}

---@alias warna.attributes_function fun(...: string): string
---@class warna.attributes
warna.attributes = {
    reset = 0,

    bright        = 1,
    bold          = 1,
    dim           = 2,
    dark          = 2,
    italic        = 3,
    underline     = 4,
    underl        = 4,
    blink         = 5,
    inverse       = 7,
    reverse       = 7,
    hidden        = 8,
    invisible     = 8,
    strikethrough = 9,
    strike        = 9,

    black   = 30,
    red     = 31,
    green   = 32,
    yellow  = 33,
    blue    = 34,
    magenta = 35,
    cyan    = 36,
    white   = 37,
    default = 39,

    bg_black   = 40,
    bg_red     = 41,
    bg_green   = 42,
    bg_yellow  = 43,
    bg_blue    = 44,
    bg_magenta = 45,
    bg_cyan    = 46,
    bg_white   = 47,
    bg_default = 49,

    ---@type warna.attributes_function
    color256 = function(n)
        print(("\27[38;5;%sm"):format(n))
        return ("\27[38;5;%sm"):format(n)
    end,
    ---@type warna.attributes_function
    rgb = function(r, g, b)
        return ("\27[38;2;%s;%s;%sm"):format(r, g, b)
    end,
    ---@type warna.attributes_function
    hex = function(hex)
        return ("\27[38;2;%d;%d;%dm"):format(hex2rgb(hex))
    end,

    ---@type warna.attributes_function
    bg_color256 = function(n)
        return ("\27[48;5;%sm%s"):format(n)
    end,
    ---@type warna.attributes_function
    bg_rgb = function(r, g, b)
        return ("\27[48;2;%s;%s;%sm"):format(r, g, b)
    end,
    ---@type warna.attributes_function
    bg_hex = function(hex)
        return ("\27[48;2;%d;%d;%dm"):format(hex2rgb(hex))
    end
}


---@param skip_registry boolean Skip method where editing registry is necesarry.
---@return boolean # Wether it successfully enable VT esce sequences.
---@return string # A short message with which method of the function is using.
--- Patch the Windows VT escape sequences problem.
---
--- Requires Windows 10 build after 14393 (Anniversary update) and `ffi` or [`cffi`](https://github.com/q66/cffi-lua) to patch.
--- If not fallbacks to editing registry.
---
--- For Windows 10 before build 14393 (Anniversary update) or before Windows 10, requires [ANSICON](https://github.com/adoxa/ansicon) to patch.
function warna.windows_enable_vt(skip_registry)
    if not on_windows then
        return false, "not windows"
    end

    if (tonumber(winver) >= 10 and not buildver >= "14393") or tonumber(winver) < 10 then
        return execute_cmd((os.getenv("ANSICON") or "ansicon") .. " -p 2>1 1>NUL") == 0, "ansicon method"
    end

    if not ffi_ok and on_windows then
        if skip_registry then
            return false, "registry method"
        end

        if execute_cmd("reg query HKCU\\CONSOLE /v VirtualTerminalLevel 2>1 1>NUL") == 0 then
            return true, "registry method"
        end

        io.stderr:write("This script will attempt to edit Registry to enable SGR, allow? [Yy/n...]")
        local yn = io.read(1)

        return yn:lower() == "y" and execute_cmd(
            "reg add HKCU\\CONSOLE /f /v VirtualTerminalLevel /t REG_DWORD /d 1 2>1 1>NUL"
        ) == 0 or false,
            "registry method"
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

    return winapi.SetConsoleMode(winapi.GetStdHandle(-11), 7) ~= 0 and winapi.SetConsoleMode(
        winapi.GetStdHandle(-12),
        7
    ) ~= 0,
        "winapi method"
end

---@param options warna.options?
---@return warna
--- Initialize Warna module.
return function(options)
    options = options or {}
    warna.options = options

    warna.windows_enable_vt(warna.options.skip_registry)


    warna.options.level = options.level or require("warna.internal.detect_colors")

    return warna
end
