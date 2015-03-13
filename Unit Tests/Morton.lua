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

local mc = require("number_sequences.morton")
---[=[
---[[
require("corona_utils.timers").WrapEx(function()
--]]
do
--[==[
	local xt = { 0, 47, 892, 1000, 1020, 3434, 5000, 6983, 23434, 32321, 50000, 65535 }
	for i, x in ipairs(xt) do
		local mx, my = mc.Morton2(0xFFFF, x), mc.Morton2(x, 0xFFFF)
		local yt, x2 = { 0, 89, 332, 933, 1001, 7000, 34343, 65535 }, xt[i+1]
		for j, y in ipairs(yt) do
--[[
			if mc.MortonPairUpdate_X(mx, y) ~= mc.Morton2(y, x) then
				print("Bad update2 x!", y, x)
			end
			if mc.MortonPairUpdate_Y(my, y) ~= mc.Morton2(x, y) then
				print("Bad update2 y!", x, y)
			end
--]]
---[[
			local y2, nx, ny = yt[j+1], 0, 0
			for num, xx in mc.Morton2_LineX(y, x, x2) do
				assert(xx >= x and (xx == 0xFFFF or xx <= x2), "Bad line x")
				assert(num == mc.Morton2(xx, y), "Bad line x solution")
				nx=nx+1
				if nx % 500 == 0 then coroutine.yield() end
			end
			coroutine.yield()
			print("X2!", x)

			for num, yy in mc.Morton2_LineY(x, y, y2) do
				assert(yy >= y and (yy == 0xFFFF or yy <= y2), "Bad line y")
				assert(num == mc.Morton2(x, yy), "Bad line y solution")
				ny=ny+1
				if ny % 500 == 0 then coroutine.yield() end
			end
			coroutine.yield()
			print("Y2!", y)
			assert(nx > 0 and ny > 0, "N2?")
--]]
		end
	end
--]==]
end
do
--[==[
	local xt = { 0, 55, 321, 676, 1020, 1023 }
	for i, x in ipairs(xt) do
		local yt, x2 = { 0, 89, 374, 500, 1001, 1023 }, xt[i+1]
		for j, y in ipairs(yt) do
			local mx, my, mz = mc.Morton3(0xFFFF, x, y), mc.Morton3(x, 0xFFFF, y), mc.Morton3(x, y, 0xFFFF)
			local zt, y2 = { 0, 200, 443, 500, 711, 1023 }, yt[j+1]
			for k, z in ipairs(zt) do
--[[
				if mc.MortonTripleUpdate_X(mx, z) ~= mc.Morton3(z, x, y) then
					print("Bad update3 x!", z, x, y)
				end
				if mc.MortonTripleUpdate_Y(my, z) ~= mc.Morton3(x, z, y) then
					print("Bad update3 y!", x, z, y)
				end
				if mc.MortonTripleUpdate_Z(mz, z) ~= mc.Morton3(x, y, z) then
					print("Bad update3 z!", x, y, z)
				end
--]]
---[[
				local z2, nx, ny, nz = zt[k+1], 0, 0, 0
				for num, xx in mc.Morton3_LineX(y, z, x, x2) do
					assert(xx >= x and (xx == 0x3FF or xx <= x2), "Bad line x")
					assert(num == mc.Morton3(xx, y, z), "Bad line x solution")
					nx=nx+1
					if nx % 500 == 0 then coroutine.yield() end
				end
				coroutine.yield()
				print("X3!")
				for num, yy in mc.Morton3_LineY(x, z, y, y2) do
					assert(yy >= y and (yy == 0x3FF or yy <= y2), "Bad line y")
					assert(num == mc.Morton3(x, yy, z), "Bad line y solution")
					ny=ny+1
					if ny % 500 == 0 then coroutine.yield() end
				end
				coroutine.yield()
				print("Y3!")
				for num, zz in mc.Morton3_LineZ(x, y, z, z2) do
					assert(zz >= z and (zz == 0x3FF or zz <= z2), "Bad line z")
					assert(num == mc.Morton3(x, y, zz), "Bad line z solution")
					nz=nz+1
					if nz % 500 == 0 then coroutine.yield() end
				end
				coroutine.yield()
				print("Z3!")
				if nx == 0 or ny == 0 or nz == 0 then
					print("N3?", nx, ny, nz)
				end
--]]
			end
		end
	end
--]==]
end

---[[
print("Woo!")
end, 50)
--]]
--]=]