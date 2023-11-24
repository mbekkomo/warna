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
    print "here"
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

