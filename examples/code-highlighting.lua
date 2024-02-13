local oldpath = package.path
package.path = "../?.lua;./?.lua"

local warna = require("warna")

package.path = oldpath

print(warna.format[[
%{magenta}local%{reset} str %{cyan}=%{reset} %{red}string%{white dim}.%{blue}upper%{white dim}(%{green}'hello world'%{white dim})%{reset}
%{blue}print%{white dim}(%{reset}str%{white dim})]])
