local function createBlankScreen()
	local screen = {
		["chars"] = {},
		["fg"] = {},
		["bg"] = {}
	}
	local rows, cols = term.getSize()

	for i = 1, rows do
		screen["chars"][i] = {}
		screen["fg"][i] = {}
		screen["bg"][i] = {}
		for j = 1, cols do
			screen["chars"][i][j] = " "
			screen["fg"][i][j] = colours.toBlit(colours.white)
			screen["bg"][i][j] = colours.toBlit(colours.black)
		end
	end

	return screen
end

local primary_screen = createBlankScreen()
local secondary_screen = createBlankScreen()

local current_screen = primary_screen
local current_screen_name = "primary"

local current_fg = colours.toBlit(colours.white)
local current_bg = colours.toBlit(colours.black)

local cursor_x = 1
local cursor_y = 1

local function setCursorPos(x, y)
	cursor_x = x or cursor_x
	cursor_y = y or cursor_y
end

local function getCursorPos()
	return cursor_x, cursor_y
end

local function setTextColor(fg)
	current_fg = colours.toBlit(fg)
end

local function setBackgroundColor(bg)
	current_bg = colours.toBlit(bg)
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
			current_row[x + i - 1] = char
			current_fg_row[x + i - 1] = current_fg
			current_bg_row[x + i - 1] = current_bg
		end
	end

	setCursorPos(x + #str, y)
end

local function clear()
	primary_screen = createBlankScreen()
	secondary_screen = createBlankScreen()
	current_screen = primary_screen
end

local function update()
	for i = 1, #current_screen["chars"] do
		term.setCursorPos(1, i)
		term.blit(
			table.concat(current_screen["chars"][i]),
			table.concat(current_screen["fg"][i]),
			table.concat(current_screen["bg"][i])
		)
	end

	if current_screen_name == "primary" then
		current_screen_name = "secondary"
		current_screen = secondary_screen
	elseif current_screen_name == "secondary" then
		current_screen_name = "primary"
		current_screen = primary_screen
	end
end

return {
	setCursorPos = setCursorPos,
	getCursorPos = getCursorPos,
	setTextColor = setTextColor,
	setBackgroundColor = setBackgroundColor,
	setBackgroundColour = setBackgroundColor,
	setTextColour = setTextColor,
	write = write,
	clear = clear,
	update = update,
}