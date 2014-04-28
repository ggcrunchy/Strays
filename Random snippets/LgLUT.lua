--- Used to generate LUT's for binary logarithm.

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

local Count = 32 -- 55 is another decent one (powers of 2 representable in doubles)
local Sieve = {}
for i = 2, 61 do
	local prime = true
	for k in pairs(Sieve) do
		if i % k == 0 then
			prime = false
			break
		end
	end
	if prime then
		Sieve[i] = true
		if i >= Count then
			local lg = {}
			for j = 1, i do
				lg[j] = false
			end
			local n = 1
			for k = 0, Count - 1 do
				lg[2^k % i], n = k, 2 * n
			end
			local good = true
			for k = 0, Count - 1 do
				if lg[2^k % i] ~= k then
					good = false
					break
				end
			end
			if good then
				print("HUZZAH!", i)
				vdump(lg)
				break
			end
		end
	end
end