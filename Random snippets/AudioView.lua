--- Game audio editing components.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

--
local function SetCurrent (what)
	Current, CurrentText.text = what, "Current music file: " .. (what or "NONE")

	layout.PutBelow(CurrentText, Songs)
	layout.RightAlignWith(CurrentText, Songs)
end

-- --
local Base = system.ResourceDirectory
-- ^^ TODO: Add somewhere to pull down remote files... and, uh, support


-- Helper to load or reload the music list
local function Reload (songs)
	-- If the stream file was removed while playing, try to close the stream before any
	-- problems arise.
	if not songs:Find(StreamName) then
		CloseStream()
	end

	-- Invalidate the current element, if its file was erased. Otherwise, provide it as an
	-- alternative in case the current selection was erased.
	local current = songs:Find(Current)

	if not current then
		SetCurrent(nil)
	end

	return current
end

--
local function SetText (button, text)
	button.parent[2].text = text
end


-- In M.Load:
--
CurrentText = display.newText(Group, "", 0, 0, native.systemFont, 24)

SetCurrent(nil)

--
local bw, bh, y = 120, 50, "from_bottom_align -20"

PlayOrStop = button.Button_XY(Group, 0, y, bw, bh, function(bgroup)
	local was_streaming, selection = Stream, Songs:GetSelection()

	CloseStream()

	if was_streaming then
		SetText(bgroup, "Play")
	elseif selection then
		Stream = audio.loadStream("Music/" .. selection)

		if Stream then
			StreamName = selection

			audio.play(Stream, { fadein = 1500, loops = -1 })

			SetText(bgroup, "Stop")
		end
	end
end)

--
local widgets = { current = CurrentText, list = Songs, play_or_stop = PlayOrStop }

widgets.set = button.Button_XY(Group, 0, y, bw, bh, function()
	SetCurrent(Songs:GetSelection())
end, "Set")

widgets.clear = button.Button_XY(Group, 0, y, bw, bh, function()
	SetCurrent(nil)
end, "Clear")

--
layout.RightAlignWith(widgets.clear, Songs)
layout.PutLeftOf(widgets.set, widgets.clear, "-1%")
layout.PutLeftOf(PlayOrStop, widgets.set, "-1%")

-- ...and...

--
help.AddHelp("Ambience", widgets)
help.AddHelp("Ambience", {
	current = "What is the 'current' selection?",
	list = "A list of available songs.",
	play_or_stop = "If music is playing, stops it. Otherwise, plays the 'current' selection, if available.",
	set = "Make the selected item in the songs list into the 'current' selection.",
	clear = "Clear the 'current' selection."
})


-- In M.Enter:
Songs:Init()

-- Sample music (until switch view or option)
-- Background option, sample (scroll views, event block selector)
-- Picture option, sample
SetText(PlayOrStop[2], "Play")

Group.isVisible = true

help.SetContext("Ambience")