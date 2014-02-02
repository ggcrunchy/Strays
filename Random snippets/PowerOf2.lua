--- Old way I did "lowest power of 2" function, with emulation fallback... not very robust with bits 31+.

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

-- Modules --
local has_bit, bit = pcall(require, "bit") -- Prefer BitOp

if not has_bit then
	bit = bit32 -- Fall back to bit32 if available
end

-- Forward references --
local band_lz

-- Imports --
if bit then -- Bit library available
	band_lz = bit.band
else -- Otherwise, make equivalents for low-bit purposes
	local lshift = math.ldexp

	-- Number of trailing zeroes helper
	local function ntz (x)
		if x == 0 then
			return 32
		else
			local n, s = 31, 16

			repeat
				local y = lshift(x, s) % 2^32

				if y ~= 0 then
					n, x = n - s, y
				end

				s = .5 * s
			until s < 1

			return n
	   end
	end

	-- One-deep memoization --
	local Bits, NI

	function band_lz (x)
		local n, tries = Bits == x and NI or lshift(1, ntz(x)), 0

		repeat
			local next = n + n

			if tries == 3 or x % next == n then
				if tries == 3 then
					n = lshift(1, ntz(x))
					next = n + n
				end

				Bits, NI = x - n, next

				return n
			end

			n, tries = next, tries + 1
		until x < n

		Bits = nil

		return 0
	end
end

-- Exports --
local M = {}

--- Getter.
-- @uint n Integer.
-- @treturn uint If _n_ > 0, lowest power of 2 in _n_; otherwise, 0.
function M.GetLowestPowerOf2 (n)
	return n > 0 and band_lz(n, -n) or 0
end

return M