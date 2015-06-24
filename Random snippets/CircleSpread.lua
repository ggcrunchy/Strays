--- Some old circle spread logic.

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

-- MAZE:

-- Standard library imports --
local ceil = math.ceil
local floor = math.floor
local sqrt = math.sqrt

-- Modules --
local circle = require("s3_utils.fill.circle")

-- Fade-in transition --
local FadeInParams = { alpha = 1, time = 1100, transition = easing.inQuad }

-- Fade the maze tiles in, as an expanding circle.
local col1, row1, col2, row2 = block:GetInitialRect()
local nx = col2 - col1 + 1
local ny = row2 - row1 + 1
local halfx = ceil(nx / 2)
local halfy = ceil(ny / 2)
local midx, midy, n = col1 + halfx - 1, row1 + halfy - 1, nx * ny

-- SNIP

local spread = circle.SpreadOut(nx - halfx, ny - halfx, function(x, y)
	x, y = x + midx, y + midy

	if x >= col1 and x <= col2 and y >= row1 and y <= row2 then
		local image = tile_maps.GetImage(tile_maps.GetTileIndex(x, y))

		if image then
			image.alpha = .05
			image.isVisible = true

			transition.to(image, FadeInParams)
		end

		n = n - 1
	end
end)

-- Spread out until all tiles in the block have been cued.
local radius, t0 = sqrt(nx^2 + ny^2) / 2000

timers.RepeatEx(function(event)
	t0 = t0 or event.time

	if n ~= 0 then
		spread(floor((event.time - t0) * radius))
	else
		return "cancel"
	end
end)