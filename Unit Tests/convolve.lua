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

print("Linear")
vdump(convolve.Convolve_1D({1,2,1},{1,2,3}))
print("Circular")
vdump(convolve.CircularConvolve_1D({1,2,1},{1,2,3}))
print("FFT")
vdump(convolve.Convolve_FFT1D({1,2,1},{1,2,3}))

-- Referring to:
-- http://www.songho.ca/dsp/convolution/convolution2d_example.html
-- http://www.johnloomis.org/ece563/notes/filter/conv/convolution.html
vdump(convolve.Convolve_2D({1,2,3,4,5,6,7,8,9}, {-1,-2,-1,0,0,0,1,2,1}, 3, 3, "same"))

local A, B, W, H =	17,24,1,8,15,
					23,5,7,14,16,
					4,6,13,20,22,
					10,12,19,21,3,
					11,18,25,2,9 }, {1,3,1,0,5,0,2,1,2}, 5, 3
local t1 = convolve.Convolve_2D(A, B, W, H)
vdump(t1)
-- From a paper...
vdump(M.CircularConvolve_2D({1,0,2,1}, {1,0,1,1}, 2,2))
-- Contrast to http://www.mathworks.com/matlabcentral/answers/100887-how-do-i-apply-a-2d-circular-convolution-without-zero-padding-in-matlab
-- but that seems to use a different padding strategy...

local t2 = M.Convolve_FFT2D(A, B, W, H, { method = "two_ffts" })
local t3 = M.Convolve_FFT2D(A, B, W, H, { method = "goertzel" })
local t4 = M.Convolve_FFT2D(A, B, W, H) -- separate fft's
				
print("COMPARING 2D convolve operations")
for i = 1, #t1 do
	if math.abs(t1[i] - t2[i]) > 1e-6 then
		print("Problem (method = Two FFT's) at: " .. i)
	end
	if math.abs(t3[i] - t2[i]) > 1e-6 then
		print("Problem (method = Goertzels) at: " .. i)
	end
	if math.abs(t3[i] - t2[i]) > 1e-6 then
		print("Problem (method = Separate FFT's) at: " .. i)
	end
end
print("DONE")