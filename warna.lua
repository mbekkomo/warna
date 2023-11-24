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

---@return integer
local function detect_colors()
    local term = os.getenv("TERM")
    local colorterm = os.getenv("COLORTERM")
    local force_color = os.getenv("FORCE_COLOR")

    ---@cast term string
    ---@cast colorterm string

    local min = 0

    if force_color and force_color ~= "" then
        local level = tonumber(force_color)

        min = level and math.min(3, level) or 1
    end

    local no_color = os.getenv("NO_COLOR")
    if no_color and no_color  ~= "" then
        return 0
    end

    if os.getenv("TF_BUILD") and os.getenv("AGENT_NAME") then
        return 1
    end

    if term == "dumb" then
        return min
    end

    if on_windows and tonumber(winver) >= 10 and buildver > "10586" then
        return buildver >= "14931" and 3 or 2
    end

    if os.getenv("CI") then
        if os.getenv("GITHUB_ACTIONS") or os.getenv("GITEA_ACTIONS") then
            return 3
        end

        local is_ci = false
        for _, sign in pairs({ "TRAVIS", "CIRCLECI", "APPVEYOR", "GITLAB_CI", "BUILDKITE", "DRONE" }) do
            if os.getenv(sign) then
                is_ci = true
                break
            end
        end

        if is_ci or os.getenv("CI_NAME") == "codeship" then
            return 1
        end
    end

    local teamcity_env = os.getenv("TEAMCITY_VERSION")
    if teamcity_env then
        return (teamcity_env:match("^9%.(0*[1-9]%d*)%.") or teamcity_env:match("%d%d+%.")) and 1 or 0
    end

    if colorterm == "truecolor" then
        return 3
    end

    if term == "xterm-kitty" then
        return 3
    end

    local term_program = os.getenv("TERM_PROGRAM")
    if term_program then
        local version = tonumber((os.getenv("TERM_PROGRAM_VERSION") or ""):match("^(%d+)") or 0)

        if term_program == "iTerm.app" then
            return version >= 3 and 3 or 2
        elseif term_program == "Apple_Terminal" then
            return 2
        end
    end

    if term:match("%-256$") or term:match("%-256color$") then
        return 2
    end

    for _, pattern in pairs({ "^screen", "^xterm", "^vt100", "^vt220", "^rxvt", "color", "ansi", "cygwin", "linux" }) do
        if term:match(pattern) then
            return 1
        end
    end

    if colorterm then
        return 1
    end

    return min
end

---@class warna
local warna = {}

---@class warna.options
warna.options = {
    --- Wether to enable 8-16 colors, by default set to `true` if several checks returned the tty stream supports it or has `$FORCE_COLOR` set to any value or `1` or has `$NO_COLOR` empty.
    enable_colors = false,

    --- Wether to enable 256 colors, by default set to `true` if several checks returned the tty stream supports it or has `$FORCE_COLOR` set to `2` or has `$NO_COLOR` empty.
    enable_256colors = false,

    --- Wether to enable truecolor/16m colors, by default set to `true` if several checks returned the tty stream supports it or has `$FORCE_COLOR` set to `3` or has `$NO_COLOR` empty.
    enable_16mcolors = false,

    ---@see warna.windows_enable_vt
    --- Wether to skip editing registry.
    skip_registry = true,

    ---@see warna.options.enable_colors
    ---@see warna.options.enable_256colors
    ---@see warna.options.enable_16mcolors
    --- Wether to assume tty stream supports colors.
    assume_colors = false
}

--- Patch the Windows VT escape sequences problem.
---
--- Requires Windows 10 build after 14393 (Anniversary update) and `ffi` or [`cffi`](https://github.com/q66/cffi-lua) to patch.
--- If not fallbacks to editing registry.
---
--- For Windows 10 before build 14393 (Anniversary update) or before Windows 10, requires [ANSICON](https://github.com/adoxa/ansicon) to patch.
---@param skip_registry boolean Skip method where editing registry is necesarry.
---@return boolean # Wether it successfully enable VT esce sequences.
---@return string # A short message with which method of the function is using.
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
return function(options)
    options = options or {}
    warna.options = options

    warna.windows_enable_vt(warna.options.skip_registry)

    local level_color
    if warna.options.assume_colors then
        level_color = 3
    else
        level_color = detect_colors()
    end

    warna.options.enable_colors = options.enable_colors or level_color >= 1
    warna.options.enable_256colors = options.enable_256colors or level_color >= 2
    warna.options.enable_16mcolors = options.enable_16mcolors or level_color >= 3

    return warna
end
