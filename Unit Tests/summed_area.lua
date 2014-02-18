--- Summed area tables tests.

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

--[[
-- FROM New_Grid in number_ops.summed_area

print("BEFORE")
DDD(sat)

	-- Put the table into sum form.
	Sum(sat, pitch + 2, 1, 1, ncols)

print("AREA")
DDD(sat)
UUU(sat, pitch + 2, 1, 1, ncols)
print("UNRAVELED")
DDD(sat)
print("")
--]]

-- Snip...

---[[
local function Num (n)
	return string.format("%i", n)
end

local function GetXY (n)
	if n == 0 then
		return 0, 0
	else
		return n.x, n.y
	end
end

local function Pair (n)
	return string.format("(%i, %i)", GetXY(n))
end

local function DumpGrid (g)
	local ii=1
	for r = 1, g.m_h + 1 do
		local t={}
		for c = 1, g.m_w + 1 do
			t[#t+1] = Elem(g[ii])
			ii=ii+1
		end
		print(table.concat(t, " "))
	end
	print("")
	print("W, H, N, AREA", g.m_w, g.m_h, #g, M.Sum(g))
	print("")
end


DDD,UUU=DumpGrid,Unravel
local aa=M.New(3, 4)
local bb=M.New(4, 5)
local cc=M.New_Grid({}, 2, 4)
local dd=M.New_Grid({2,3,4,1},2,2)
local ee=M.New_Grid({2,3,4},2,2)

print("Values")
print("V11", M.Value(dd, 1, 1))
print("V12", M.Value(dd, 1, 2))
print("")

Elem = Num

DumpGrid(aa)
DumpGrid(bb)
DumpGrid(cc)
DumpGrid(dd)
DumpGrid(ee)

print("Playing with setting values")
print("")

local ff=M.New_Grid({1,2,3,
					4,5,6,
					7,8,9,
					10,11,12}, 3)
local gg=M.New_Grid({1,2,3,
					0,5,6,
					7,8,9,
					10,11,12}, 3)
local hh=M.New_Grid({0,2,3,
					4,0,6,
					7,8,9,
					10,0,12}, 3)

DumpGrid(ff)

M.Set(gg, 1, 2, 4)

DumpGrid(gg) -- Looks like ff?

M.Set_Multi(hh, {
	1, 1, 1,
	2, 2, 5,
	1, 1, 1, -- Repeat ignored?
	2, 4, 11,
	1010, 2, 34343, -- Out-of-bounds ignored
	5, 1, 13 -- More sensible OOB
})

DumpGrid(hh) -- Looks like ff?

print("Non-numbers")
print("")

local PairMT = {}

function PairMT.__add (a, b)
	if a == 0 or b == 0 then
		return a == 0 and b or a
	else
		return setmetatable({ x = a.x + b.x, y = a.y + b.y }, PairMT)
	end
end

function PairMT.__sub (a, b)
	if b == 0 then
		return a
	else
		local ax, ay = GetXY(a)

		return setmetatable({ x = ax - b.x, y = ay - b.y }, PairMT)
	end
end

local function NewPair (x, y)
	return setmetatable({ x = x, y = y }, PairMT)
end

Elem = Pair

local ff = M.New_Grid({NewPair(2, 7),NewPair(3, 14),NewPair(4,1),NewPair(1,0)},2,2)

DumpGrid(ff)

--]]