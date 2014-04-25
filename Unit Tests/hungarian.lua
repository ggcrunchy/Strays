--- An implementation of the [Hungarian algorithm](http://en.wikipedia.org/wiki/Hungarian_algorithm).
--
-- Adapted from [here](http://csclab.murraystate.edu/bob.pilgrim/445/munkres.html).

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
local ceil = math.ceil
local huge = math.huge
local min = math.min
local pairs = pairs

-- Modules --
local labels = require("graph_ops.labels")

-- Exports --
local M = {}

--+++++++++++++++
local oc=os.clock
--+++++++++++++++

-- --
local Costs = {}

-- Finds the smallest element in each row and subtracts it from every row element
local function SubtractSmallestRowCosts (from, n, ncols)
	local dcols = ncols - 1

	for ri = 1, n, ncols do
		local rmin = from[ri]

		for i = 1, dcols do
			rmin = min(rmin, from[ri + i])
		end

		for i = ri, ri + dcols do
			Costs[i] = from[i] - rmin
		end
	end
end

-- --
local Column, Row = {}, {}

-- --
--local CovCol, UncovCol = {}, {}
--local CovRow, UncovRow = {}, {}
--+++++++++++++++++++++++++++++++++++++++++++++++
local pot = require("bitwise_ops.powers_of_2")
local PowersOf2 = pot.PowersOf2

local FreeC, MaskC = {}, {}
local FreeR, MaskR = {}, {}

local function Clear ()
	for i = 1, #MaskC do
		FreeC[i] = MaskC[i]
	end
	for i = 1, #MaskR do
		FreeR[i] = MaskR[i]
	end
end
--+++++++++++++++++++++++++++++++++++++++++++++++
--
--[[
local function ClearCoverage (ncols, nrows)
	CovCol.n, UncovCol.n = 0, ncols
	CovRow.n, UncovRow.n = 0, nrows

	--
	local ri = 1

	for i = 1, nrows do
		UncovCol[i], Column[i] = i - 1, i
		UncovRow[i], Row[i], ri = ri, i, ri + ncols
	end

	--
	for i = nrows + 1, ncols do
		UncovCol[i], Column[i] = i - 1, i
	end
end
]]
-- --
local Covered = 0

-- --
local ColStar, RowStar = {}, {}
--++++++++++
local NSTARS
--++++++++++
-- Stars the first zero found in each uncovered row or column
local function StarSomeZeroes (n, ncols)
--++++++
NSTARS=0
--++++++
--+++++++++++++++++++++++++++++++++++++++++++++++
local nrows = n / ncols
local nc = ceil(ncols / 52)
local nr = ceil(nrows / 52)
for i = 1, nc do
	if i < nc or ncols % 52 == 0 then
		MaskC[i] = 2^52-1
	else
		local tail = ncols % 52
		MaskC[i] = 2^tail-1
	end
end
for i = 1, nr do
	if i < nr or nrows % 52 == 0 then
		MaskR[i] = 2^52-1
	else
		local tail = nrows % 52
		MaskR[i] = 2^tail - 1
	end
end
Clear()
--+++++++++++++++++++++++++++++++++++++++++++++++
	--
	local dcols = ncols - 1

	for ri = 1, n, ncols do
		RowStar[ri] = ncols

		for i = 0, dcols do
			if Costs[ri + i] == 0 and Column[i + 1] ~= Covered then
				ColStar[i + 1], RowStar[ri] = ri, i
				Column[i + 1] = Covered
--+++++++++++++
NSTARS=NSTARS+1
--+++++++++++++
				break
			end
		end
	end

	--
	for i = 1, ncols do
		if Column[i] ~= Covered then
			ColStar[i] = n + 1
		end
	end
end
--[[
--
local function CoverColumn (col, scol)
	local nucols = UncovCol.n
	local at, ctop = CovCol.n + 1, UncovCol[nucols]

	CovCol[at] = UncovCol[col]
	UncovCol[col] = ctop
	Column[scol + 1] = -at
	Column[ctop + 1] = col

	UncovCol.n, CovCol.n = nucols - 1, at
end
]]
local NCOLS
-- Counts how many columns contain a starred zero
local function CountCoverage (n, ncols)
	for ri = 1, n, ncols do
		local col = RowStar[ri]

		if col < ncols then
			--[[
			local cindex = Column[col + 1]

			if cindex > 0 then
				CoverColumn(cindex, col)
			end]]
--++++++++++++++++++++++++++++
local c = col % 52
local i = (col - c) / 52 + 1
local f = 2^c
local v = FreeC[i]
if v % (2 * f) >= f then
	FreeC[i] = v - f
end
if not ZZ then
	ZZ=true
	print(c, i, f, v, FreeC[i])
end
--++++++++++++++++++++++++++++
		end
	end

	local yes=true

	for i = 1, #MaskC do
		yes = yes and FreeC[i]==0
	end

	return yes and NCOLS or 0
--	return CovCol.n
end
--[[
--
local function CoverRow (row, rindex, ncols)
	local nurows = UncovRow.n
	local at, rtop = CovRow.n + 1, UncovRow[nurows]
	local top = (rtop - 1) / ncols + 1

	CovRow[at] = UncovRow[rindex]
	UncovRow[rindex] = rtop
	Row[row] = -at
	Row[top] = rindex

	UncovRow.n, CovRow.n = nurows - 1, at
end
]]
--
local function FindZero ()
	--[[
	local nuc, vmin = UncovCol.n, huge

	for i = 1, UncovRow.n do
		local ri = UncovRow[i]

		for j = 1, nuc do
			local col = UncovCol[j]
			local cost = Costs[ri + col]

			if cost < vmin then
				if cost == 0 then
					return ri, col
				else
					vmin = cost
				end
			end
		end
	end

	return vmin
]]
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
	local nc, vmin = #MaskC, huge
	local rr = 0

	for i = 1, #MaskR do
		for _, _, rbit in PowersOf2(FreeR[i]) do
			local ri = (rr + rbit) * NCOLS + 1
			local cc = 0

			for j = 1, nc do
				for _, _, cbit in PowersOf2(FreeC[j]) do
					local col = cc+cbit
					local cost = Costs[ri + col]

					if cost < vmin then
						if cost == 0 then
							return ri, col
						else
							vmin = cost
						end
					end
				end
				cc=cc+52
			end
		end
		rr=rr+52
	end
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
	return vmin
end
--[[
--
local function UncoverColumn (cindex, scol)
	local nccols = CovCol.n
	local at, ctop = UncovCol.n + 1, CovCol[nccols]
	local col = -cindex

	UncovCol[at] = CovCol[col]
	CovCol[col] = ctop
	Column[scol + 1] = at
	Column[ctop + 1] = cindex

	CovCol.n, UncovCol.n = nccols - 1, at
end
]]
-- --
local Primes = {}

-- --
local Zeroes = {}

-- Prime some uncovered zeroes
local function PrimeZeroes (ncols)
	while true do
		--
		local zn, col, ri = Zeroes.n

		if zn > 0 then
			ri, col, Zeroes.n = Zeroes[zn - 1], Zeroes[zn], zn - 2
		else
			ri, col = FindZero()
		end

		--
		if col then
			Primes[ri] = col

			local scol = RowStar[ri]

			--
			if scol < ncols then
				local row = (ri - 1) / ncols-- + 1
--[[
				local rindex, cindex = Row[row], Column[scol + 1]

				--
				if rindex > 0 then
					CoverRow(row, rindex, ncols)
				end
-- ^^^ THIS, at least, appears to be broken
				--
				if cindex < 0 then
					UncoverColumn(cindex, scol)
				end
-- ^^^ Not sure
]]
--++++++++++++++++++++++++++++
if not WW then
	WW=true
	print("Coords", ri, col)
end
do
	local r = row % 52
	local i = (row - r) / 52 + 1
	local f = 2^r
	local v = FreeR[i]
	local rr
	if v % (2 * f) >= f then
		rr=true
		FreeR[i] = v - f
	end
if not XX then
	XX=true
	print("Cover row", r, i, f, v, rr and "YES" or "NO", FreeR[i])
end
end

do
	local c = col % 52
	local i = (col - c) / 52 + 1
	local f = 2^c
	local v = FreeC[i]
	local aa
	if v % (2 * f) < f then
		aa=true
		FreeC[i] = v + f
	end
if not YY then
	YY=true
	print("Uncover column", c, i, f, v, aa and "YES" or "NO", FreeC[i])
end
end
--++++++++++++++++++++++++++++

			--
			else
				return ri, col
			end

		--
		else
			return false, ri
		end
	end
end

--
local function RemoveStar (n, ri, col, ncols)
	RowStar[ri] = ncols

	if ri == ColStar[col + 1] then
		repeat
			ri = ri + ncols
		until ri > n or RowStar[ri] == col

		ColStar[col + 1] = ri
	end
end

--
local function BuildPath (ri, col, n, ncols, nrows)
	local pp=0
	repeat
		pp=pp+1
if not col then
	print("PP", pp)
	print("RI", ri)
	vdump(ColStar)
	vdump(Primes)
end
		local rnext = ColStar[col + 1]

		-- Star the current primed zero (on the first pass, this is the uncovered input).
		RowStar[ri] = col

		if ri < rnext then
			ColStar[col + 1] = ri
		end

		-- If there is one, go to the starred zero in the column of the last primed zero. Unstar
		-- it, then move to the primed zero in the same row.
		ri = rnext

		if ri <= n then
			RemoveStar(n, ri, col, ncols)

			col = Primes[ri]
		end
	until ri > n

--	ClearCoverage(ncols, nrows)
	Clear()

	for k in pairs(Primes) do
		Primes[k] = nil
	end
end

--++++++++++++++
local AU,AUN=0,0
--++++++++++++++

-- Updates the cost matrix to reflect the new minimum
local function UpdateCosts (vmin)
--+++++++++++
--[[
if NSTARS==419 and not AA then
	print("VMIN?", vmin)
	print("NUR/C", UncovRow.n, UncovCol.n)
	AA=true
end
]]
local au=oc()
--+++++++++++
--[[
	-- Add the minimum value to every element of each covered row...
	local ncc, nuc = CovCol.n, UncovCol.n

	for i = 1, CovRow.n do
		local ri = CovRow[i]

		for j = 1, ncc do
			local index = ri + CovCol[j]

			Costs[index] = Costs[index] + vmin
		end
	end

	-- ...subtracting it from every element of each uncovered column.
	for i = 1, UncovRow.n do
		local ri = UncovRow[i]

		for j = 1, nuc do
			local col = UncovCol[j]
			local index = ri + col
			local cost = Costs[index] - vmin

			Costs[index] = cost

			if cost == 0 then
				local zn = Zeroes.n

				Zeroes[zn + 1], Zeroes[zn + 2], Zeroes.n = ri, col, zn + 2
			end
		end
	end
]]
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
	local nc, nr = #MaskC, #MaskR
	do
		local rr = 0

		for i = 1, nr do
			local rbits = (2^52 - FreeR[i] - 1) % (MaskR[i] + 1)
			for _, _, rbit in PowersOf2(rbits) do
				local ri = (rr + rbit) * NCOLS + 1
				local cc = 0

				for j = 1, nc do
					local cbits = (2^52 - FreeC[j] - 1) % (MaskC[j] + 1)
					for _, _, cbit in PowersOf2(cbits) do
						local col = cc+cbit
						local index = ri + col

						Costs[index] = Costs[index] + vmin
					end
					cc=cc+52
				end
			end
			rr=rr+52
		end		
	end
	do
		local rr = 0

		for i = 1, nr do
			for _, _, rbit in PowersOf2(FreeR[i]) do
				local ri = (rr + rbit) * NCOLS + 1
				local cc = 0

				for j = 1, nc do
					for _, _, cbit in PowersOf2(FreeC[j]) do
						local col = cc+cbit
						local index = ri + col
						local cost = Costs[index] - vmin

						Costs[index] = cost

						if cost == 0 then
							local zn = Zeroes.n

							Zeroes[zn + 1], Zeroes[zn + 2], Zeroes.n = ri, col, zn + 2
						end
					end
					cc=cc+52
				end
			end
			rr=rr+52
		end
	end
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++
--2^32 - Fix(x) - 1
--+++++++++++
AU=AU+oc()-au
AUN=AUN+1
--+++++++++++
end

--++++++++++++++
local LP,LPN=0,0
local PZ,PZN=0,0
--++++++++++++++

--
local function BuildSolution_Square (out, n, ncols)
	local row = 1

	for ri = 1, n, ncols do
		out[row], row = RowStar[ri] + 1, row + 1
	end
end

--
local function DefYieldFunc () end

--- DOCME
-- @array costs
-- @uint ncols
-- @ptable[opt] opts
-- @treturn array out
function M.Run (costs, ncols, opts)
	local out = (opts and opts.into) or {}
	local yfunc = (opts and opts.yfunc) or DefYieldFunc

--+++++++++++
local lp=oc()
local sum=0
--+++++++++++

	local n, from = #costs, costs
	local nrows = ceil(n / ncols)
NCOLS=ncols
	--
	if ncols < nrows then
		local index = 1

		for i = 1, ncols do
			for j = i, n, ncols do
				Costs[index], index = costs[j], index + 1
			end
		end

		ncols, nrows, from = nrows, ncols, Costs
-- TODO: ^^^ Works? (Add resolve below, too...)
	end

	-- Kick off the algorithm with a first round of zeroes, starring as many as possible.
	SubtractSmallestRowCosts(from, n, ncols)
	StarSomeZeroes(n, ncols)
--	ClearCoverage(ncols, nrows)
--+++++
Clear()
--+++++
	--
	local do_check = true

	Zeroes.n = 0

	while true do
--+++++++++++++
sum=sum+oc()-lp
--+++++++++++++
		yfunc()
--+++++
lp=oc()
--+++++
		-- Check if the starred zeroes describe a complete set of unique assignments.
		if do_check then
			local ncovered = CountCoverage(n, ncols)

			if ncovered >= ncols or ncovered >= nrows then
				if from == Costs then
					-- Inverted, do something...
				end

				--
				if ncols == nrows then
					BuildSolution_Square(out, n, ncols)
				end

--++++++++++++++++++++++++++++++++++++
local left=oc()-lp
LP=LP+left
LPN=LPN+1

print("Loop", LP / LPN, LP)
print("  Prime zeroes", PZ / PZN, PZ)
print("  Actual update", AU / AUN, AU)
print("TOTAL", sum+left)
LP,LPN=0,0
PZ,PZN=0,0
AU,AUN=0,0
--++++++++++++++++++++++++++++++++++++
				return out
			else
				do_check = false
			end
		end
--+++++++++++
local pz=oc()
--+++++++++++
		-- Find a noncovered zero and prime it.
		local prow0, pcol0 = PrimeZeroes(ncols)

		Zeroes.n = 0
--+++++++++++
PZ=PZ+oc()-pz
PZN=PZN+1
--+++++++++++

		-- If there was no starred zero in the row containing the primed zero, try to build up a
		-- solution. On the next pass, check if this has produced a valid assignment.
		if prow0 then
			do_check = true

			BuildPath(prow0, pcol0, n, ncols, nrows)
--+++++++++++++
NSTARS=NSTARS+1
--+++++++++++++
		-- Otherwise, no uncovered zeroes remain. Update the matrix and do another pass, without
        -- altering any stars, primes, or covered lines.
		else
-- GETS STUCK HERE...
			UpdateCosts(pcol0)
		end
--+++++++++++
LP=LP+oc()-lp
LPN=LPN+1
--+++++++++++
	end
end

--- DOCME
-- @ptable t
-- @treturn array out
function M.Run_Labels (t)
	-- Set up the and do Run()
end

-- Export the module.
return M