local record warna
	record options
		level: integer
	end

	attributes:	{string:function(...: string): string|string|integer}

	windows_patch_vte: function(boolean): boolean, string
	raw_apply: function(string, {string}): string
	raw_format: function(string): string
	apply: function(string, {string}): string
	format: function(string): string
	strip_escapes: function(string): string
end

return warna
