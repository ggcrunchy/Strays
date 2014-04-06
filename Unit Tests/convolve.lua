--- Convolution tests.

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

local convolve = require("number_ops.convolve")

local function CompareMethods (dim, t, ...)
	print("COMPARING " .. dim .. "D FFT-based convolve operations...")

	local comp, ok = { ... }, true

	for i = 1, #t do
		for j = 1, #comp, 2 do
			local name, other = comp[j], comp[j + 1]

			if math.abs(t[i] - other[i]) > 1e-6 then
				print(dim .. "D Problem (method = " .. name .. ") at: " .. i)

				ok = false
			end
		end
	end

	if ok then
		print("All good!")
	end
end

do
	print("Linear")
	local A, B = {1,2,1}, {1,2,3}
	local t1 = convolve.Convolve_1D(A, B)
	vdump(t1)
	print("Circular")
	vdump(convolve.CircularConvolve_1D(A, B))

	CompareMethods(1, t1,
		"Goertzels", convolve.ConvolveFFT_1D(A, B, { method = "goertzel" }),
		"Separate FFT's", convolve.ConvolveFFT_1D(A, B, { method = "separate" }),
		"Two FFT's", convolve.ConvolveFFT_1D(A, B)
	)
end

do
	-- Referring to:
	-- http://www.songho.ca/dsp/convolution/convolution2d_example.html
	-- http://www.johnloomis.org/ece563/notes/filter/conv/convolution.html
	vdump(convolve.Convolve_2D({1,2,3,4,5,6,7,8,9}, {-1,-2,-1,0,0,0,1,2,1}, 3, 3, "same"))

	local A, B, W, H = {17,24,1,8,15,
						23,5,7,14,16,
						4,6,13,20,22,
						10,12,19,21,3,
						11,18,25,2,9 }, {1,3,1,0,5,0,2,1,2}, 5, 3
	local t1 = convolve.Convolve_2D(A, B, W, H) -- "full"

	-- From a paper...
	vdump(convolve.CircularConvolve_2D({1,0,2,1}, {1,0,1,1}, 2,2))
	-- Contrast to http://www.mathworks.com/matlabcentral/answers/100887-how-do-i-apply-a-2d-circular-convolution-without-zero-padding-in-matlab
	-- but that seems to use a different padding strategy...

	CompareMethods(2, t1,
		"Goertzels", convolve.ConvolveFFT_2D(A, B, W, H, { method = "goertzel" }),
		"Separate FFT's", convolve.ConvolveFFT_2D(A, B, W, H, { method = "separate" }),
		"Two FFT's", convolve.ConvolveFFT_2D(A, B, W, H)
	)
end

do
	local fft=require("number_ops.fft")

	local function vdump2 (t)
		for i = 1, #t do
			if math.abs(t[i]) < 1e-9 then
				t[i] = 0
			end
		end

		vdump(t)
	end

	for _, v in ipairs{
		{1,1,1,1,0,0,0,0}, {1,3,1,1,0,0,7,0}, {2,1,1,2,9,3,4,6}
	} do
		local stock, n = {}, #v
		local half = n / 2

		for _, real in ipairs(v) do
			stock[#stock + 1] = real
			stock[#stock + 1] = 0
		end

		print("TABLE")
		vdump(v)
		print("")
		print("Stock FFT")
		fft.FFT_1D(stock, n)
		vdump2(stock)
		print("")
		print("Real FFT")
		fft.RealFFT_1D(v, n)
		vdump2(v)
		print("")
		print("Real IFFT")
		fft.RealIFFT_1D(v, half)
		for i = 1, n do
			v[i] = v[i] / half
		end
		vdump2(v)
		print("")
	end
end