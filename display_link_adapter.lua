local prev_connections = {}

NON_APPLICABLE_FUNCTIONS = {
	["getCursorBlink"] = function() return false end,
	["setCursorBlink"] = function() end,
	["getTextColour"] = function() return colours.white end,
	["getTextColor"] = function() return colours.white end,
	["setTextColour"] = function(colour) end,
	["setTextColor"] = function(color) end,
	["getBackgroundColour"] = function() return colours.black end,
	["getBackgroundColor"] = function() return colours.black end,
	["setBackgroundColour"] = function(colour) end,
	["setBackgroundColor"] = function(color) end,
	["getPaletteColour"] = function(colour) return colours[colour] or colours.white end,
	["getPaletteColor"] = function(color) return colors[color] or colours.white end,
	["setPaletteColour"] = function(colour, value) end,
	["setPaletteColor"] = function(color, value) end,
	["blit"] = function(...) end,
}

local function generateGridLine(w)
	local line = {}

	for i=1, w do
		line[i] = " "
	end

	return line
end

local function generateGrid(w, h)
	local grid = {}

	for i=1, h do
		grid[i] = generateGridLine(w)
	end

	return grid
end

local function wrapLink(link_name)
	local link_peripheral = nil
	if type(link_name) == "table" then
		link_peripheral = link_name
		link_name = peripheral.getName(link_peripheral)
	elseif type(link_name) == "string" then
		link_peripheral = peripheral.wrap(link_name)
	else
		error("wrapLink: bad argument #1 (string or table expected, got " .. type(link_name) .. ")")
	end

	if prev_connections[link_name] ~= nil then
		return prev_connections[link_name]
	end

	local h, w = link_peripheral.getSize()
	local grid = generateGrid(w, h)

	local wrapped = {}

	for func_name, func in pairs(link_peripheral) do
		if type(func) == "function" then
			wrapped[func_name] = function(...)
				local result = {func(...)}
				return table.unpack(result)
			end
		end
	end

	function wrapped.getSize()
		local rows, cols = link_peripheral.getSize()
		return cols, rows
	end

	function wrapped.write(text)
		local _, y = link_peripheral.getCursorPos()
		link_peripheral.write(text)

		for i=1, #text do
			grid[y][i] = text:sub(i,i)
		end
	end

	function wrapped.clear()
		link_peripheral.clear()

		local rows, cols = link_peripheral.getSize()
		grid = generateGrid(cols, rows)
	end

	function wrapped.clearLine()
		local _, y = link_peripheral.getCursorPos()
		local _, cols = link_peripheral.getSize()
		link_peripheral.clearLine()

		grid[y] = generateGridLine(cols)
	end

	function wrapped.scroll(y)
		if type(y) ~= "number" then
			error("scroll: bad argument #1 (number expected, got " .. type(y) .. ")")
		elseif y == 0 then
			return
		end

		local rows, cols = link_peripheral.getSize()

		if y > 0 then
			for i = 1, rows do
				if grid[i + y] then
					grid[i] = grid[i + y]
				else
					grid[i] = generateGridLine(cols)
				end
			end
		elseif y < 0 then
			for i = 1, rows do
				if i + y > rows then
					local index = (i + y) - rows
					grid[index] = generateGridLine(cols)
				else
					grid[i + y] = grid[i]
				end
			end
		end

		for i = 1, rows do
			link_peripheral.setCursorPos(1, i)
			link_peripheral.write(table.concat(grid[i], ""))
		end
	end

	for func_name, func in pairs(NON_APPLICABLE_FUNCTIONS) do
		wrapped[func_name] = func
	end

	prev_connections[link_name] = wrapped

	return wrapped
end

return wrapLink