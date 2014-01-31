--- Stuff from Hacker's Delight... maybe useful if I ever play with z80 again?

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
local floor = math.floor
local log = math.log

-- Modules --
local has_bit, bit = pcall(require, "bit") -- Prefer BitOp

if not has_bit then
	bit = bit32 -- Fall back to bit32 if available
end

-- Forward references --
local lshift
local rshift

-- Imports --
if bit then -- Bit library available
	lshift = bit.lshift
	rshift = bit.rshift
else -- Otherwise, make equivalents for division constant purposes
	lshift = math.ldexp

	function rshift (x, n)
		return floor(lshift(x, -n))
	end
end

-- Exports --
local M = {}

--- DOCME
function M.DivU_MP (x, m, p)
	return rshift(x * m, p)
end

-- Cached logarithm --
local Lg2 = log(2)

--- DOCME
-- "Simple code in Python" from Hacker's Delight
function M.MagicGU (nmax, d)
	local nc, two_p = floor(nmax / d) * d - 1, 1
	local nbits = floor(log(nmax) / Lg2) + 1

	for p = 0, 2 * nbits + 1 do
		local q = d - 1 - (two_p - 1) % d

		if two_p > nc * q then
			local m = floor((two_p + q) / d)

			return m, p
		end

		two_p = two_p + two_p
	end
end

return M