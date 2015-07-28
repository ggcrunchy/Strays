--- Some controls from a shader demo's utilities.

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
local function TouchCircle (func, x, y)
	local xoff, yoff

	return function(event)
		local phase, circle = event.phase, event.target

		if phase == "began" then
			display:getCurrentStage():setFocus(circle)

			xoff, yoff = event.x - circle.x, event.y - circle.y
		elseif phase == "moved" and xoff then
			local resx, resy = func(event.x - xoff, event.y - yoff)

			circle.x, circle.y = resx or x, resy or y
		elseif phase == "ended" or phase == "cancelled" then
			display.getCurrentStage():setFocus(nil)

			xoff, yoff = nil
		end

		return true
	end
end

--
local function AuxLineControl (group, r, g, b, func, x, y)
	local circle = display.newCircle(group, 0, 0, 5)

	circle:setFillColor(r, g, b)
	circle:setStrokeColor(r * .8, g * .8, b * .8)

	circle.strokeWidth = 3

	circle:addEventListener("touch", TouchCircle(func, x, y))

	local newx, newy = func(x, y)

	circle.x, circle.y = newx or x, newy or y
end

--
local function Guide (group, tbounds, r, g, b, id)
	local guide = display.newCircle(group, 0, 0, 10)

	guide:setFillColor(0, 0)
	guide:setStrokeColor(r, g, b, .4)

	guide.strokeWidth = 3

	guide.m_x, guide.m_y, guide.m_id = tbounds.xMin, tbounds.yMin, id

	return guide
end

--
local function UpdateProps (target, guide, prop, x, y, line)
	effect_props.SetEffectProperty(target, prop, unit_pair.Encode(x, y))

	guide.x = guide.m_x + x * target.contentWidth
	guide.y = guide.m_y + y * target.contentHeight

	display.remove(line)

	if guide.m_id == 1 then
		target.m_x1, target.m_y1 = guide.x, guide.y
	elseif guide.m_id == 2 then
		target.m_x2, target.m_y2 = guide.x, guide.y
	end

	if target.m_x1 and target.m_x2 then -- wait until both are set
		line = display.newLine(target.parent, target.m_x1, target.m_y1, target.m_x2, target.m_y2)

		line:setStrokeColor(0, 1, 0, .7)

		line.strokeWidth = 3

		return line
	end
end

--
local function AuxControls (target, prop1, prop2, id1, id2)
	local tbounds, group, line = target.contentBounds, target.parent
	local minx, miny, maxx, maxy = tbounds.xMin, tbounds.yMin, tbounds.xMax, tbounds.yMax
	local dx, dy = maxx - minx, maxy - miny

	--
	local guide1 = Guide(group, tbounds, 1, 0, 0, id1)
	local x1, y1 = unit_pair.Decode(effect_props.GetEffectProperty(target, prop1))

	AuxLineControl(group, 1, 0, 0, function(x)
		x, x1 = FitVar(x, minx, maxx)

		line = UpdateProps(target, guide1, prop1, x1, y1, line)

		return x
	end, minx + x1 * dx, miny - 15)
	AuxLineControl(group, 1, 0, 0, function(_, y)
		y, y1 = FitVar(y, miny, maxy)

		line = UpdateProps(target, guide1, prop1, x1, y1, line)

		return false, y
	end, minx - 15, miny + y1 * dy)

	--
	if prop2 then
		local guide2 = Guide(group, tbounds, 0, 0, 1, id2)
		local x2, y2 = unit_pair.Decode(effect_props.GetEffectProperty(target, prop2))

		AuxLineControl(group, 0, 0, 1, function(_, y)
			y, y2 = FitVar(y, miny, maxy)

			line = UpdateProps(target, guide2, prop2, x2, y2, line)

			return false, y
		end, maxx + 15, miny + y2 * dy)
		AuxLineControl(group, 0, 0, 1, function(x)
			x, x2 = FitVar(x, minx, maxx)

			line = UpdateProps(target, guide2, prop2, x2, y2, line)

			return x
		end, minx + x2 * dx, maxy + 15)
	end
end