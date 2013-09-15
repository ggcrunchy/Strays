--- Testing simplex noise.

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

-- For testing, uncomment these:
  -- local t1 = os.clock() -- For total time
  -- local C, Cmin, Cmax -- Return value scalar
  -- function printf (s, ...) print(string.format(s, ...)) end
    

--[[
	-- Timing test, 2D case
	local S = M.Simplex2D
	local mmin, mmax = math.min, math.max
	local fmin, fmax = 10000, -10000
	local v = require("jit.dump")
	local t1 = os.clock()
-- v.start("tisH", "SOME_DIRECTORY/Simplex2D.html")	-- Customize this
--[=[
	for k = 1, 500 do
		local fmin2, fmax2 = fmin, fmax
		fmin, fmax = 10000, -10000
		C = 83 + k * .006 -- Subtitute C for constant on return line above
--]=]
	for i = -2500, 2500 do
		for j = -2500, 2500 do
			local f = S(i + .5, j + .3)
			fmin = mmin(fmin, f)
			fmax = mmax(fmax, f)
		end
	end
--[=[
		if fmin < fmin2 and fmin >= -1 then
			Cmin = C
		else
			fmin = fmin2
		end

		if fmax > fmax2 and fmax <= 1 then
			Cmax = C
		else
			fmax = fmax2
		end
	end
	printf("Simplex2D: min = %f, max = %f, Cmin = %f, Cmax = %f", fmin, fmax, Cmin, Cmax)
--]=]
-- v.off()
	printf("Simplex2D: time / call = %.9f, min = %f, max = %f", (os.clock() - t1) / (5001 * 5001), fmin, fmax)
--]]

--[[
	-- Timing test, 3D case
	local S = M.Simplex3D
	local mmin, mmax = math.min, math.max
	local fmin, fmax = 10000, -10000
	local v = require("jit.dump")
	local t1 = os.clock()
-- v.start("tisH", "SOME_DIRECTORY/Simplex3D.html")	-- Customize this
--[=[
	for l = 1, 500 do
		local fmin2, fmax2 = fmin, fmax
		fmin, fmax = 10000, -10000
		C = 33 + l * .002 -- Subtitute C for constant on return line above
--]=]
	for i = -50, 50 do
		for j = -50, 50 do
			for k = -50, 50 do
				local f = S(i + .5, j + .4, k + .1)
				fmin = mmin(fmin, f)
				fmax = mmax(fmax, f)
			end
		end
	end
--[=[
		if fmin < fmin2 and fmin >= -1 then
			Cmin = C
		else
			fmin = fmin2
		end

		if fmax > fmax2 and fmax <= 1 then
			Cmax = C
		else
			fmax = fmax2
		end
	end
	printf("Simplex3D: min = %f, max = %f, Cmin = %f, Cmax = %f", fmin, fmax, Cmin, Cmax)
--]=]
-- v.off()
	printf("Simplex3D: time / call = %.9f, min = %f, max = %f", (os.clock() - t1) / (101 * 101 * 101), fmin, fmax)
--]]

--[[
	-- Timing test, 4D case
	local S = M.Simplex4D
	local mmin, mmax = math.min, math.max
	local fmin, fmax = 10000, -10000
	local v = require("jit.dump")
	local t1 = os.clock()
-- v.start("tisH", "SOME_DIRECTORY/Simplex4D.html")
--[=[
	for m = 1, 500 do
		local fmin2, fmax2 = fmin, fmax
		fmin, fmax = 10000, -10000
		C = 40 + m * .006 -- Subtitute C for constant on return line above
--]=]
	for i = -25, 25 do
		for j = -25, 25 do
			for k = -25, 25 do
				for l = -25, 25 do
					local f = S(i + .5, j + .4, k + .1, l + .7)
					fmin = mmin(fmin, f)
					fmax = mmax(fmax, f)
				end
			end
		end
	end
--[=[
		if fmin < fmin2 and fmin >= -1 then
			Cmin = C
		else
			fmin = fmin2
		end

		if fmax > fmax2 and fmax <= 1 then
			Cmax = C
		else
			fmax = fmax2
		end
	end
	printf("Simplex4D: min = %f, max = %f, Cmin = %f, Cmax = %f", fmin, fmax, Cmin, Cmax)
--]=]
-- v.off()
	printf("Simplex4D: time / call = %.9f, min = %f, max = %f", (os.clock() - t1) / (51 * 51 * 51 * 51), fmin, fmax)
--]]

-- For testing, uncomment this:
  -- printf("%.9f", os.clock() - t1) -- Total test time

--[=[
-- Customize as needed to dump values to a file, e.g. to compare against other implementations:
local F = io.open("SOME_DIRECTORY/LuaOut.txt", "w")
if F then
--[[
	for i = 1, 50 do
		for j = 1, 50 do
			local f = M.Simplex2D(i + .5, j + .3)
			F:write(string.format("(%i, %i): %f\n", i, j, f))
		end
	end
--]]
--[[
	for i = -1, -50, -1 do
		for j = -1, -50, -1 do
			for k = -1, -50, -1 do
				local f = M.Simplex3D(i + .5, j + .4, k + .1)
				F:write(string.format("(%i, %i, %i): %f\n", i, j, k, f))
			end
		end
	end
--]]
--[[
	for i = -1, -50, -1 do
		for j = -1, -50, -1 do
			for k = -1, -50, -1 do
				for l = -1, -50, -1 do
					local f = M.Simplex4D(i + .5, j + .4, k + .1, l + .7)
					F:write(string.format("(%i, %i, %i, %i): %f\n", i, j, k, l, f))
				end
			end
		end
	end
--]]
	F:close()
end
--]=]