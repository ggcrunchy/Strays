--- Some tests for grid operations.

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

local grid_funcs = require("tektite_core.array.grid")

local function Comp (what, index, w, h, layout, col, row)
	local c, r = grid_funcs.IndexToCell_Layout(index, w, h, layout)

	print(what, c, r, c == col, r == row)
end

for _ = 1, 5 do
	local w, h = math.random(4, 15), math.random(4, 15)

	print("W, H", w, h)

	for _ = 1, 4 do
		local col, row = math.random(w), math.random(h)

		print("COL, ROW", col, row)

		local index1 = grid_funcs.CellToIndex_Layout(col, row, w, h, "boundary")
		local index2 = grid_funcs.CellToIndex_Layout(col, row, w, h, "boundary_horz")
		local index3 = grid_funcs.CellToIndex_Layout(col, row, w, h, "boundary_vert")
		local index4 = grid_funcs.CellToIndex_Layout(col, row, w, h, "normal")

		print("INDICES", index1, index2, index3, index4)

		Comp("boundary, index -> cell", index1, w, h, "boundary", col, row)
		Comp("boundary (horz), index -> cell", index2, w, h, "boundary_horz", col, row)
		Comp("boundary (vert), index -> cell", index3, w, h, "boundary_vert", col, row)
		Comp("normal, index -> cell", index4, w, h, "normal", col, row)
	end

	print("")
end