-- Opening the file and staging it
post = io.open("15JAN20.md", "r")
io.input(post)

-- Mode states
headingMode = false
emphasisMode = false
boldMode = false

-- Metadata
convertedLine = ""
lastTouchedChar = 1
lastChange = 0 -- 0: none, 1: emphasis, 2: bolded. This is probably a terrible solution.

-- Tests
--line = io.read()
--line = "# I'm a heading!"
--line = "I'm a _test_ string. I _test_ the output!"
line = "I'm a **bolded** string. I test **bolded** input! **Bolded** input every day!"

-- Loop over every character in a line
for i = 1, string.len(line) do
	char = string.sub(line, i, i)
	nextChar = string.sub(line, i+1, i+1)
	-- Checking for headings
	if char == "#" then
		headingMode = true
		convertedLine = convertedLine .. "<h1>"
		convertedLine = convertedLine .. string.sub(line, i+2)
		convertedLine = convertedLine .. "</h1>"
	-- Checking for emphasis
	elseif char == "_" then
		if lastTouchedChar == 1 then
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
		else
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar+1, i-1)
		end
		if not emphasisMode then
			convertedLine = convertedLine .. "<em>"
		else
			convertedLine =	convertedLine .. "</em>"
		end
		lastTouchedChar = i
		lastChange = 1 -- Setting the last change to emphasis
		emphasisMode = not emphasisMode
	-- Checking for bolding
	elseif char == "*" and nextChar == "*" then
		if lastTouchedChar == 1 then
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
		else
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar+2, i-1)
		end
		if not boldMode then
			convertedLine = convertedLine .. "<strong>"
		else
			convertedLine = convertedLine .. "</strong>"
		end
		lastTouchedChar = i
		lastChange = 2 -- Setting the last change to bold
		boldMode = not boldMode
	end
end

-- Append the rest of the line if the line isn't a header
if not headingMode then
	convertedLine = convertedLine .. string.sub(line, lastTouchedChar+lastChange)
end

print(convertedLine)

