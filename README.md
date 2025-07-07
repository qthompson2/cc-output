# cc-output
 A wrapper for CC: Tweaked's term module that implements paging.

# Functions
## Cursor Position

	getCursorPos()

Returns the current position of the cursor.

	setCursorPos(x, y)

Sets the position of the cursor to the provided x and y values.

## Colour

	isColour() or isColor()

Returns a boolean representing whether the current display peripheral supports colour.

	getTextColour() or getTextColor()

Returns the current text colour.

	setTextColour(colour) or setTextColor(color)

Sets the current text colour to the provided value.

	getBackgroundColour() or getBackgroundColor(color)

Returns the current background colour.

	setBackgroundColour(colour) or setBackgroundColor(color)

Sets the current background colour to the provided value.

	getPaletteColour(index) or getPaletteColor(index)

Returns the current palette for a specific colour.

	setPaletteColour(...) or setPaletteColor(...)
	
Sets the palette for a specific colour.
## Display Size

	getSize()

Returns the size of the current display.

## Text Scale

	getTextScale()

Returns the text scale of the current display. Raises an error if called before redirection or if the current display does not support multiple text scales.

	setTextScale(scale)

Sets the text scale of the current display. Raises an error if called before redirection or if the current display does not support multiple text scales.

## Outputting Text

	write(text)

Writes text to the current display.

	blit(text, fg, bg)

Writes text to the current display with specific foreground and background colours. Raises an error if text, fg, and bg are of different lengths.

	clear()

Clears the current display.

	clearLine()

Clears the line the cursor has selected.

	scroll(n)

Scrolls `n` lines down (if `n` is positive) or up (if `n` is negative).

	update()

Outputs all changes to the current monitor.

## Redirection

	redirect(monitor)

Changes the current monitor. `monitor` can be either a string or a peripheral table. If `monitor` == "native" the current monitor will be redirected back to the original computer.

## Misc
	
	isSupported(function_name)

Returns a boolean representing whether the current display peripheral has a function with a name that matches `function_name`.