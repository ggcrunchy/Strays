--- UI element layout mechanisms / factories.

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
local select = select

-- Modules --
local args = require("iterator_ops.args")
local buttons = require("ui.Button")

-- Corona globals --
local display = display

-- Imports --
local ArgsByN = args.ArgsByN
local Button = buttons.Button
local contentCenterX = display.contentCenterX
local contentCenterY = display.contentCenterY

-- Exports --
local M = {}

---
-- @pgroup group
-- @param skin
-- @number x
-- @number y
-- @number bw
-- @number bh
-- @number sep
-- @param ...
function M.VBox (group, skin, x, y, bw, bh, sep, ...)
	x = x or contentCenterX

	if not y then
		local n = select("#", ...) / 2

		y = contentCenterY - (bh + sep) * (n - 1) / 2
	end

	--
	local h = 0

	for _, func, text in ArgsByN(2, ...) do
		Button(group, skin, x, y + h, bw, bh, func, text)

		h = h + bh + sep
	end
end


--[[
From ui/layout:

-- Is the object not a group?
local function NonGroup (object)
	return object._type ~= "GroupObject"
end

-- Helper to get an x-coordinate relative to a position, in terms of width...
local function RelativeX (object, t)
	return object.x + t * object.contentWidth
end

-- ...and y-coordinate, in terms of height
local function RelativeY (object, t)
	return object.y + t * object.contentHeight
end

-- Finds the y-coordinate at the bottom of an object; Numbers resolve like deltas, directly to themselves
local function BottomY (object)
	if Number(object) then
		return DY(object)
--	elseif NonGroup(object) then
--		return RelativeY(object, 1 - object.anchorY)
	else
		return object.contentBounds.yMax
	end
end

-- Finds the x-coordinate at the left side of an object; Numbers behave as per BottomY
local function LeftX (object)
	if Number(object) then
		return DX(object)
--	elseif NonGroup(object) then
--		return RelativeX(object, -object.anchorX)
	else
		return object.contentBounds.xMin
	end
end

-- Finds the x-coordinate at the right side of an object; Numbers behave as per BottomY
local function RightX (object)
	if Number(object) then
		return DX(object)
--	elseif NonGroup(object) then
--		return RelativeX(object, 1 - object.anchorX)
	else
		return object.contentBounds.xMax
	end
end

-- Finds the y-coordinate at the top of an object; Numbers behave as per BottomY
local function TopY (object)
	if Number(object) then
		return DY(object)
--	elseif NonGroup(object) then
--		return RelativeY(object, -object.anchorY)
	else
		return object.contentBounds.yMin
	end
end

-- Finds the x-coordinate at the center of an object...
local function CenterX (object)
--	if NonGroup(object) then
--		return RelativeX(object, .5 - object.anchorX)
--	else
		local bounds = object.contentBounds

		return .5 * (bounds.xMin + bounds.xMax)
--	end
end

-- ...and the y-coordinate
local function CenterY (object)
--	if NonGroup(object) then
--		return RelativeY(object, .5 - object.anchorY)
--	else
		local bounds = object.contentBounds

		return .5 * (bounds.yMin + bounds.yMax)
--	end
end

--- Assigns an object's y-coordinate such that its bottom is aligned with the top of a
-- reference object or a y-coordinate.
-- @pobject object Object to position.
-- @tparam ?|DisplayObject|Number ref Reference object or y-coordinate.
-- @tparam[opt] Number dy Displacement from the "above" position.
function M.PutAbove (object, ref, dy)
	local y = TopY(ref)

--	if NonGroup(object) then
	--	y = y - (1 - object.anchorY) * object.contentHeight
--	else
		y = y - (object.contentBounds.yMax - object.y)
--	end

	object.y = floor(y + DY(dy))
end

--- Assigns an object's y-coordinate such that its top is aligned with the bottom of a
-- reference object or a y-coordinate.
-- @pobject object Object to position.
-- @tparam ?|DisplayObject|Number ref Reference object or y-coordinate.
-- @tparam[opt] Number dy Displacement from the "below" position.
function M.PutBelow (object, ref, dy)
	local y = BottomY(ref)

--	if NonGroup(object) then
	--	y = y + object.anchorY * object.contentHeight
--	else
		y = y + (object.y - object.contentBounds.yMin)
--	end

	object.y = floor(y + DY(dy))
end

--- Assigns an object's x-coordinate so that its right side is to the left of a reference
-- object or an x-coordinate.
-- @pobject object Object to position.
-- @tparam ?|DisplayObject|Number ref Reference object or x-coordinate.
-- @tparam[opt] Number dx Displacement from the "left of" position.
function M.PutLeftOf (object, ref, dx)
	local x = LeftX(ref)

--	if NonGroup(object) then
	--	x = x - (1 - object.anchorX) * object.contentWidth
--	else
		x = x - (object.contentBounds.xMax - object.x)
--	end

	object.x = floor(x + DX(dx))
end

--- Assigns an object's x-coordinate so that its left side is to the right of a reference
-- object or an x-coordinate.
-- @pobject object Object to position.
-- @tparam ?|DisplayObject|Number ref Reference object or x-coordinate.
-- @tparam[opt] Number dx Displacement from the "right of" position.
function M.PutRightOf (object, ref, dx)
	local x = RightX(ref)

--	if NonGroup(object) then
	--	x = x + object.anchorX * object.contentWidth
--	else
		x = x + (object.x - object.contentBounds.xMin)
--	end

	object.x = floor(x + DX(dx))
end
]]

--[[
local a = display.newCircle(0, 0, 20)
local maxdx, maxdy = 0, 0
local mindx, mindy = math.huge, math.huge
for i = 1, 4 do
	a.x = math.random(0, display.contentWidth)
	a.y = math.random(0, display.contentHeight)

	for u = 0, 8 do
		a.anchorX = u / 8

		local hb = a.contentBounds
		local w = a.contentWidth

		local xx = a.parent:localToContent(a.x, 0)
		local lx, rx = xx - a.anchorX * w, xx + (1 - a.anchorX) * w
-- hb.xMin = xx - a.anchorX * w -> from_left = hb.xMin + a.anchorX * w
-- hb.xMax = xx + (1 - a.anchorX) * w
		local dl, dr = math.abs(lx - hb.xMin), math.abs(rx - hb.xMax)

		maxdx = math.max(maxdx, dl, dr)
		mindx = math.min(mindx, dl, dr)

		for v = 0, 8 do
			a.anchorY = u / 8

			local vb = a.contentBounds
			local h = a.contentHeight

			local _, yy = a.parent:localToContent(0, a.y)
			local ay, by = yy - a.anchorY * h, yy + (1 - a.anchorY) * h
-- vb.yMin = yy - a.anchorY * h -> vb.yMin + a.anchorY * h
-- vb.yMax = yy + (1 - a.anchorY) * h
			local da, db = math.abs(ay - vb.yMin), math.abs(by - vb.yMax)

			maxdy = math.max(maxdy, da, db)
			mindy = math.min(mindy, da, db)
		end
	end
end

print("X", mindx, maxdx)
print("Y", mindy, maxdy)
]]

-- Export the module.
return M