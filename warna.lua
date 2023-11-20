local warna = {}

local on_windows = package.config:sub(1, 1) == "\\"

local function log_warn(...)
    if not warna.log_warn then return end

    io.stderr:write("[warna] "..table.concat({...}, " ").."\n")
end

function warna.windows_enable_sequence()
    local ok, ffi = pcall(require, "ffi")
    if not ok and ffi then
        ok, ffi = pcall(require, "cffi")
        if not ok and ffi then
            log_warn("'ffi' nor 'cffi' is found, calling from CMD to enable...")
        end
    end

    if (not ok and not on_windows) or
       (ok and ffi.os ~= "Windows") then
        return false
    end

    if not ok and on_windows then
        local code
        if _VERSION == "Lua 5.1" then
            code = os.execute("REG ADD HKCU\\CONSOLE /f /v VirtualTerminalLevel /t REG_DWORD /d 1 2>1 1>NUL")
        else
            _, _, code = os.execute("REG ADD HKCU\\CONSOLE /f /v VirtualTerminalLevel /t REG_DWORD /d 1 2>1 1>NUL")
        end

        return code == 0
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
end

return function()
    return warna
end
