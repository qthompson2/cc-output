local cols, rows = term.getSize()

local screen = window.create(term.current(), 1, 1, cols, rows, false)

local output = {}

for func_name, func in pairs(screen) do
	if type(func) == "function" then
		output[func_name] = function(...)
			local result = {func(...)}
			return table.unpack(result)
		end
	end
end

function output.isSupported(func_name)
	return screen[func_name] ~= nil
end

function output.update()
	screen.setVisible(true)
	screen.setVisible(false)
end

return output