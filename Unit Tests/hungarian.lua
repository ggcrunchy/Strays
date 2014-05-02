--- Failed bitwise Hungarian stuff.

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
local log2 = require("bitwise_ops.log2")
local operators = require("bitwise_ops.operators")

-- Imports --
local Lg_PowerOf2 = log2.Lg_PowerOf2

-- Forward declarations --
local ClearCoverage
local CoverColumn
local CoverRow
local FindZero
local GetCount
local UncoverColumn
local UpdateCosts

-- Exports --
local M = {}

--+++++++++++++++
local oc=os.clock
--+++++++++++++++

-- --
local Costs = {}

-- --
local Zeroes = {}

--
if operators.HasBitLib() then
	local band = operators.band
	local bnot = operators.bnot
	local bor = operators.bor
	local bxor = operators.bxor
	local lshift = operators.lshift
	local rshift = operators.rshift

	-- --
	local FreeCols, MaskCols = {}, {}
	local FreeRows, MaskRows = {}, {}

	-- --
	local ColN, RowN

	--
	function ClearCoverage (ncols, nrows, is_first)
		if is_first then
			--
			ColN = ceil(ncols / 32)

			for i = 1, ColN - 1 do
				MaskCols[i] = 0xFFFFFFFF
			end

			MaskCols[ColN] = lshift(1, ncols) - 1

			--
			RowN = ceil(nrows / 32)

			for i = 1, RowN - 1 do
				MaskRows[i] = 0xFFFFFFFF
			end

			MaskRows[RowN] = lshift(1, nrows) - 1
		end

		--
		for i = 1, RowN do
			FreeCols[i] = MaskCols[i]
			FreeRows[i] = MaskRows[i]
		end

		for i = RowN + 1, ColN do
			FreeCols[i] = MaskCols[i]
		end
	end

	--
	local function AuxCover (i)
		return rshift(i, 5) + 1, lshift(1, i)
	end

	--
	function CoverColumn (col)
		local index, bit = AuxCover(col)

		FreeCols[index] = band(FreeCols[index], bnot(bit))
	end

	--
	function CoverRow (row)
		local index, bit = AuxCover(row)
		local old = FreeRows[index]
		local new = band(old, bnot(bit))

		FreeRows[index] = new

		return old ~= new
	end

	--
	local function AuxPowers (offset, bits)
		if bits ~= 0 then
			local bit = band(bits, -bits)

			if bit > 0 then
				return bxor(bits, bit), Lg_PowerOf2(bit) + offset
			else
				return 0, offset + 31
			end
		end
	end

	--
	local function Powers (bits, offset)
		return AuxPowers, offset, bits
	end
local Lg = {}

-- Fill in the values and plug holes.
do
	local n = 1

	for i = 0, 54 do
		Lg[n % 59], n = i, 2 * n
	end

	Lg[15] = false
	Lg[30] = false
	Lg[37] = false
end
	--
	function FindZero (ncols)
		local roff, vmin = 0, huge

		for i = 1, RowN do
		--	for _, rpos in Powers(FreeRows[i], roff) do
			local rbits, rpos = FreeRows[i]

			while rbits ~= 0 do
				local rbit = band(rbits, -rbits)

				if rbit > 0 then
					rbits, rpos = rbits - rbit--[[bxor(rbits, rbit)]], Lg[rbit % 59] + roff--Lg_PowerOf2(rbit) + roff
				else
					rbits, rpos = 0, roff + 31
				end

				local coff, ri = 0, rpos * ncols + 1

				for j = 1, ColN do
				--	for _, col in Powers(FreeCols[j], coff) do
					local cbits, col = FreeCols[j]

					while cbits ~= 0 do
						local cbit, cpos = band(cbits, -cbits)

						if cbit > 0 then
							cbits, col = cbits - cbit--[[bxor(cbits, cbit)]], Lg[cbit % 59] + coff--Lg_PowerOf2(cbit) + coff
						else
							cbits, col = 0, coff + 31
						end

						local cost = Costs[ri + col]

						if cost < vmin then
							if cost == 0 then
								return ri, col
							else
								vmin = cost
							end
						end
					end

					coff = coff + 32
				end
			end

			roff = roff + 32
		end
--print("NUTS")
		return vmin
	end

	--
	function GetCount (ncols)
		local bits = 0

		for i = 1, ColN do
			bits = bor(FreeCols[i], bits)
		end
--[[
print("")
for i = 1, ColN do
	print(("%x"):format(FreeCols[i]))
end
print("")
]]
		return bits == 0 and ncols or 0
	end

	--
	function UncoverColumn (col)
		local index, bit = AuxCover(col)

		FreeCols[index] = bor(FreeCols[index], bit)
	end

	--
	function UpdateCosts (vmin, ncols)
		local roff = 0
--print("UPDATING")
		for i = 1, RowN do
			local rbits = band(bnot(FreeRows[i]), MaskRows[i])

			for _, rpos in Powers(rbits, roff) do
				local coff = rpos * ncols + 1

				for j = 1, ColN do
					local cbits = band(bnot(FreeCols[j]), MaskCols[j])

					for _, index in Powers(cbits, coff) do
						Costs[index] = Costs[index] + vmin
					end

					coff = coff + 32
				end
			end

			roff = roff + 32
		end
--print("ONE")
		roff = 0

		for i = 1, RowN do
			for _, rpos in Powers(FreeRows[i], roff) do
				local coff, ri = 0, rpos * ncols + 1

				for j = 1, ColN do
					for _, col in Powers(FreeCols[j], coff) do
						local index = ri + col
						local cost = Costs[index] - vmin

						Costs[index] = cost

						if cost == 0 then
							local zn = Zeroes.n

							Zeroes[zn + 1], Zeroes[zn + 2], Zeroes.n = ri, col, zn + 2
						end
					end

					coff = coff + 32
				end
			end

			roff = roff + 32
		end
--print("TWO")
	end
end










--++++++++++++++++++++++++++++++++++++++++
local STATE={}
local NCOLS, NROWS
local function C (i, qt)
	local cost = Costs[i] or 0
	if cost < 1e11 then
		if cost ~= 0 then
			if qt then
				qt[#qt + 1] = cost
			end
			return "?"
		else
			return STATE[i]
		end
	else
		return "!"
	end
end
function DUMP (what, phase, qs)
	if AA then return end
	print(what)
	for i = 1, NCOLS^2 do
		STATE[i]="0"
	end
	if not phase or phase == 2 then
		for row = 1, NROWS do
			local ri = (row - 1) * NCOLS + 1
			local col = RowStar[ri]
			if col < NCOLS then
				STATE[ri + col] = "*"
			end
		end
		for ri, col in pairs(Primes) do
			STATE[ri + col] = "P"
		end
	end
	print("************************")
	local index, qt = 1, qs and {}
	for _ = 1, NROWS do
		local t={}
		for _ = 1, NCOLS do
			t[#t+1], index = C(index, qt), index + 1
		end
		print(table.concat(t, " "))
	end
	print("************************")
	if false then--not phase then
		for i = 1, NCOLS do
			if vector.IsBitClear(FreeColBits, i - 1) then
				print("Column " .. i .. " covered")
			end
		end
		for i = 1, NROWS do
			if vector.IsBitClear(FreeRowBits, i - 1) then
				print("Row " .. i .. " covered")
			end
		end
	end
	if qt and #qt > 0 then
		vdump(qt)
	end
	print("")
end
--++++++++++++++++++++++++++++++++++++++++
