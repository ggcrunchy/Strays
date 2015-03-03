--- Some tests for grid iterators.

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

local fo = require("coroutine_ops.flow")
local gi = require("iterator_ops.grid")
local tt = require("corona_utils.timers")

local Dim, FadeMS = 10, 75
local FadeSeconds = FadeMS / 1000
local CX, CY = display.contentCenterX - Dim, display.contentCenterY - Dim

local op = gi.Ellipse -- Quadrant

local function Color ()
	return .3 + math.random() * .675
end

tt.WrapEx(function()
	local fade, fade_away, group = { alpha = 1, time = FadeMS }, { alpha = .1, delay = 600, onComplete = display.remove }

	while true do
		group = display.newGroup()

		local w, h = math.random(4, 21), math.random(4, 21)
		local text = display.newText(group, ("%i, %i"):format(w, h), 50, 50, native.systemFontBold, 25)

		for x, y in op(w, h) do
			local rect = display.newRect(group, CX + x * Dim, CY + y * Dim, Dim, Dim)

			rect:setFillColor(Color(), Color(), Color())

			rect.alpha = .3

			transition.to(rect, fade)

			fo.Wait(FadeSeconds)
		end

		transition.to(group, fade_away)
	end
end)