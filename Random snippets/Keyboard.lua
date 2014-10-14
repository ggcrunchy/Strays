--- Deprecated keyboard features.

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
local function SetRef (keys, target)
	if keys.m_refx and target then
		target.anchorX, target.x = 0, keys.m_refx
	end
end

-- --
local SelectW, SelectH = 75, 45

--
local function UpdateSelection (target, select)
	local bounds = target.contentBounds
	local x, w = (bounds.xMin + bounds.xMax) / 2, bounds.xMax - bounds.xMin
	local y, h = (bounds.yMin + bounds.yMax) / 2, bounds.yMax - bounds.yMin

	select.x, select.y = target.parent:contentToLocal(x, y)

	select.xScale = w / SelectW + 1
	select.yScale = h / SelectH + 1

	target.parent:insert(select)
end

--[[
	local target = kgroup.m_target

	...

	elseif target then
		ProduceKeyEvent(btext)

		local ttext = target.text

		if btext == "<-" then
			target.text = ttext:sub(1, -2)
		elseif btext ~= "OK" then
			target.text = ttext .. btext
		elseif not kgroup.m_close_if or kgroup:m_close_if() then
			kgroup:SetTarget(nil)
		end

		if ttext ~= target.text then
			SetRef(kgroup, target)
			UpdateSelection(target, kgroup.m_selection)

			if kgroup.m_on_edit then
				kgroup:m_on_edit(target)
			end
		end
]]

--- DOCME
-- @treturn DisplayObject X
function Keyboard:GetTarget ()
	return self.m_target
end

--- DOCME
-- @callable close_if
function Keyboard:SetClosePredicate (close_if)
	self.m_close_if = close_if
end

--- DOCME
-- @callable on_edit
function Keyboard:SetEditFunc (on_edit)
	self.m_on_edit = on_edit
end

--
local function CheckTarget ()
	local target = Keyboard.m_target

	if not (Keyboard.parent and target and target.isVisible) then
		Runtime:removeEventListener("enterFrame", CheckTarget)

		if Keyboard.parent then
			Keyboard:SetTarget(nil)
		end
	end
end

--- DOCME
-- @pobject target
-- @bool left_aligned
function Keyboard:SetTarget (target, left_aligned)
	self.m_refx = left_aligned and target and target.x
	self.m_target = target

	SetRef(self, target)

	local select = self.m_selection

	if target then
		if not select then
			select = display.newRoundedRect(0, 0, SelectW, SelectH, 12)

			self.m_selection = select
		end

		select:setFillColor(0, 0)
		select:setStrokeColor(0, 1, 0, .75)

		select.strokeWidth = 2

		UpdateSelection(target, select)

		Runtime:addEventListener("enterFrame", CheckTarget)

	elseif select then
		display.remove(select)

		self.m_selection = nil
	end

	self.isVisible = target ~= nil
end

--
Keyboard:SetTarget(nil)