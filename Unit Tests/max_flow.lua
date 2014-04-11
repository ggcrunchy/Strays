--- Testing max flow.

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

local mf=require("graph_ops.flow")
-- A = { b = 3, d = 3 } -> 1 = 2, 4
-- B = { c = 4 } -> 2 = 3
-- C = { a = 3, d = 1, e = 2 } -> 3 = 1, 4, 5
-- D = { e = 2, f = 6 } -> 4 = 5, 6
-- E = { b = 1, g = 1 } -> 5 = 2, 7
-- F = { g = 9 } -> 6 = 7
-- G = "SINK"
-- Source = a, sink = g
do
	local a, b = mf.MaxFlow ({
		1, 2, 3, 1, 4, 3,
		2, 3, 4,
		3, 1, 3, 3, 4, 1, 3, 5, 2,
		4, 5, 2, 4, 6, 6,
		5, 2, 1, 5, 7, 1,
		6, 7, 9
	}, 1, 7)
	print("Max flow = " .. tostring(a))
	vdump(b)
end

do
	local a, b = mf.MaxFlow_Labels ({
		a = { b = 3, d = 3 },
		b = { c = 4 },
		c = { a = 3, d = 1, e = 2 },
		d = { e = 2, f = 6 },
		e = { b = 1, g = 1 },
		f = { g = 9 }
	}, "a", "g")
	print("Max flow = " .. tostring(a))
	vdump(b)
end

-- Algorithms in C++ example
do
	local n, rn, cut = mf.MaxFlow_Labels({
		["0"] = { ["1"] = 2, ["2"] = 3 },
		["1"] = { ["3"] = 3, ["4"] = 1 },
		["2"] = { ["3"] = 1, ["4"] = 1 },
		["3"] = { ["5"] = 2 },
		["4"] = { ["5"] = 3 }
	}, "0", "5", { compute_mincut = true })
	print("Flow: ", n)
	print("Residual network and mincut")
	vdump(rn)
	vdump(cut)
end

-- Online example
do
	local n, rn, cut = mf.MaxFlow_Labels({
		u = { v = 3 },
		s = { u = 4, w = 2 },
		v = { t = 2, x = 1 },
		t = { x = 4 },
		w = { x = 1 },
		x = { u = 1, s = 3 },
	}, "s", "t", { compute_mincut = true })

	print("Flow: ", n)
	print("Residual network and mincut")
	vdump(rn)
	vdump(cut)
end