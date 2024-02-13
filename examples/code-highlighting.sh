#!/usr/bin/env bash

function warna.lua
{
  [[ -f ../warna.lua ]] && lua ../warna.lua "$@"
  [[ -f ./warna.lua ]] && lua ./warna.lua "$@"
}

warna.lua "\
%{magenta}local%{reset} str %{cyan}=%{reset} %{red}string%{white dim}.%{blue}upper%{white dim}(%{green}'hello world'%{white dim})%{reset}
%{blue}print%{white dim}(%{reset}str%{white dim})
"
