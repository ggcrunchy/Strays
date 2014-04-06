--- Stuff from quaternions.

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

-- Something from Game Developer magazine

	local Neighborhood = .959066
	local Scale = 1.000311
	local AddK = Scale / math.sqrt(Neighborhood)
	local Factor = Scale * (-.5 / (Neighborhood * math.sqrt(Neighborhood))) 

	local function Norm (x, y)
		local s = x^2 + y^2
		local k1 = AddK + Factor * (s - Neighborhood)
		local k = k1

		if s < .83042395 then
			k = k * k1

			if s < .30174562 then
				k = k * k1
			end
		end

		return x * k, y * k, k, s
	end

	for i = 1, 20 do
		local x1 = random() --i / 21
		local x2 = random()

		for _ = 1, 10 do
			local y1 = math.sqrt(math.max(1 - x1^2, 0))
			local y2 = math.sqrt(math.max(1 - x2^2, 0))
			local t = random()
			local x, y = (1 - t) * x1 + t * x2, (1 - t) * y1 + t * y2
			local nx, ny, k, s = Norm(x, y)
			local len = math.sqrt(nx^2 + ny^2)

	if len < .95 or len > 1.05 then
	--	printf("K = %.4f, S = %.4f, t = %.3f, got len = %.4f", k, s, t, len)
	--	print("")
	end

		--	printf("Started with (%.4f, %.4f), got (%.4f, %.4f), len = %.6f", x, y, nx, ny, len)
		end
	end