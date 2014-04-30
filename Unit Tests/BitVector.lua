--- Bit vector tests.

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

--package.loaded.bit = require("plugin.bit")

--[=[
local bb=package.loaded.bit

local band=bb.band
local bnot=bb.bnot
local bor=bb.bor
local bxor=bb.bxor
local lshift=bb.lshift
local rshift=bb.rshift

function AuxInit (n, clear)
	return rshift(n, 5), band(n, 0x1F), 32
end

function Init (arr, n, clear)
	local mask, nblocks, tail, power = 0, AuxInit(n, clear)

	if tail > 0 then
		nblocks, mask = nblocks + 1, 2^tail - 1
	end

	local fill = clear and 0 or 2^power - 1

	for i = 1, nblocks do
		arr[i] = fill
	end

	if mask ~= 0 and not clear then
		arr[nblocks] = mask
	end

	arr.n, arr.mask = nblocks, mask
end

local function AuxGet (out, bits, ri, wi)
	--
--	bits=math.abs(bits)
	local j = wi + 1

	while bits ~= 0 do
		local _, e = math.frexp(bits)
		local pos = e - 1

		out[j], j, bits = ri + pos, j + 1, bits - 2^pos
	end

	--
	local l, r = wi + 1, j

	while l < r do
		r = r - 1

		out[l], out[r], l = out[r], out[l], l + 1
	end

	return j - 1
end

function GetIndices_Clear (out, from)
	local count, offset, n, mask = 0, 0, from.n, from.mask

	if mask ~= 0 then
		n = n - 1
	end

	for i = 1, n do
		local bits = bnot(from[i])

		if bits < 0 then
			bits = bits + 2^32
		end

		count, offset = AuxGet(out, bits, offset, count), offset + 32
	end

	if mask ~= 0 then
		count = AuxGet(out, band(bnot(from[n + 1]), mask), offset, count)
	end

	return count
end

function GetIndices_Set (out, from)
	local count, offset = 0, 0

	for i = 1, from.n do
		local bits = from[i]

		if bits < 0 then
			bits = bits + 2^32
		end

		count, offset = AuxGet(out, bits, offset, count), offset + 32
	end

	return count
end

	function AuxAllSet (arr, n)
		local bits = arr[1]

		for i = 2, n do
			bits = band(arr[i], bits)
		end

		return bxor(bits, 0xFFFFFFFF) == 0
	end

function AllSet (arr)
	local n, mask = arr.n, arr.mask

	if mask ~= 0 then
		if mask ~= arr[n] then -- In bitwise version, mask less than 2^31
			return false
		end

		n = n - 1
	end

	return AuxAllSet(arr, n)
end

function Clear (arr, index)
	local slot, bit = rshift(index, 5) + 1, lshift(1, index)
	local old = arr[slot]
	--[[
	local new = band(old, bnot(bit))

	if new < 0 then
		new = new + 2^32
	end
]]
	arr[slot] = band(old, bnot(bit))--new

	return band(old, bit) ~= 0--old ~= new
end

function Set (arr, index)
	local slot, bit = rshift(index, 5) + 1, lshift(1, index)
	local old = arr[slot]
--[[
	local new = bor(old, bit)

	if new < 0 then
		new = new + 2^32
	end
]]
	arr[slot] = bor(old, bit)--new

	return band(old, bit) == 0--old ~= new
end

local AA={}

Init(AA, 33)

local function VDUMP (out)
	vdumpx(out)
	for i = #out, 1, -1 do
		out[i] = nil
	end
end

vdumpx(AA)
print("ALL SET?", AllSet(AA))
local out={}
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("SET?", Set(AA, 3))
print("ALL SET?", AllSet(AA))
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("GET # CLEARED", GetIndices_Clear(out, AA))
VDUMP(out)
print("CLEAR?", Clear(AA, 13))
print("ALL SET?", AllSet(AA))
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("GET # CLEARED", GetIndices_Clear(out, AA))
VDUMP(out)
print("CLEAR?", Clear(AA, 32))
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("GET # CLEARED", GetIndices_Clear(out, AA))
VDUMP(out)
print("CLEAR?", Clear(AA, 31))
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("GET # CLEARED", GetIndices_Clear(out, AA))
VDUMP(out)
print("SET?", Set(AA, 31))
print("GET # SET", GetIndices_Set(out, AA))
VDUMP(out)
print("GET # CLEARED", GetIndices_Clear(out, AA))
VDUMP(out)
--]=]