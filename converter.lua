-- Tests
--line = io.read()
--line = "# I'm a heading!"
--line = "I'm a _test_ string. I _test_ the output!"
--line = "I'm a **bolded** string. I test **bolded** input! **Bolded** input every day!"
--line = "I'm a **hardass**. I do _both_!"
--line = "I'm a _hardass_. I do **both**!"

-- convertLine: Returns valid HTML from markdown input
function convertLine(line)
	-- Mode states
	local headingMode = false
	local emphasisMode = false
	local boldMode = false
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
		if i == 1 and char ~= "#" and char ~= "-" then
			convertedLine = convertedLine .. "<p>"
			closeParagraph = true
		-- Checking for headings
		elseif char == "#" and i == 1 then
			headingMode = true
			convertedLine = convertedLine .. "<h1>"
			convertedLine = convertedLine .. string.sub(line, i+2)
			convertedLine = convertedLine .. "</h1>"
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
		-- Checking for horizontal line
		elseif char == "-" and nextChar == "-" and thirdChar == "-" then
			return "<hr/>"
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
			convertedLine = convertedLine .. "<img src='" .. imageLink .. "'>" .. imageName .. "</img>"
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

	return convertedLine
end

firstLine = true
for line in io.lines("test.md") do
	line = convertLine(line)
	print(line)
end

--print(convertLine("This is an **_odd_** test..."))
--print(convertLine("---"))
--print(convertLine("Try _this_ and see if **you** survive"))
--print(convertLine("And _here's_ a [link](http://example.com) for **you**, and another one [here](http://google.com)"))
--print(convertLine("Here's a regular ![image](http://google.com/logo.png)"))
--print(convertLine("Finally, here's an ![image](http://google.com/logo.png) with a [link](http://example.com)"))
--print(convertLine("And here's a switcheroo: [link](http://example.com) ![image](http://google.com/logo.png)"))

