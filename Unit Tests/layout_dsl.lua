--- Layout DSL tests.

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

local rr = display.newRect(100, 100, 50, 50)
rr:setFillColor(1, 0, 0)
local dsl=require("corona_ui.utils.layout_dsl")

dsl.AddProperties(rr)

local opts = {
	{ "left", 400 },
	{ "center_y", 97 },
	{ "right", 22 },
	{ "bottom", "70%" },
	{ "right", "from_right -87" },
	{ "height", "18%" }
}

local function Details ()
	print("X, Y", rr.x, rr.y)
	print("LEFT, TOP", rr.left, rr.top)
	print("RIGHT, BOTTOM", rr.right, rr.bottom)
	print("CENTER", rr.center_x, rr.center_y)
	print("")
end

timer.performWithDelay(3000, function(e)
	local k, v = unpack(opts[e.count])

	print("APPLYING: ", k, v)

	rr[k] = v

	Details()
end, #opts)

Details()