--- Minimum spanning tree tests.

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

local mst = M.MST{
	1, 2, 7, -- (A, B), 7
	1, 4, 5, -- (A, D), 5
	2, 3, 8, -- (B, C), 8
	2, 4, 9, -- (B, D), 9
	2, 5, 7, -- (B, E), 7
	3, 5, 5, -- (C, E), 5
	4, 5, 15,-- (D, E), 15
	4, 6, 6, -- (D, F), 6
	5, 6, 8, -- (E, F), 8
	5, 7, 9, -- (E, G), 9
	6, 7, 11 -- (F, G), 11
}

for i = 1, #mst, 2 do
	print(mst[i], mst[i + 1])
end

local mst2 = M.MST_Labels{
	a = { b = 7, d = 5 },
	b = { c = 8, d = 9, e = 7 },
	c = { e = 5 },
	d = { e = 15, f = 6 },
	e = { f = 8, g = 9 },
	f = { g = 11 }
}

vdump(mst2)