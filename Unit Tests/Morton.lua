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