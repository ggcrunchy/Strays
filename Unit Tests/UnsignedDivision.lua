--- Tests of "magic numbers" for unsigned integer division.

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

--[=[
-- Cached logarithm --
local Lg2 = math.log(2)

--- DOCME
-- "Simple code in Python" from Hacker's Delight
function MagicGU (nmax, d)
	local nc, two_p = math.floor(nmax / d) * d - 1, 1
	local nbits = math.floor(math.log(nmax) / Lg2) + 1

	for p = 0, 2 * nbits + 1 do
		local q = d - 1 - (two_p - 1) % d

		if two_p > nc * q then
			local m = math.floor((two_p + q) / d)

			return m, p
		end

		two_p = two_p + two_p
	end
end

local M, P = 1,0

local list = {}
local N=1e7
for i = 1, N do--2048 do
	local m, p = MagicGU(i, 53)
	if m ~= M or p ~= P then
		print("As of", i - 1, m, p)
		M, P = m, p
		list[#list+1]=M
		list[#list+1]=P
		list[#list+1]=i - 1
	end
end

for i = 1, #list, 3 do
	local m, p, start, next = list[i], list[i + 1], list[i + 2], list[i + 5] or N--2048
	local k = m * 2^-p
	if i == 1 then
		start = 0
	end
	print("m, p", m, p, start, next - 1)
	for j = start, next - 1 do
		if j % 53 ~= j - math.floor(j * k) * 53 then
			print("SHUCKS :(", j)
			break
		end
	end
	print("YEAH!")
end
--]=]
--[=[
local K = 39 * 2^-11
print(57 % 53, 57 - math.floor(57 * K) * 53)
print((57 - 4) * K)

for i = 0, 105 do
	local pos = i % 53
	local slot = (i - pos) / 53 + 1
	local jj = math.floor(i * K)
	local SLOT = jj + 1
	local POS = i - jj * 53
	print(slot==SLOT, pos==POS)
end
--]=]
--[[
local div = require("number_ops.divide")
local m = div.GenerateUnsignedConstants(105, 53, true)
for i = 0, 105 do
	local a, b = div.DivRem(i, 53)
	local c, d = div.DivRem_Magic(i, 53, m)
	print(a==c, b==d)
end
--]]