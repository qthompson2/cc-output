local current_directory = debug.getinfo(1).source:sub(2) -- get source, removes the leading '@'
OutputFunctionsLoader = loadfile(fs.getDir(current_directory) .. "/output.lua")

if not OutputFunctionsLoader then
	error("Failed to load data from " .. fs.getDir(current_directory) .. "/output.lua")
end

OutputFunctions = OutputFunctionsLoader()

Native = {}
Native._cursor_x, Native._cursor_y = 1, 1
Native._redirected = false
Native._current_peripheral = term.native()
Native._current_peripheral.setCursorPos(1, 1)
Native["_modified"] = false
Native_current_fg = colours.toBlit(term.getTextColor())
Native_current_bg = colours.toBlit(term.getBackgroundColor())
Native["_chars"], Native["_fg"], Native["_bg"] = OutputFunctions.createGrid(term.getSize())

OutputFunctions.applyIsSupported(Native)
OutputFunctions.applyIsColour(Native)
OutputFunctions.applyGetSize(Native)
OutputFunctions.applyGetCursorPos(Native)
OutputFunctions.applyGetCursorBlink(Native)
OutputFunctions.applyGetTextColour(Native)
OutputFunctions.applyGetBackgroundColour(Native)
OutputFunctions.applyGetTextScale(Native)
OutputFunctions.applyGetPaletteColour(Native)
OutputFunctions.applySetTextColour(Native)
OutputFunctions.applySetBackgroundColour(Native)
OutputFunctions.applySetCursorPos(Native)
OutputFunctions.applySetCursorBlink(Native)
OutputFunctions.applySetTextScale(Native)
OutputFunctions.applySetPaletteColour(Native)
OutputFunctions.applyUpdate(Native)
OutputFunctions.applyWrite(Native)
OutputFunctions.applyBlit(Native)
OutputFunctions.applyScroll(Native)
OutputFunctions.applyClearLine(Native)
OutputFunctions.applyClear(Native)
OutputFunctions.applyRedirect(Native)
OutputFunctions.applyCurrent(Native)
OutputFunctions.applyConfig(Native)

return Native