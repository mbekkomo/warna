# warna [![GitHub License](https://img.shields.io/github/license/komothecat/warna?style=for-the-badge)](./LICENSE) [![GitHub Release](https://img.shields.io/github/v/release/komothecat/warna?style=for-the-badge)](/komothecat/warna/releases/latest)

![Lua](https://img.shields.io/badge/Lua-5.1_--_5.4%2C_LuaJIT-blue?style=for-the-badge&logo=lua&logoColor=lua)
[![LuaRocks](https://img.shields.io/luarocks/v/UrNightmaree/warna?style=for-the-badge&logo=lua&logoColor=lua)](https://luarocks.org/modules/UrNightmaree/warna)

<br>

🎨 Terminal text styling for Lua

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
    * `0` — Disable color support
    * `1` — Basic color support (8-16 colors)
    * `2` — 256 colors support
    * `3` — Truecolor support (16 million colors)<br>

    By default, the field value is automatically detected.<br>
    Can be overridden by setting [`NO_COLOR`](http://no-color.org) environment variable, [`FORCE_COLOR`](https://force-color.org) environment variable, or directly setting the field itself.

### `attributes`
```lua
{
    color = { [string]: function(string...): string?|any }
    [string]: any
}
```

- Fields:
  - `[string]: function(string...): string?|any`:
    - `function(string...): string?` If the attribute accepts attribute parameters (implying the `string...`) or it's dynamic attribute and returns an escape sequence.
    - `any` If the attribute is static, the value of the field is automatically `tostring`'ed.

All fields in `attributes` are documented in the [list attributes](#list-attributes) section.

### `windows_enable_vt`

```lua
function windows_enable_vt(skip_registry: boolean): boolean, string
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

> ![NOTE]
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

Apply string with attributes.

### `apply`

```lua
function apply(str: string, attrs: string[]): string
```

- Parameters:
  - `str: string`: String to be applied with attributes.
  - `attrs: string[]` List of attributes. Follows the syntax of an [attribute](#attribute-syntax).
- Returns:
  - `string`: The applied string.

Similar to [`raw_apply`](#raw_apply), except it resets the escape sequence.

### `raw_format`

> ![NOTE]
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

Similar to [`raw_format`](#raw_format), except it resets the escape sequence.

### CLI

You can also run the `warna.lua` as CLI, which acts as a helper for styling text in shell script.

```
Usage: warna.lua <fmt|text> [<attributes>]
       warna.lua -b <fmt|text> [<attributes>]
       warna.lua -f <fmt>
       warna.lua -a <text> [<attributes>]

Flags: * -h -- Prints the command usage
       * -b -- Both format the text and apply attributes to the text (Default if a flag isn't supplied)
       * -f -- Format the text
       * -a -- Apply the text with attributes
```

## Attributes

### Format specifier

The format specifier is similar to [`ansicolors.lua`](https://github.com/kikito/ansicolors.lua).
```
%{ [<attributes>] }
```

### Attribute syntax

The syntax of an attribute looks like this.
```
<specifier>[:<arg>[(,|;)<arg>...]]
```

### List attributes


- Basic attributes
  - `reset`
  - `bright` or `bold`
  - `dim` or `dark`
  - `italic`
  - `underline` or `underl`
  - `blink`
  - `inverse` or `reverse`
  - `hidden` or `invisible`
  - `strikethrough` or `strike`

- Color attributes
  - `black`
  - `red`
  - `green`
  - `yellow`
  - `blue`
  - `magenta`
  - `cyan`
  - `white`
  - `default`
  - `color`

- More color attributes
  - `color256:(ncolor)`
  - `rgb:(r),(g),(b)`
  - `hex:(hex)`
