local codeBlockMode = false -- Since this spans multiple lines, it needs to be on the outside

-- convertLine: Returns valid HTML from markdown input
function convertLine(line)
	-- Mode states
	local headingMode = false
	local emphasisMode = false
	local boldMode = false
	local codeMode = false
	local strikeMode = false
	local imageMode = false

	-- Metadata
	local convertedLine = ""
	local lastTouchedChar = 1
	local lastChange = 0 -- 0: none, 1: emphasis, 2: bolded. This is probably a terrible solution.
	local closeParagraph = false
	local linkName = ""
	local linkLink = ""
	local imageName = ""
	local imageLink = ""
	local imageLinkFirstIndex = 0
	local imageLinkLastIndex = 0
	local imageNameFirstIndex = 0
	local imageNameLastIndex = 0

	-- Loop over every character in a line
	for i = 1, string.len(line) do
		lastChar = string.sub(line, i-1, i-1)
		char = string.sub(line, i, i)
		nextChar = string.sub(line, i+1, i+1)
		thirdChar = string.sub(line, i+2, i+2)

		-- Checking whether or not to insert a <p> tag
		if i == 1 and char ~= "#" and char ~= "-" and (char ~= "`" and nextChar ~= "`" and thirdChar ~= "`") and not codeBlockMode then
			convertedLine = convertedLine .. "<p>"
			closeParagraph = true
		end
		-- Checking for headings
		if char == "#" and i == 1 then
			headingMode = true
			-- Looping to count how many #'s are in the line
			headingCount = 1
			for j = 2, 6 do
				if string.sub(line, j, j) == "#" then
					headingCount = j
				else
					break
				end
			end
			-- Creating the proper heading
			convertedLine = convertedLine .. "<h" .. headingCount .. ">"
			convertedLine = convertedLine .. string.sub(line, i+headingCount+1)
			convertedLine = convertedLine .. "</h" .. headingCount .. ">"
		-- Checking for emphasis
		elseif char == "_" then
			if lastTouchedChar == 1 then
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
			else
				if lastChange == 2 then
					convertedLine = convertedLine .. string.sub(line, lastTouchedChar+2, i-1)
				else
					convertedLine = convertedLine .. string.sub(line, lastTouchedChar+1, i-1)
				end
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
			if i == 1 then
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar+2, i-1)
			elseif lastTouchedChar == 1 then
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
			else
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar+lastChange, i-1)
			end
			if not boldMode then
				convertedLine = convertedLine .. "<strong>"
			else
				convertedLine = convertedLine .. "</strong>"
			end
			lastTouchedChar = i
			lastChange = 2 -- Setting the last change to bold
			boldMode = not boldMode
		-- Check for strikethrough
		elseif char == "~" and nextChar == "~" then
			if lastTouchedChar == 1 then
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
			else
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar+2, i-1)
			end
			if not strikeMode then
				convertedLine = convertedLine .. "<s>"
			else
				convertedLine = convertedLine .. "</s>"
			end
			lastTouchedChar = i
			lastChange = 2 -- Setting the last change to strike
			strikeMode = not strikeMode
		-- Checking for code blocks
		elseif char == "`" and nextChar == "`" and thirdChar == "`" then
			if not codeBlockMode then
				convertedLine = convertedLine .. "<pre>"
			else
				convertedLine = convertedLine .. "</pre>"
			end
			lastChange = 3 -- Setting to last change to codeBlock
			codeBlockMode = true
		-- Checking for inline code blocks
		elseif char == "`" and not codeBlockMode then
			if lastTouchedChar == 1 then
				convertedLine = convertedLine .. string.sub(line, lastTouchedChar, i-1)
			else
				if lastChange == 2 then
					convertedLine = convertedLine .. string.sub(line, lastTouchedChar+2, i-1)
				else
					convertedLine = convertedLine .. string.sub(line, lastTouchedChar+1, i-1)
				end
			end
			if not codeMode then
				convertedLine = convertedLine .. "<code>"
			else
				convertedLine =	convertedLine .. "</code>"
			end
			lastTouchedChar = i
			lastChange = 1 -- Setting the last change to emphasis/code
			codeMode = not codeMode
		-- Checking for horizontal line
		elseif char == "-" and nextChar == "-" and thirdChar == "-" then
			return "<hr/>\n"
		-- Checking for links
		elseif char == "[" and lastChar ~= "!" then
			linkMode = true
			linkNameFirstIndex = i
		elseif char == "]" and linkMode then
			linkNameLastIndex = i
			linkName = string.sub(line, linkNameFirstIndex+1, linkNameLastIndex-1)
		elseif char == "(" and linkMode then
			linkLinkFirstIndex = i
		elseif char == ")" and linkMode then
			linkLinkLastIndex = i
			linkLink = string.sub(line, linkLinkFirstIndex+1, linkLinkLastIndex-1)
		elseif char == "!" and nextChar == "[" then
			imageMode = true
			imageNameFirstIndex = i+1
		elseif char == "]" and imageMode then
			imageNameLastIndex = i
			imageName = string.sub(line, imageNameFirstIndex+1, imageNameLastIndex-1)
		elseif char == "(" and imageMode then
			imageLinkFirstIndex = i
		elseif char == ")" and imageMode then
			imageLinkLastIndex = i
			imageLink = string.sub(line, imageLinkFirstIndex+1, imageLinkLastIndex-1)
		end
		-- Insert the link
		if string.len(linkName) > 0 and string.len(linkLink) > 0 and linkMode then
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar+lastChange, linkNameFirstIndex-1)
			lastTouchedChar = linkLinkLastIndex-1
			convertedLine = convertedLine .. "<a href='" .. linkLink .. "'>" .. linkName .. "</a>"
			--convertedLine = convertedLine .. string.sub(line, linkNameFirstIndex-1, linkLinkLastIndex)
			lastChange = 2
			-- Resetting the values
			linkName = ""
			linkLink = ""
			linkMode = false
		end
		-- Insert the image
		if string.len(imageName) > 0 and string.len(imageLink) > 0 and imageMode then
			convertedLine = convertedLine .. string.sub(line, lastTouchedChar+lastChange, imageNameFirstIndex-2)
			lastTouchedChar = imageLinkLastIndex+1
			convertedLine = convertedLine .. "<img src='" .. imageLink .. "'" .. " alt='" .. imageName .. "'/>\n"
			convertedLine = convertedLine .. "<figcaption>" .. imageName .. "</figcaption>"
			lastChange = 0
			-- Resetting the values
			imageName = ""
			imageLink = ""
			imageMode = false
		end
	end

	-- Append the rest of the line if the line isn't a header
	if not headingMode then
		convertedLine = convertedLine .. string.sub(line, lastTouchedChar+lastChange)
	end
	-- Close a paragraph tag if one is open
	if closeParagraph then
		convertedLine = convertedLine .. "</p>"
	end

	-- Return convertedLine if it's not blank (to strip blank lines in input)
	if convertedLine ~= "" then
		return convertedLine .. "\n"
	end
end

-- If either argument is unset, print an error message
if arg[1] == nil or arg[2] == nil then
	print("Error: Missing arguments.")
	print("Usage: lua path/to/converter.lua input.md output.html")
elseif arg[3] ~= nil then
	print("Error: Too many arguments.")
	print("Usage: lua path/to/converter.lua input.md output.html")
else
	-- Delete the file if it already exists
	os.remove(arg[2])

	-- Open file and stage it for output
	local outputFile = io.open(arg[2], "a")
	io.output(outputFile)

	-- Taking the first arg (the input file) and converting it line by line
	for line in io.lines(arg[1]) do
		-- Appending it to the file
		io.write(convertLine(line))
	end

	-- Print a success message
	print("File '" .. arg[1] .. "' successfully converted to '" .. arg[2] .. "'!")

	-- Unstaging the file after output is complete
	io.close(outputFile)
end

