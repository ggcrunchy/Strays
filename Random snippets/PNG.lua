--- Some PNG stuff that ought to be superceded by now.

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

-- Reads a 4-byte hex out of a file as an integer
-- TODO: This must be feasible in a more clean way...
local function HexToNum (file)
	local sum, mul, str = 0, 2^24, file:read(4)

	for char in str:gmatch(".") do
		local num = char:byte()

		if num ~= 0 then
			sum = sum + mul * num
		end

		mul = mul / 256
	end

	return sum
end



	-- In the simulator, figure out the scaling.
	local xscale, yscale

	if system.getInfo("platformName") == "Win" then
		xscale, yscale = 2, 1.95 -- If reading the PNG fails, punt...

		local png = open(system.pathForFile(name, base_dir), "rb")

		if png then
			png:read(12)

			if png:read(4) == "IHDR" then
				xscale = w / HexToNum(png)
				yscale = h / HexToNum(png)
			end

			png:close()
		end
	end

	return name, xscale or 1, yscale or 1