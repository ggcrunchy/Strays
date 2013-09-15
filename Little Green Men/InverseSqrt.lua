--- Trying out different ways to simulate inverse square root.

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

do
	local Neighborhood = .959066
	local Scale = 1.000311
	local AddK = Scale / math.sqrt(Neighborhood)
	local Factor = Scale * (-.5 / (Neighborhood * math.sqrt(Neighborhood)))
	local K2 = AddK - Factor * Neighborhood
local floor = math.floor
local pow = math.pow
	--
	local function Norm_Basic (s)
	--	local k = K2 + Factor * s
local a = floor(.83042395 - s)
local b = floor(.30174562 - s)
--[[
		if s < .83042395 then
			if s < .30174562 then
				k = k * k * k
			else
				k = k * k
			end
		end
]]
		return pow(K2 + Factor * s, 1 - (a + b))
	end

	--- DOCME
	local abs=math.abs
local log=math.log
local exp=math.exp
-- Note: magnitude should be close to 1
	function Norm2 (x, y)
		local ax, ay = abs(x), abs(y)
		local isum = 1 / (ax + ay)

		local k = Norm_Basic(1 - 2 * ax * ay * isum * isum) * isum

		return x * k, y * k
	end
local K3 = K2 + Factor
local F2 = -2 * Factor

	--- DOCME
	function Norm2_Newton (x, y)
		local p = abs(x * y)
		local q = exp(-.5 * log(x * x + y * y + p + p))
		local prod = p * q * q
		local k, s = 1 + prod, .5 - prod

		k = k * (1.5 - s * k * k)
		k = k * (1.5 - s * k * k)
		k = k * q

		return x * k, y * k
	end

	--- DOCME
	function Norm3_Newton (x, y, z)
		local ax, ay, az = abs(x), abs(y), abs(z)
		local isum = 1 / (ax + ay + az)
		local prod = (ax * (ay + az) + ay * az) * isum * isum
		local s = .5 - prod
--		local s = (x * x + y * y) / (x * x + 2 * x * y + y * y)
		local k = .99963715362155 + 1.0650311300369 * prod

	--	s = .5 * s

		k = k * (1.5 - s * k * k)
		k = k * (1.5 - s * k * k)
k = k * isum
		return x * k, y * k, z * k
	end

	--- DOCME
	function Norm4_Newton (x, y, z, w)
		local ax, ay, az, aw = abs(x), abs(y), abs(z), abs(w)
		local isum = 1 / (ax + ay + az + aw)
		local prod = (ax * ay + (ax + ay) * (az + aw) + az * aw) * isum * isum
		local s = .5 - prod
--		local s = (x * x + y * y) / (x * x + 2 * x * y + y * y)
		local k = .99963715362155 + 1.0650311300369 * prod

	--	s = .5 * s

		k = k * (1.5 - s * k * k)
		k = k * (1.5 - s * k * k)
k = k * isum
		return x * k, y * k, z * k, w * k
	end

end

function printf (s, ...)
	print(s:format(...))
end

--[[
for i = 1, 50, 3 do
	for j = 1, 50, 4 do
		local d = math.sqrt(i*i+j*j)
		local x, y = Norm2(i, j)
		local X, Y = Norm2_Newton(i, j)
		printf("(%i, %i) -> S: (%.3f, %.3f) N2: (%.3f, %.3f) N2N: (%.3f, %.3f)", i, j, i / d, j / d, x, y, X, Y)
	end
end

--]]

--[[
for i = 1, 50, 3 do
	for j = 1, 50, 4 do
		for k = 1, 50, 5 do
			local d = math.sqrt(i*i+j*j+k*k)
			local X, Y, Z = Norm3_Newton(i, j, k)
			printf("(%i, %i, %i) -> S: (%.3f, %.3f, %.3f) N2N: (%.3f, %.3f, %.3f)", i, j, k, i / d, j / d, k / d, X, Y, Z)
		end
	end
end

--]]

--[[
local mine, maxe = 1000, -1000
for i = 1, 50, 3 do
	for j = 1, 50, 4 do
		for k = 1, 50, 5 do
			for l = 1, 50, 6 do
				local d = math.sqrt(i*i+j*j+k*k+l*l)
				local X, Y, Z, W = Norm4_Newton(i, j, k, l)
				printf("(%i, %i, %i, %i) -> S: (%.3f, %.3f, %.3f, %.3f) N2N: (%.3f, %.3f, %.3f, %.3f)", i, j, k, l, i / d, j / d, k / d, l / d, X, Y, Z, W)
			end
		end
	end
end
printf("Min = %.12f, Max = %.12f", mine, maxe)
--]]

--[[
for i = 1, 50, 3 do
	for j = 1, 50, 4 do
		local d = math.sqrt(i*i+j*j)
--		local denom = 1-- / (i + j)
		local x, y = Norm2(i, j)-- * denom, j * denom)
		local X, Y = Norm2_Newton(i, j)-- * denom, j * denom)
		printf("(%i, %i) -> S: (%.3f, %.3f) N2: (%.3f, %.3f) N2N: (%.3f, %.3f)", i, j, i / d, j / d, x, y, X, Y)
	end
end

--]]

---[=[
local clock, sqrt, n2, n2n = os.clock, math.sqrt, Norm2, Norm2_Newton

local n = 0

for i = 1, 50000, 3 do
	for j = 1, 50000, 4 do
		n = n + 1
	end
end

local t1 = clock()

for i = 1, 50000, 3 do
	for j = 1, 50000, 4 do
		local d = 1 / sqrt(i*i+j*j)
		local x, y = i * d, j * d
	end
end

local t2 = clock()

for i = 1, 50000, 3 do
	for j = 1, 50000, 4 do
--		local d = 1 / (i + j)
		local x, y = n2(i, j)-- * d, j * d)
	end
end

local t3 = clock()

for i = 1, 50000, 3 do
	for j = 1, 50000, 4 do
--		local d = 1 / (i + j)
		local x, y = n2n(i, j)-- * d, j * d)
	end
end

local t4 = clock()

printf("Sqrt = %.12f, norm basic = %.12f, norm newton = %.12f", (t2 - t1) / n, (t3 - t2) / n, (t4 - t3) / n)
--]=]

--[=[
local clock, sqrt, n3 = os.clock, math.sqrt, Norm3_Newton

local n = 0

for i = 1, 5000, 3 do
	for j = 1, 5000, 4 do
		for k = 1, 5000, 5 do
			n = n + 1
		end
	end
end

local t1 = clock()

for i = 1, 5000, 3 do
	for j = 1, 5000, 4 do
		for k = 1, 5000, 5 do
			local d = 1 / sqrt(i*i+j*j+k*k)
			local x, y, z = i * d, j * d, k * d
		end
	end
end

local t2 = clock()

for i = 1, 5000, 3 do
	for j = 1, 5000, 4 do
		for k = 1, 5000, 5 do
			local x, y, z = n3(i, j, k)
		end
	end
end

local t3 = clock()

printf("Sqrt = %.12f, norm3 newton = %.12f", (t2 - t1) / n, (t3 - t2) / n)
--]=]

--[=[
local clock, sqrt, n4 = os.clock, math.sqrt, Norm4_Newton

local n = 0

for i = 1, 500, 3 do
	for j = 1, 500, 4 do
		for k = 1, 500, 5 do
			for l = 1, 500, 6 do
				n = n + 1
			end
		end
	end
end

local t1 = clock()
local p = math.pow
for i = 1, 500, 3 do
	for j = 1, 500, 4 do
		for k = 1, 500, 5 do
			for l = 1, 500, 6 do
				local d = 1 / sqrt(i*i+j*j+k*k+l*l)
				local x, y, z, w = i * d, j * d, k * d, l * d
			end
		end
	end
end

local t2 = clock()

for i = 1, 500, 3 do
	for j = 1, 500, 4 do
		for k = 1, 500, 5 do
			for l = 1, 500, 6 do
				local x, y, z, w = n4(i, j, k, l)
			end
		end
	end
end

local t3 = clock()

printf("Sqrt = %.12f, norm4 newton = %.12f", (t2 - t1) / n, (t3 - t2) / n)
--]=]