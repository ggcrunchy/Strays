--- Bitwise-variant operations for the Hungarian algorithm module.

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
local min = math.min
local huge = math.huge

-- Modules --
local log2 = require("bitwise_ops.log2")
local operators = require("bitwise_ops.operators")
local vector = require("bitwise_ops.vector")

-- Imports --
local band = operators.band
local bnot = operators.bnot
local bor = operators.bor
local lshift = operators.lshift
local rshift = operators.rshift

-- Exports --
local M = {}

-- --
local FreeCols, MaskCols = {}, {}
local FreeRows, MaskRows = {}, {}

-- --
local ColN, RowN

-- --
local FlatCovColN, FlatUncovColN
local FlatCovRowN, FlatUncovRowN

--- DOCME
function M.ClearCoverage (ncols, nrows, is_first)
	if is_first then
--[[
		--
		ColN = ceil(ncols / 32)
		MaskCols[ColN] = lshift(1, ncols) - 1

		for i = 1, ColN - min(1, MaskCols[ColN]) do
			MaskCols[i] = 0xFFFFFFFF
		end

		--
		RowN = ceil(nrows / 32)
		MaskRows[RowN] = lshift(1, nrows) - 1

		for i = 1, RowN - min(1, MaskRows[RowN]) do
			MaskRows[i] = 0xFFFFFFFF
		end
--]]
		vector.Init(FreeCols, ncols)
		vector.Init(FreeRows, nrows)
	else
		vector.SetAll(FreeCols)
		vector.SetAll(FreeRows)
	end
--[[
	--
	for i = 1, RowN do
		FreeCols[i] = MaskCols[i]
		FreeRows[i] = MaskRows[i]
	end

	for i = RowN + 1, ColN do
		FreeCols[i] = MaskCols[i]
	end
--]]
	--
	FlatCovColN, FlatUncovColN = nil
	FlatCovRowN, FlatUncovRowN = nil
end

--
local function AuxCover (i)
	return rshift(i, 5) + 1, lshift(1, i)
end

--- DOCME
function M.CoverColumn (col)
--[[
	local index, bit = AuxCover(col)
	local old = FreeCols[index]
	local new = band(old, bnot(bit))

	if old ~= new then
		FreeCols[index], FlatCovColN, FlatUncovColN = new
	end
]]
	if vector.Clear(FreeCols, col) then
		FlatCovColN, FlatUncovColN = nil
	end
end

--- DOCME
function M.CoverRow (row)
--[[
	local index, bit = AuxCover(row)
	local old = FreeRows[index]
	local new = band(old, bnot(bit))

	if old ~= new then
		FreeRows[index], FlatCovRowN, FlatUncovRowN = new

		return true
	end
]]
	if vector.Clear(FreeRows, row) then
		FlatCovRowN, FlatUncovRowN = nil

		return true
	end
end

-- --
local Lg = log2.PopulateMod59()

--
local function Populate (arr, from, n, mask)
	local count, offset = 0, 0

	for i = 1, n do
		local bits = from[i]

		if mask then
			bits = band(bnot(bits), mask[i])
		end

		while bits ~= 0 do
			local bit, pos = band(bits, -bits)

			if bit > 0 then
				bits, pos = bits - bit, offset + Lg[bit % 59]
			else
				bits, pos = 0, offset + 31
			end

			arr[count + 1], count = pos, count + 1
		end

		offset = offset + 32
	end

	return count
end

-- --
local FlatUncovCols, FlatUncovRows = {}, {}

--- DOCME
function M.FindZero (costs, ncols)
	FlatUncovColN = FlatUncovColN or vector.GetIndices_Set(FlatUncovCols, FreeCols)--Populate(FlatUncovCols, FreeCols, ColN)
	FlatUncovRowN = FlatUncovRowN or vector.GetIndices_Set(FlatUncovRows, FreeRows)--Populate(FlatUncovRows, FreeRows, RowN)

	local vmin = huge

	for i = 1, FlatUncovRowN do
		local ri = FlatUncovRows[i] * ncols + 1

		for j = 1, FlatUncovColN do
			local col = FlatUncovCols[j]
			local cost = costs[ri + col]

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
end

--- DOCME
function M.GetCount (ncols)
	--[[
	local bits = 0

	for i = 1, ColN do
		bits = bor(FreeCols[i], bits)
	end
]]
	return vector.AllClear(FreeCols)--[[bits == 0]] and ncols or 0
end

--- DOCME
function M.UncoverColumn (col)
--[[
	local index, bit = AuxCover(col)
	local old = FreeCols[index]
	local new = bor(old, bit)

	if old ~= new then
		FreeCols[index], FlatCovColN, FlatUncovColN = new
	end]]


	if vector.Set(FreeCols, col) then
		FlatCovRowN, FlatUncovRowN = nil
	end
end

-- --
local FlatCovCols, FlatCovRows = {}, {}

--- DOCMEMORE
-- Updates the cost matrix to reflect the new minimum
function M.UpdateCosts (vmin, costs, zeroes, ncols)
	--
	FlatCovColN = FlatCovColN or vector.GetIndices_Clear(FlatCovCols, FreeCols)--Populate(FlatCovCols, FreeCols, ColN, MaskCols)
	FlatCovRowN = FlatCovRowN or vector.GetIndices_Clear(FlatCovRows, FreeRows)--Populate(FlatCovRows, FreeRows, RowN, MaskRows)

	--
	for i = 1, FlatCovRowN do
		local ri = FlatCovRows[i] * ncols + 1

		for j = 1, FlatCovColN do
			local index = ri + FlatCovCols[j]

			costs[index] = costs[index] + vmin
		end
	end

	--
	FlatUncovColN = FlatUncovColN or vector.GetIndices_Set(FlatUncovCols, FreeCols)--Populate(FlatUncovCols, FreeCols, ColN)
	FlatUncovRowN = FlatUncovRowN or vector.GetIndices_Set(FlatUncovRows, FreeRows)--Populate(FlatUncovRows, FreeRows, RowN)

	for i = 1, FlatUncovRowN do
		local ri = FlatUncovRows[i] * ncols + 1

		for j = 1, FlatUncovColN do
			local col = FlatUncovCols[j]
			local index = ri + col
			local cost = costs[index] - vmin

			costs[index] = cost

			if cost == 0 then
				local zn = zeroes.n

				zeroes[zn + 1], zeroes[zn + 2], zeroes.n = ri, col, zn + 2
			end
		end
	end
end

-- Export the module.
return M