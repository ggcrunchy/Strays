--- Testing Morton numbers.

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

local function MortonNaive (x, y, z)
	local result = 0

	for i = 0, 9 do
		local mask = lshift(1, i)
		local xm = band(x, mask)
		local ym = band(y, mask)
		local zm = band(z, mask)

		-- i(x) = i * 3 + 0
		-- i(y) = i * 3 + 1
		-- i(z) = i * 3 + 2
		-- shift(flag) = i * 3 + K - i = i * (3 - 1) + K = i * 2 + K
		local i0 = i * 2

		result = bor(result, lshift(xm, i0), lshift(ym, i0 + 1), lshift(zm, i0 + 2))
	end

	return result
end

-- Update tests

--[[
local mn = require("number_sequences.morton")

for _, x in ipairs{ 2, 27, 10003, 59253 } do
	for _, y in ipairs{ 900, 84, 10000, 60000 } do
		local num = mn.Morton2(x, y)
		local mx, my = mn.MortonPair(num)
		local x1, x2, y1, y2 = 32007, 803, 9339, 27

		local a1, b1 = mn.MortonPairUpdate_X(num, x1), mn.Morton2(x1, y)
		local a2, b2 = mn.MortonPairUpdate_X(num, x2), mn.Morton2(x2, y)
		local a3, b3 = mn.MortonPairUpdate_Y(num, y1), mn.Morton2(x, y1)
		local a4, b4 = mn.MortonPairUpdate_Y(num, y2), mn.Morton2(x, y2)

		print("MORTON2!", num, mx, my, a1 == b1, a2 == b2, a3 == b3, a4 == b4)
		print("")
	end
end

for _, x in ipairs{ 2, 27, 103, 5925 } do
	for _, y in ipairs{ 900, 84, 1000, 600 } do
		for _, z in ipairs{ 87, 1011, 330, 57 } do
			local num = mn.Morton3(x, y, z)
			local mx, my, mz = mn.MortonTriple(num)
			local x1, x2, y1, y2, z1, z2 = 307, 803, 933, 27, 402, 534

			local a1, b1 = mn.MortonTripleUpdate_X(num, x1), mn.Morton3(x1, y, z)
			local a2, b2 = mn.MortonTripleUpdate_X(num, x2), mn.Morton3(x2, y, z)
			local a3, b3 = mn.MortonTripleUpdate_Y(num, y1), mn.Morton3(x, y1, z)
			local a4, b4 = mn.MortonTripleUpdate_Y(num, y2), mn.Morton3(x, y2, z)
			local a5, b5 = mn.MortonTripleUpdate_Z(num, z1), mn.Morton3(x, y, z1)
			local a6, b6 = mn.MortonTripleUpdate_Z(num, z2), mn.Morton3(x, y, z2)

			print("MORTON3!", num, mx, my, mz, a1 == b1, a2 == b2, a3 == b3, a4 == b4, a5 == b5, a6 == b6)
			print("")
		end
	end
end
]]