local current_fg = colours.toBlit(colours.white)
local current_bg = colours.toBlit(colours.black)

local current_monitor, current_monitor_peripheral, redirected = "native", term.native(), false

local function createBlankScreen()
	local screen = {
		["chars"] = {},
		["fg"] = {},
		["bg"] = {},
		["modified"] = false
	}
	local rows, cols = current_monitor_peripheral.getSize()

	for i = 1, rows do
		screen["chars"][i] = {}
		screen["fg"][i] = {}
		screen["bg"][i] = {}
		for j = 1, cols do
			screen["chars"][i][j] = " "
			screen["fg"][i][j] = current_fg
			screen["bg"][i][j] = current_bg
		end
	end

	return screen
end

local update_style = {
	on_func_call = "on_func_call",
	on_modified = "on_modified"
}

local settings = {
	["update_style"] = update_style.on_func_call
}

local screen = createBlankScreen()

local cursor_x = 1
local cursor_y = 1

local function setCursorPos(x, y)
	cursor_x = x or cursor_x
	cursor_y = y or cursor_y
end

local function getCursorPos()
	return cursor_x, cursor_y
end

local function setTextColour(fg)
	current_fg = colours.toBlit(fg)
end

local function setBackgroundColour(bg)
	current_bg = colours.toBlit(bg)
end

local function getTextColour()
	return colours.fromBlit(current_fg)
end

local function getBackgroundColour()
	return colours.fromBlit(current_bg)
end

local function getSize()
	return current_monitor_peripheral.getSize()
end

local function redirect(monitor)
	if monitor == "native" then
		current_monitor = "native"
		current_monitor_peripheral = term.native()
		redirected = false
	else
		if type(monitor) == "string" then
			monitor = peripheral.wrap(monitor)
		end
		if monitor == nil then
			error("Output.redirect: Peripheral not found")
		end

		local type = peripheral.getType(monitor)
		if type == "monitor" then
			current_monitor = peripheral.getName(monitor)
			current_monitor_peripheral = monitor
		elseif type == "Create_DisplayLink" then
			current_monitor = peripheral.getName(monitor)
			current_monitor_peripheral = monitor
		else
			error("Output.redirect: Invalid peripheral")
		end

		redirected = true
	end
end

local function setTextScale(scale)
	if redirected then
		if current_monitor_peripheral.setTextScale ~= nil then
			current_monitor_peripheral.setTextScale(scale)
		else
			error("Output.setTextScale: Monitor does not support this function")
		end
	else
		error("Output.setTextScale: Not redirected to a monitor")
	end
end

local function getTextScale()
	if redirected then
		if current_monitor_peripheral.getTextScale ~= nil then
			return current_monitor_peripheral.getTextScale()
		else
			error("Output.getTextScale: Monitor does not support this function")
		end
	else
		error("Output.getTextScale: Not redirected to a monitor")
	end
end

local function setUpdateStyle(new_style)
	if update_style[new_style] == nil then
		error("Output.setUpdateStyle: Invalid update style")
	end
	settings["update_style"] = new_style
end

local function getUpdateStyle()
	return settings["update_style"]
end

local function update()
	if screen["modified"] then
		for i = 1, #screen["chars"] do
			current_monitor_peripheral.setCursorPos(1, i)
			if current_monitor_peripheral.blit ~= nil then
				current_monitor_peripheral.blit(
					table.concat(screen["chars"][i]),
					table.concat(screen["fg"][i]),
					table.concat(screen["bg"][i])
				)
			else
				current_monitor_peripheral.write(
					table.concat(screen["chars"][i])
				)
			end
		end
		if current_monitor_peripheral.update ~= nil then
			current_monitor_peripheral.update()
		end

		screen["modified"] = false
	end
end

local function write(str)
	local x, y = getCursorPos()
	local current_row = screen["chars"][y]
	local current_fg_row = screen["fg"][y]
	local current_bg_row = screen["bg"][y]

	if current_row == nil then
		return
	end

	for i = 1, #str do
		local char = str:sub(i, i)
		if current_row[x + i - 1] ~= nil then
			if current_row[x + i - 1] ~= char
			or current_fg_row[x + i - 1] ~= current_fg
			or current_bg_row[x + i - 1] ~= current_bg then
				screen["modified"] = true
			end

			current_row[x + i - 1] = char
			current_fg_row[x + i - 1] = current_fg
			current_bg_row[x + i - 1] = current_bg
		end
	end

	setCursorPos(x + #str, y)

	if settings["update_style"] == update_style.on_modified and screen["modified"] then
		update()
	end
end

local function blit(text, fg, bg)
	local x, y = getCursorPos()
	local current_row = screen["chars"][y]
	local current_fg_row = screen["fg"][y]
	local current_bg_row = screen["bg"][y]

	if #text ~= #fg or #text ~= #bg then
		error("Output.blit: Arguments must be the same length")
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
				screen["modified"] = true
			end

			current_row[x + i - 1] = char
			current_fg_row[x + i - 1] = fg_char
			current_bg_row[x + i - 1] = bg_char
		end
	end

	setCursorPos(x + #text, y)

	if settings["update_style"] == update_style.on_modified and screen["modified"] then
		update()
	end
end

local function clearLine()
	local x, y = getCursorPos()
	local current_row = screen["chars"][y]
	local current_fg_row = screen["fg"][y]
	local current_bg_row = screen["bg"][y]

	if current_row == nil then
		return
	end

	for i = 1, #current_row do
		current_row[i] = " "
		current_fg_row[i] = current_fg
		current_bg_row[i] = current_bg
	end

	screen["modified"] = true
	setCursorPos(1, y)

	if settings["update_style"] == update_style.on_modified and screen["modified"] then
		update()
	end
end

local function clear()
	screen = createBlankScreen()
	screen["modified"] = true

	if settings["update_style"] == update_style.on_modified and screen["modified"] then
		update()
	end
end

return {
	setCursorPos = setCursorPos,
	getCursorPos = getCursorPos,
	getTextColour = getTextColour,
	getTextColor = getTextColour,
	setTextColour = setTextColour,
	setTextColor = setTextColour,
	getBackgroundColour = getBackgroundColour,
	getBackgroundColor = getBackgroundColour,
	setBackgroundColour = setBackgroundColour,
	setBackgroundColor = setBackgroundColour,
	getSize = getSize,
	redirect = redirect,
	setTextScale = setTextScale,
	getTextScale = getTextScale,
	write = write,
	blit = blit,
	clear = clear,
	clearLine = clearLine,
	update = update,
	config = {
		setUpdateStyle = setUpdateStyle,
		getUpdateStyle = getUpdateStyle,
	}
}