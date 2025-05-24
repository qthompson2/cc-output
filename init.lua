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
	local cols, rows = current_monitor_peripheral.getSize()

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

local primary_screen = createBlankScreen()
local secondary_screen = createBlankScreen()

local current_screen = primary_screen
local current_screen_name = "primary"

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

local function write(str)
	local x, y = getCursorPos()
	local current_row = current_screen["chars"][y]
	local current_fg_row = current_screen["fg"][y]
	local current_bg_row = current_screen["bg"][y]

	if current_row == nil then
		return
	end

	for i = 1, #str do
		local char = str:sub(i, i)
		if current_row[x + i - 1] ~= nil then
			if current_row[x + i - 1] ~= char
			or current_fg_row[x + i - 1] ~= current_fg
			or current_bg_row[x + i - 1] ~= current_bg then
				current_screen["modified"] = true
			end

			current_row[x + i - 1] = char
			current_fg_row[x + i - 1] = current_fg
			current_bg_row[x + i - 1] = current_bg
		end
	end

	setCursorPos(x + #str, y)
end

local function blit(text, fg, bg)
	local x, y = getCursorPos()
	local current_row = current_screen["chars"][y]
	local current_fg_row = current_screen["fg"][y]
	local current_bg_row = current_screen["bg"][y]

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
				current_screen["modified"] = true
			end

			current_row[x + i - 1] = char
			current_fg_row[x + i - 1] = fg_char
			current_bg_row[x + i - 1] = bg_char
		end
	end

	setCursorPos(x + #text, y)
end

local function clearLine()
	local x, y = getCursorPos()
	local current_row = current_screen["chars"][y]
	local current_fg_row = current_screen["fg"][y]
	local current_bg_row = current_screen["bg"][y]

	if current_row == nil then
		return
	end

	for i = 1, #current_row do
		current_row[i] = " "
		current_fg_row[i] = current_fg
		current_bg_row[i] = current_bg
	end

	current_screen["modified"] = true
	setCursorPos(1, y)
end

local function clear()
	primary_screen = createBlankScreen()
	secondary_screen = createBlankScreen()
	current_screen = primary_screen
end

local function redirect(monitor)
	if monitor == "native" then
		current_monitor = "native"
		current_screen = primary_screen
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

local function update()
	if current_screen["modified"] then
		for i = 1, #current_screen["chars"] do
			current_monitor_peripheral.setCursorPos(1, i)
			if current_monitor_peripheral.blit ~= nil then
				current_monitor_peripheral.blit(
					table.concat(current_screen["chars"][i]),
					table.concat(current_screen["fg"][i]),
					table.concat(current_screen["bg"][i])
				)
			else
				current_monitor_peripheral.write(
					table.concat(current_screen["chars"][i])
				)
			end
		end
		if current_monitor_peripheral.update ~= nil then
			current_monitor_peripheral.update()
		end

		current_screen["modified"] = false

		if current_screen_name == "primary" then
			current_screen_name = "secondary"
			current_screen = secondary_screen
		elseif current_screen_name == "secondary" then
			current_screen_name = "primary"
			current_screen = primary_screen
		end
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
}