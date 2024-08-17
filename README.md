# Warna

[![GitHub License](https://img.shields.io/github/license/komothecat/warna?style=for-the-badge)](./LICENSE) [![GitHub Release](https://img.shields.io/github/v/release/komothecat/warna?display_name=release&style=for-the-badge&color=green)](https://github.com/komothecat/warna/releases/latest)<br>
![Lua](https://img.shields.io/badge/Lua-5.1_--_5.4%2C_LuaJIT-blue?style=for-the-badge&logo=lua&logoColor=lua)
[![LuaRocks](https://img.shields.io/luarocks/v/UrNightmaree/warna?style=for-the-badge&logo=lua&color=blue)](https://luarocks.org/modules/UrNightmaree/warna)


🎨 Terminal text styling library for Lua

> The name of this library is based on a word "warna", which means color in Indonesian language.
> Why did I choose this? Cuz I'm an Indonesian :P

## Installation

### Luarocks

Run the following command to install Warna.
```bash
$ luarocks install warna
```

### Manual

Copy `warna.lua` from repository tree to the path where Lua can find and require it.

## Usage

### `options`

```lua
{
    level: integer = --[[ Automatically detected ]],
}
```

- Fields:
  - `level: integer`: Specifies the level of color support.
    * `-1` — Disable escape sequences completely.
    * `0`  — Disable color support.
    * `1`  — Basic color support. (8-16 colors)
    * `2`  — 256 colors support.
    * `3`  — Truecolor support. (16 million colors)<br>

    By default, the field value is automatically detected.<br>
    Can be overridden by setting [`NO_COLOR`](http://no-color.org) environment variable, [`FORCE_COLOR`](https://force-color.org) environment variable, or directly setting the field itself.

### `attributes`
```lua
{
    colors = { [string]: function(string...): string?|string|number },
    [string]: function(string...): string?|string|number
}
```

- Fields:
  - `[string]: function(string...): string?|string|number`: For attributes that requires `options.level >= 0`
  - `colors[string]: function(string...): string?|string|number`: For attributes that requires `options.level >= 1`
    - `function(string...): string?` If the attribute accepts attribute parameters (implying the `string...`) or it's dynamic attribute and returns an escape sequence.
    - `string|number` If the attribute is static, the value of the field is automatically `tostring`'ed.

All fields in `attributes` are documented in the [list of attributes](#list-of-attributes) section.

### `windows_patch_vte`

```lua
function windows_patch_vte(skip_registry: boolean): boolean, string
```

- Parameters:
  - `skip_registry: boolean`: Skip editing the registry.
- Returns:
  - `boolean`: Wether it successfully enable VTE.
  - `string`: What method does the function used for enabling VTE.

Patch the Windows VT color sequences problem.

Requires Windows 10 build after 14393 (Anniversary update) and `ffi` or [`cffi`](https://github.com/q66/cffi-lua) library to patch.
If not fallbacks to editing registry.

For Windows 10 before build 14393 (Anniversary update) or before Windows 10, requires [ANSICON](https://github.com/adoxa/ansicon) to patch.

### `raw_apply`

> [!NOTE]
>
> This function does not resets it's escape sequence, implying it's a "raw" function.

```lua
function raw_apply(str: string, attrs: string[]): string
```

- Parameters:
  - `str: string`: String to be applied with attributes.
  - `attrs: string[]` List of attributes. Follows the syntax of an [attribute](#attribute-syntax).
- Returns:
  - `string`: The applied string.

Apply attributes to a string.

### `apply`

```lua
function apply(str: string, attrs: string[]): string
```

- Parameters:
  - `str: string`: String to be applied with attributes.
  - `attrs: string[]` List of attributes. Follows the syntax of an [attribute](#attribute-syntax).
- Returns:
  - `string`: The applied string.

Similar to [`raw_apply`](#raw_apply), except the string has `reset` attribute appended.

### `raw_format`

> [!NOTE]
>
> This function does not resets it's escape sequence, implying it's a "raw" function.

```lua
function raw_format(fmt: string): string
```

- Parameters:
  - `fmt: string`: String containing [format specifier](#format-specifier).
- Returns:
  - `string`: The formatted string.

Format a string containing [format specifier](#format-specifier).

### `format`

```lua
function format(fmt: string): string
```

- Parameters:
  - `fmt: string`: String containing [format specifier](#format-specifier).
- Returns:
  - `string`: The formatted string.

Similar to [`raw_format`](#raw_format), except the string has `reset` attribute appended.

### `strip_escapes`

```lua
function strip_escapes(str: string): string
```

- Parameters:
  - `str: string`: String containing `ESC[...m`.
- Returns:
  - `string`: Stripped string.

Strip a string containing escape sequences (`ESC[...m`).

### CLI

You can also run the `warna.lua` as CLI, which acts as a helper for styling text in shell script.

```
Usage: warna.lua <flags>
       warna.lua <fmt|text> [<attributes...>]
       warna.lua -b <fmt|text> [<attributes...>]
       warna.lua -f <fmt>
       warna.lua -a <text> [<attributes...>]

Flags: * -h -- Prints the command usage
       * -r -- Don't skip editing registry when enabling VTE in Windows.
       * -b -- Both format the text and apply attributes to the text (Default if a flag isn't supplied)
       * -f -- Format the text
       * -a -- Apply the text with attributes

<flags> can be stack up as many as you want. e.g `-ar 'My Text' red`.

Accepts NO_COLOR and FORCE_COLOR to manipulate color support.
```

## Attributes

The format specifier is similar to [`ansicolors.lua`](https://github.com/kikito/ansicolors.lua).
The following text uses LPEG's [re](https://www.inf.puc-rio.br/~roberto/lpeg/re.html) expression to specify the format syntax.
```
format <- ('%{' / '%%{') %s* attributes? %s* '}'
attributes <- attribute (' '^+1 attribute)*
attribute <- [a-zA-Z-]+ (':' [^,; ]^-0 ((',' / ';') [^,; ]^-0)*)?
```

### List of attributes

- Basic attributes <br>
  Enabled by default, i.e only enabled if `options.level >= 0`.
  - `reset`
  - `bright` or `bold`
  - `dim` or `dark`
  - `italic`
  - `underline` or `underl`
  - `blink`
  - `inverse` or `reverse`
  - `hidden` or `invisible`
  - `strikethrough` or `strike`

> [!NOTE]
>
> To use background colors, prepend the `specifier` with `bg-`.
> For example:
>   - `bg-red` to set the text background with red color.
>   - `bg-color256:93` to set the text background with 256 color code `093` or `#8700ff`.
>   - `bg-hex:#1e1e2e` to set the text background with hex color code `#1e1e2e`.

- Color attributes<br>
  Only enabled if `options.level >= 1`.
  - `black`
  - `red`
  - `green`
  - `yellow`
  - `blue`
  - `magenta`
  - `cyan`
  - `white`
  - `default`

- More color attributes<br>
  Certain color attributes only enabled if `options.level >= 2` or `options.level >= 3`.
  - `color256:(ncolor)` (Only enabled if `options.level >= 2`)
    - `ncolor`: The [Xterm 256 colors](https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg).
  - `rgb:(r),(g),(b)` (Only enabled if `options.level >= 3`)
    - `r`,`g`,`b`: RGB code.
  - `hex:(hex)` (Only enabled if `options.level >= 3`)
    - `hex`: Hex color code.
