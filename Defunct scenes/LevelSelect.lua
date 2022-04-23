--- Level select scene.

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

-- Standard library imports --
local abs = math.abs
local floor = math.floor
--local ipairs = ipairs
local min = math.min

-- Modules --
--local button = require("solar2d_ui.widgets.button")
--local checkbox = require("solar2d_ui.widgets.checkbox")
--local layout = require("solar2d_ui.utils.layout")
local levels_list = require("game.LevelsList")
--local persistence = require("solar2d_utils.persistence")
local transitions = require("solar2d_utils.transitions")

-- Solar2D globals --
local display = display
local native = native
local Runtime = Runtime
local system = system
local transition = transition

-- Solar2D modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

--
--
--

local FlipParams = {}

local function PageX (index)
	return (index - 1) * display.contentWidth
end

-- --
local FirstOnPage

-- --
local NCols, NRows = 3, 3

-- --
local NumPerPage = NCols * NRows

--
local function GoToPage (group, index, on_done)
	local x = PageX(index)

	;(on_done and FlipParams or group).x = -x

	if on_done then
		if on_done ~= "wait" then
			FlipParams.onComplete = on_done
		end

		--
		if abs(x + group.x) > 1e-3 then
			if on_done == "wait" then
				transitions.DoAndWait(group, FlipParams)
			else
				transition.to(group, FlipParams)
			end
		elseif on_done ~= "wait" then
			FlipParams.onComplete()
		end

		FlipParams.onComplete = nil
	end

	FirstOnPage = (index - 1) * NumPerPage + 1
end

-- --
local ExtraX, ExtraY = 0, .5

-- --
local FracW = math.floor(display.contentWidth / (NCols + ExtraX))
local FracH = math.floor(display.contentHeight / (NRows + ExtraY))

-- --
local BoxW, BoxH = math.floor(.6 * FracW), math.floor(.6 * FracH)

local function DivRem (a, b)
  local quot = floor(a / b)

	return quot, a - quot * b
end

--
local function GetPage (index)
	local page, slot = DivRem(index - 1, NumPerPage)

	return page + 1, slot
end

--
local function GetXY (index)
	local page, slot = GetPage(index)
	local ybin, xbin = DivRem(slot, NCols)
	local x = display.contentCenterX + (ExtraX + xbin - 1) * FracW + PageX(page)
	local y = display.contentCenterY + (ExtraY + ybin - 1) * FracH
-- todo: probably needs adjustment for even vs. odd NCols / NRows; also verify NCols is correct divisor
	return x, y
end

-- --
local Args = { effect = "fade" }

--
local function GoToScene (event)
	if event.phase == "ended" then
		Args.params = event.target.m_data

		composer.gotoScene("game.scene.Level", Args)

		Args.params = nil
	end

	return true
end

-- --
local LScroll, RScroll

--
local function ShowScrollButtons (group)
	local enough = group.numChildren > NumPerPage

	LScroll.isVisible, RScroll.isVisible = enough, enough
end

-- --
local NameIndex = 0

--
local function AddButton (group, index, data, text)
	-- Bundle the button parts into a group so that we can count elements per page reliably.
	local bgroup = display.newGroup()

	group:insert(bgroup)

	--
	local rect = display.newRoundedRect(bgroup, 0, 0, BoxW, BoxH, 12)--layout.ResolveX("3.125%"))

	rect:addEventListener("touch", GoToScene)
	rect:setFillColor(.5)
	rect:setStrokeColor(.25, .5)

	rect.strokeWidth = 4
	rect.x, rect.y = GetXY(index)

	rect.m_data = data or index

	-- Database levels will have a name. Otherwise, either auto-generate a generic name from
	-- a running index or use one in the level info, if available.
	if not text then
		local name = levels_list.GetLevel(index).name

		if name then
			text = name
		else
			NameIndex = NameIndex + 1

			text = "Level " .. NameIndex
		end
	end

	--
	local str = display.newText(bgroup, text, 0, 0, native.systemFontBold, 25)--layout.ResolveY("6.67%"))

	str.x, str.y = rect.x, rect.y

	-- When a button suddenly becomes visible after unlocking a level, we may be adding a
	-- button to the second page for the first time, and the ability to scroll then becomes
	-- necessary. However, we only do this if we are also in the appropriate mode.
	if group.isVisible then
		ShowScrollButtons(group)
	end

	return bgroup
end

--
local function GetView (scene)
	local view = scene.levels

	return view--view.isVisible and view or scene.db
end

function Scene:create ()
--	button.Button_XY(self.view, "15%", "8.6%", "25%", "10.4%", composer.getVariable("WantsToGoBack"), "Go Back")

	--
	local function OnPageFlip ()
		self.block.isHitTestable = false
	end

	--
	local function Flip (view, index)
		self.block.isHitTestable = true

		GoToPage(view, GetPage(index), OnPageFlip)
	end

	-- TODO: Deuglify these :P
	-- 35 / 800 = 4.375
	-- 15 / 800 = 1.875, 15 / 480 = 3.125
	LScroll = display.newCircle(self.view, 35, display.contentCenterY, 15)
	RScroll = display.newCircle(self.view, display.contentWidth - 35, display.contentCenterY, 15)

	LScroll:addEventListener("touch", function(event)
		if event.phase == "ended" and FirstOnPage > 1 then
			Flip(GetView(self), FirstOnPage - 1)
		end

		return true
	end)

	RScroll:addEventListener("touch", function(event)
		local view = GetView(self)

		if event.phase == "ended" and FirstOnPage + NumPerPage <= view.numChildren then
			Flip(view, FirstOnPage + NumPerPage)
		end

		return true
	end)

	-- Install buttons for already-unlocked levels.
	self.levels = display.newGroup()

	self.view:insert(self.levels)	

	for i = 1, min((system.getPreference("app", "completed", "number") or 0) + 1, levels_list.GetCount()) do
		-- TODO: look for any special text (e.g. "boss", "tutorial", etc.)

		AddButton(self.levels, i, false)
	end

	--
	self.db = display.newGroup()

	self.view:insert(self.db)

	--[[
	self.switch_mode = checkbox.Checkbox_XY(self.view, "right_of 1.25%", "from_bottom -6.25%", "3.75%", "6.25%", function(_, check)
		self.levels.isVisible, self.db.isVisible = not check, check

		local view = GetView(self)

		ShowScrollButtons(view)
		GoToPage(view, 1)
	end)
]]
	-- Create an invisible net to trap input during page scrolls and during the cutscene
	-- overlay (also, this obviates the need to make the overlay modal).
	self.block = display.newRect(self.view, 0, 0, display.contentWidth, display.contentHeight)

	self.block:addEventListener("touch", function() return true end)

	self.block.isVisible = false
	-- ^^^ TODO: Use net.Blocker()?
end

Scene:addEventListener("create")

--
--
--

function Scene:destroy ()
	LScroll, RScroll = nil
end

Scene:addEventListener("destroy")

--
--
--

--
local function HideOverlay ()
	Scene.block.isHitTestable = false
end

local function WantsToGoBack ()
	composer.gotoScene("game.scene.Title", "fade")
end

function Scene:show (event)
	local came_from = composer.getSceneName("previous") or ""

	if event.phase == "did" then
--[[
		-- Add available database levels. If there were any, allow for switching over to them.
		local levels = persistence.GetLevels()

		for i, level in ipairs(levels) do
			AddButton(self.db, i, level.data, level.name)
		end

		self.switch_mode.isVisible = #levels > 0

		self.switch_mode:Check(false)
]]
		--
		local params

	-- cutscene to watch? (could still be pending if not completely watched, say)
		if came_from:ends(".Level") then
			Runtime:dispatchEvent{ name = "unloaded" }

			params = { get_xy = GetXY, index = (system.getPreference("app", "completed", "number") or 0) + 1 }

			GoToPage(self.levels, GetPage(params.index), nil)

			params.more = params.index < levels_list.GetCount()

			function params.add_button (index, x, y, time)
--				fx.Sparkle(self.view, x, y, time)

				return AddButton(self.levels, index + 1, false)
			end

			function params.get_xy (index)
				index = index + 1

				local page, x, y = GetPage(index), GetXY(index)

				return x - PageX(page), y
			end

			function params.go_to_page (index)
				GoToPage(self.levels, GetPage(index + 1), "wait")
			end
		end

		-- Launch the cutscene overlay, if any params were specified.
		if params then
			composer.showOverlay("game.overlay.Cutscene", { params = params })
		end
	else
		self.levels.isVisible = true
--[[
		self.db.isVisible = false
		self.switch_mode.isVisible = false
]]
		if not came_from:ends(".Level") then
			GoToPage(self.levels, 1)
		else
			self.block.isHitTestable = true
		end

		ShowScrollButtons(self.levels)
	end

	-- The listen function explicitly returns us to the title screen when going back (since we
	-- may be coming from the level); in addition, it detects the cutscene overlay closing.
	composer.getVariable("hide_overlay"):Push(HideOverlay)
	composer.getVariable("wants_to_go_back"):Push(WantsToGoBack)
end

Scene:addEventListener("show")

--
--
--

function Scene:hide (event)
	if event.phase == "did" then
--[[
		-- The database might change between now and our next visit to this scene, so just wipe
		-- the list out and replenish it when we return.
		for i = self.db.numChildren, 1, -1 do
			self.db:remove(i)
		end
]]
	else
		composer.getVariable("hide_overlay"):Pop()
		composer.getVariable("wants_to_go_back"):Pop()
	end
end

Scene:addEventListener("hide")

--
--
--

return Scene