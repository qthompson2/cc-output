local update_styles = {
	on_modified = 1,
	on_function_call = 2,
}

local function _internal_error(raise_error, message)
	if raise_error then
		error(message)
	else
		return false, message
	end
end

local function createGrid(cols, rows)
	local chars = {}
	local fg = {}
	local bg = {}

	for i = 1, rows do
		chars[i] = {}
		fg[i] = {}
		bg[i] = {}
		for j = 1, cols do
			chars[i][j] = " "
			fg[i][j] = colours.toBlit(colours.white)
			bg[i][j] = colours.toBlit(colours.black)
		end
	end

	return chars, fg, bg
end

local function applyIsSupported(t)
	t.isSupported = function(function_name)
		return type(t._current_peripheral[function_name]) == "function"
	end
end

local function applyGetCursorPos(t)
	t.getCursorPos = function()
		return t._cursor_x, t._cursor_y
	end
end

local function applySetCursorPos(t)
	if type(t.isSupported) ~= "function" then
		error("applySetCursorPos: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	t.setCursorPos = function(x, y)
		if type(x) ~= "number" and type(x) ~= "nil" then
			return _internal_error(t._raise_errors, "Output.setCursorPos: bad argument #1 (number expected, got " .. type(x) .. ")")
		elseif type(y) ~= "number" and type(y) ~= "nil" then
			return _internal_error(t._raise_errors, "Output.setCursorPos: bad argument #2 (number expected, got " .. type(y) .. ")")
		end
		t._cursor_x = x or t._cursor_x
		t._cursor_y = y or t._cursor_y

		if t.isSupported("setCursorPos") then
			t._current_peripheral.setCursorPos(t._cursor_x, t._cursor_y)
		end
	end
end

local function applySetCursorBlink(t)
	if type(t.isSupported) ~= "function" then
		error("applySetCursorBlink: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	t.setCursorBlink = function(blink)
		if t.isSupported("setCursorBlink") then
			t._current_peripheral.setCursorBlink(blink)
		else
			return _internal_error(t._raise_errors, "Output.setCursorBlink: function not supported")
		end
	end
end

local function applyGetCursorBlink(t)
	if type(t.isSupported) ~= "function" then
		error("applyGetCursorBlink: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	t.getCursorBlink = function()
		if t.isSupported("getCursorBlink") then
			return t._current_peripheral.getCursorBlink()
		else
			return _internal_error(t._raise_errors, "Output.getCursorBlink: function not supported")
		end
	end
end

local function applyGetSize(t)
	t.getSize = function()
		if t._redirected then
			if peripheral.getType(t._current_peripheral) == "Create_DisplayLink" then -- Create_DisplayLinks return getSize in reverse order
				local rows, cols = t._current_peripheral.getSize()
				return cols, rows
			else
				return t._current_peripheral.getSize()
			end
		else
			return term.native().getSize()
		end
	end
end

local function applyIsColour(t)
	if type(t.isSupported) ~= "function" then
		error("applyIsColour: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	local function isColour()
		if t.isSupported("isColour") then
			return t._current_peripheral.isColour()
		else
			return _internal_error(t._raise_errors, "Output.isColour: function not supported")
		end
	end
	t.isColour = isColour
	t.isColor = isColour -- Alias for compatibility
end

local function applySetTextColour(t)
	local function setTextColour(colour)
		if type(colour) == "number" then
			if colour > 65535 or colour < 1 then
				return _internal_error(t._raise_errors, "Output.setTextColour: colour out of range (1 - 65535)")
			else
				t._current_fg = colours.toBlit(colour)
			end
		else
			return _internal_error(t._raise_errors, "Output.setTextColour: bad argument #1 (number expected, got " .. type(colour) .. ")")
		end
	end

	t.setTextColour = setTextColour
	t.setTextColor = setTextColour -- Alias for compatibility
end

local function applySetBackgroundColour(t)
	local function setBackgroundColour(colour)
		if type(colour) == "number" then
			if colour > 65535 or colour < 1 then
				return _internal_error(t._raise_errors, "Output.setBackgroundColour: colour out of range (1 - 65535)")
			else
				t._current_bg = colours.toBlit(colour)
			end
		else
			return _internal_error(t._raise_errors, "Output.setBackgroundColour: bad argument #1 (number expected, got " .. type(colour) .. ")")
		end
	end

	t.setBackgroundColour = setBackgroundColour
	t.setBackgroundColor = setBackgroundColour -- Alias for compatibility
end

local function applySetPaletteColour(t)
	if type(t.isSupported) ~= "function" then
		error("applySetPaletteColour: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	local function setPaletteColour(...)
		if t.isSupported("setPaletteColour") then
			t._current_peripheral.setPaletteColour(...)
		else
			return _internal_error(t._raise_errors, "Output.setPaletteColour: function not supported")
		end
	end

	t.setPaletteColour = setPaletteColour
	t.setPaletteColor = setPaletteColour -- Alias for compatibility
end

local function applyGetTextColour(t)
	local function getTextColour()
		return colours.fromBlit(t._current_fg)
	end

	t.getTextColour = getTextColour
	t.getTextColor = getTextColour -- Alias for compatibility
end

local function applyGetBackgroundColour(t)
	local function getBackgroundColour()
		return colours.fromBlit(t._current_bg)
	end

	t.getBackgroundColour = getBackgroundColour
	t.getBackgroundColor = getBackgroundColour -- Alias for compatibility
end

local function applyGetPaletteColour(t)
	if type(t.isSupported) ~= "function" then
		error("applyGetPaletteColour: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	local function getPaletteColour(index)
		if t.isSupported("getPaletteColour") then
			return t._current_peripheral.getPaletteColour(index)
		else
			return _internal_error(t._raise_errors, "Output.getPaletteColour: function not supported")
		end
	end

	t.getPaletteColour = getPaletteColour
	t.getPaletteColor = getPaletteColour -- Alias for compatibility
end

local function applySetTextScale(t)
	if type(t.isSupported) ~= "function" then
		error("applySetTextScale: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	end

	t.setTextScale = function(scale)
		if t._redirected then
			if t.isSupported("setTextScale") then
				t._current_peripheral.setTextScale(scale)
			else
				return _internal_error(t._raise_errors, "Output.setTextScale: function not supported")
			end
		else
			return _internal_error(t._raise_errors, "Output.setTextScale: function not supported on native")
		end
	end
end

local function applyGetTextScale(t)
	t.getTextScale = function()
		if t._redirected then
			if t.isSupported("getTextScale") then
				return t._current_peripheral.getTextScale()
			else
				return _internal_error(t._raise_errors, "Output.getTextScale: function not supported")
			end
		else
			return _internal_error(t._raise_errors, "Output.getTextScale: function not supported on native")
		end
	end
end

local function applyUpdate(t)
	if type(t.isSupported) ~= "function" then
		error("applyUpdate: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	elseif type(t._current_peripheral) ~= "table" then
		error("applyUpdate: bad argument #1 (table expected for t._current_peripheral, got " .. type(t._current_peripheral) .. ")")
	elseif type(t["_modified"]) ~= "boolean" then
		error("applyUpdate: bad argument #1 (boolean expected for t._modified, got " .. type(t._modified) .. ")")
	elseif type(t["_chars"]) ~= "table" then
		error("applyUpdate: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyUpdate: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyUpdate: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	end

	t.update = function()
		if t["_modified"] then
			local blink
			if t.isSupported("setCursorBlink") then
				blink = t.getCursorBlink()
				t.setCursorBlink(false)
			end
			for i = 1, #t["_chars"] do
				t._current_peripheral.setCursorPos(1, i)
				if t.isSupported("blit") then
					t._current_peripheral.blit(
						table.concat(t["_chars"][i]),
						table.concat(t["_fg"][i]),
						table.concat(t["_bg"][i])
					)
				else
					t._current_peripheral.write(
						table.concat(t["_chars"][i])
					)
				end
			end

			if t.isSupported("update") then
				t._current_peripheral.update()
			end
			if t.isSupported("setCursorBlink") then
				t.setCursorBlink(blink)
			end

			t["_modified"] = false
		end
	end
end

local function applyWrite(t)
	if type(t.getCursorPos) ~= "function" then
		error("applyWrite: bad argument #1 (function expected for t.getCursorPos, got " .. type(t.getCursorPos) .. ")")
	elseif type(t.setCursorPos) ~= "function" then
		error("applyWrite: bad argument #1 (function expected for t.setCursorPos, got " .. type(t.setCursorPos) .. ")")
	elseif type(t["_chars"]) ~= "table" then
		error("applyWrite: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyWrite: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyWrite: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	elseif type(t["_modified"]) ~= "boolean" then
		error("applyWrite: bad argument #1 (boolean expected for t._modified, got " .. type(t._modified) .. ")")
	end

	t.write = function(text)
		local x, y = t.getCursorPos()
		local current_row = t["_chars"][y]
		local current_fg_row = t["_fg"][y]
		local current_bg_row = t["_bg"][y]

		if current_row == nil then
			return
		end

		text = tostring(text)

		for i = 1, #text do
			local char = text:sub(i, i)
			if current_row[x + i - 1] ~= nil then
				if current_row[x + i - 1] ~= char
				or current_fg_row[x + i - 1] ~= t._current_fg
				or current_bg_row[x + i - 1] ~= t._current_bg then
					t["_modified"] = true
				end

				current_row[x + i - 1] = char
				current_fg_row[x + i - 1] = t._current_fg
				current_bg_row[x + i - 1] = t._current_bg
			end
		end

		t.setCursorPos(x + #text, y)

		if t._update_style == update_styles.on_modified then
			t.update()
		end
	end
end

local function applyBlit(t)
	if type(t.getCursorPos) ~= "function" then
		error("applyBlit: bad argument #1 (function expected for t.getCursorPos, got " .. type(t.getCursorPos) .. ")")
	elseif type(t.setCursorPos) ~= "function" then
		error("applyBlit: bad argument #1 (function expected for t.setCursorPos, got " .. type(t.setCursorPos) .. ")")
	elseif type(t["_chars"]) ~= "table" then
		error("applyBlit: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyBlit: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyBlit: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	elseif type(t["_modified"]) ~= "boolean" then
		error("applyBlit: bad argument #1 (boolean expected for t._modified, got " .. type(t._modified) .. ")")
	end

	t.blit = function(text, fg, bg)
		local x, y = t.getCursorPos()
		local current_row = t["_chars"][y]
		local current_fg_row = t["_fg"][y]
		local current_bg_row = t["_bg"][y]

		if type(text) ~= "string" then
			return _internal_error(t._raise_errors, "Output.blit: bad argument #1 (string expected, got " .. type(text) .. ")")
		elseif type(fg) ~= "string" then
			return _internal_error(t._raise_errors, "Output.blit: bad argument #2 (string expected, got " .. type(fg) .. ")")
		elseif type(bg) ~= "string" then
			return _internal_error(t._raise_errors, "Output.blit: bad argument #3 (string expected, got " .. type(bg) .. ")")
		end

		if #text ~= #fg or #text ~= #bg or #fg ~= #bg then
			return _internal_error(t._raise_errors, "Output.blit: Arguments must be the same length")
		end

		if current_row == nil then
			return
		end

		for i = 1, #text do
			local char = text:sub(i, i)
			local fg_char = fg:sub(i, i)
			local bg_char = bg:sub(i, i)
			if current_row[x + i - 1] ~= nil then
				if current_row[x + i - 1] ~= char
				or current_fg_row[x + i - 1] ~= fg_char
				or current_bg_row[x + i - 1] ~= bg_char then
					t["_modified"] = true
				end

				current_row[x + i - 1] = char
				current_fg_row[x + i - 1] = fg_char
				current_bg_row[x + i - 1] = bg_char
			end
		end
		t.setCursorPos(x + #text, y)
		if t._update_style == update_styles.on_modified then
			t.update()
		end
	end
end

local function applyClearLine(t)
	if type(t["_chars"]) ~= "table" then
		error("applyClearLine: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyClearLine: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyClearLine: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	elseif type(t.getSize) ~= "function" then
		error("applyClearLine: bad argument #1 (function expected for t.getSize, got " .. type(t.getSize) .. ")")
	end

	t.clearLine = function()
		local _, y = t.getCursorPos()
		local current_row = t["_chars"][y]
		local current_fg_row = t["_fg"][y]
		local current_bg_row = t["_bg"][y]

		if current_row == nil then
			return
		end

		local cols, _ = t.getSize()

		for i = 1, cols do
			current_row[i] = " "
			current_fg_row[i] = t._current_fg
			current_bg_row[i] = t._current_bg
		end

		t["_modified"] = true

		if t._update_style == update_styles.on_modified then
			t.update()
		end
	end
end

local function applyClear(t)
	if type(t["_chars"]) ~= "table" then
		error("applyClear: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyClear: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyClear: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	elseif type(t.getSize) ~= "function" then
		error("applyClear: bad argument #1 (function expected for t.getSize, got " .. type(t.getSize) .. ")")
	end

	t.clear = function()
		local _, rows = t.getSize()

		for i = 1, rows do
			t.setCursorPos(1, i)
			t.clearLine()
		end

		t["_modified"] = true
		t.setCursorPos(1, 1)

		if t._update_style == update_styles.on_modified then
			t.update()
		end
	end
end

local function applyScroll(t)
	if type(t.getSize) ~= "function" then
		error("applyScroll: bad argument #1 (function expected for t.getSize, got " .. type(t.getSize) .. ")")
	elseif type(t["_chars"]) ~= "table" then
		error("applyScroll: bad argument #1 (table expected for t._chars, got " .. type(t._chars) .. ")")
	elseif type(t["_fg"]) ~= "table" then
		error("applyScroll: bad argument #1 (table expected for t._fg, got " .. type(t._fg) .. ")")
	elseif type(t["_bg"]) ~= "table" then
		error("applyScroll: bad argument #1 (table expected for t._bg, got " .. type(t._bg) .. ")")
	end

	t.scroll = function(n)
		if type(n) ~= "number" then
			_internal_error(t._raise_errors, "Output.scroll: bad argument #1 (number expected, got " .. type(n) .. ")")
		elseif n == 0 then
			return -- No need to scroll if n is 0
		end

		local chars, fg, bg = {}, {}, {}
		local cols, rows = t.getSize()

		if n > 0 then
			for i = 1, rows do
				if t["_chars"][i + n] then
					chars[i] = t["_chars"][i + n]
					fg[i] = t["_fg"][i + n]
					bg[i] = t["_bg"][i + n]
				else
					chars[i] = {}
					fg[i] = {}
					bg[i] = {}
					for j = 1, cols do
						chars[i][j] = " "
						fg[i][j] = t._current_fg
						bg[i][j] = t._current_bg
					end
				end
			end
		elseif n < 0 then
			for i = 1, rows do
				if i + n > rows then
					local index = (i + n) - rows
					chars[index] = {}
					fg[index] = {}
					bg[index] = {}
					for j = 1, cols do
						chars[index][j] = " "
						fg[index][j] = t._current_fg
						bg[index][j] = t._current_bg
					end
				else
					chars[i + n ] = t["_chars"][i]
					fg[i + n] = t["_fg"][i]
					bg[i + n] = t["_bg"][i]
				end
			end
		end

		t["_chars"] = chars
		t["_fg"] = fg
		t["_bg"] = bg

		t["_modified"] = true

		if t._update_style == update_styles.on_modified then
			t.update()
		end
	end
end

local function applyCurrent(t)
	if type(t.isSupported) ~= "function" then
		error("applyCurrent: bad argument #1 (function expected for t.isSupported, got " .. type(t.isSupported) .. ")")
	elseif type(t._current_peripheral) ~= "table" then
		error("applyCurrent: bad argument #1 (table expected for t._current_peripheral, got " .. type(t._current_peripheral) .. ")")
	end

	t.current = function()
		return t
	end
end

local function applyRedirect(t)
	if type(t.getSize) ~= "function" then
		error("applyRedirect: bad argument #1 (function expected for t.getSize, got " .. type(t.getSize) .. ")")
	elseif type(t.setCursorPos) ~= "function" then
		error("applyRedirect: bad argument #1 (function expected for t.setCursorPos, got " .. type(t.setCursorPos) .. ")")
	end

	t.redirect = function(new_peripheral)
		if type(new_peripheral) == "string" then
			if new_peripheral == "native" then
				if t._redirected then
					t._redirected = false
					t._current_peripheral = term.native()
					t["_chars"], t["_fg"], t["_bg"] = createGrid(t.getSize())
					t.setCursorPos(1, 1)
				end
			else
				new_peripheral = peripheral.wrap(new_peripheral)

				if new_peripheral == nil then
					_internal_error(t._raise_errors, "Output.redirect: peripheral not found")
				end
			end
		end
		if type(new_peripheral) == "table" then
			t._redirected = true
			t._current_peripheral = new_peripheral
			t["_chars"], t["_fg"], t["_bg"] = createGrid(t.getSize())
			t.setCursorPos(1, 1)
		else
			_internal_error(t._raise_errors, "Output.redirect: bad argument #1 (table expected, got " .. type(new_peripheral) .. ")")
		end
	end
end

local function applyConfig(t)
	t.config = {}

	t._update_style = update_styles.on_function_call

	t.config.setUpdateOnModified = function(enabled)
		if type(enabled) ~= "boolean" then
			return _internal_error(t._raise_errors, "Output.config.setUpdateOnModified: bad argument #1 (boolean expected, got " .. type(enabled) .. ")")
		end
		if enabled then
			t._update_style = update_styles.on_modified
		else
			t._update_style = update_styles.on_function_call
		end
	end

	t.config.getUpdateOnModified = function()
		return t._update_style == update_styles.on_modified
	end

	t._raise_errors = true

	t.config.setRaiseErrors = function(enabled)
		if type(enabled) ~= "boolean" then
			return _internal_error(t._raise_errors, "Output.config.setRaiseErrors: bad argument #1 (boolean expected, got " .. type(enabled) .. ")")
		end
		t._raise_errors = enabled
	end

	t.config.getRaiseErrors = function()
		return t._raise_errors
	end
end

return {
	applyBlit = applyBlit,
	applyClear = applyClear,
	applyClearLine = applyClearLine,
	applyCurrent = applyCurrent,
	applyGetBackgroundColour = applyGetBackgroundColour,
	applyGetCursorBlink = applyGetCursorBlink,
	applyGetCursorPos = applyGetCursorPos,
	applyGetPaletteColour = applyGetPaletteColour,
	applyGetSize = applyGetSize,
	applyGetTextColour = applyGetTextColour,
	applyGetTextScale = applyGetTextScale,
	applyIsColour = applyIsColour,
	applyIsSupported = applyIsSupported,
	applyRedirect = applyRedirect,
	applyScroll = applyScroll,
	applySetCursorBlink = applySetCursorBlink,
	applySetCursorPos = applySetCursorPos,
	applySetBackgroundColour = applySetBackgroundColour,
	applySetPaletteColour = applySetPaletteColour,
	applySetTextColour = applySetTextColour,
	applySetTextScale = applySetTextScale,
	applyUpdate = applyUpdate,
	applyWrite = applyWrite,
	applyConfig = applyConfig,
	createGrid = createGrid,
}