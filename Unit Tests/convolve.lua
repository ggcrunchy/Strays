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

local circular_convolution = require("signal_ops.circular_convolution")
local fft_convolution = require("signal_ops.fft_convolution")
local linear_convolution = require("signal_ops.linear_convolution")
local fft = require("fft_ops.fft")
local real_fft = require("fft_ops.real_fft")

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

	print("")
end

do
	print("1D convolutions")
	print("")
	print("Linear")
	local A, B = {1,2,1}, {1,2,3}
	local t1 = linear_convolution.Convolve_1D(A, B)
	vdump(t1)
	print("")

	print("Circular")
	vdump(circular_convolution.Convolve_1D(A, B))
	print("")

	local Precomp = {}

	fft_convolution.PrecomputeKernel_1D(Precomp, #A, B)

	CompareMethods(1, t1,
		"Goertzels", fft_convolution.Convolve_1D(A, B, { method = "goertzel" }),
		"Precomputed Kernel", fft_convolution.Convolve_1D(A, Precomp, { method = "precomputed_kernel" }),
		"Separate FFT's", fft_convolution.Convolve_1D(A, B, { method = "separate" }),
		"Two FFT's", fft_convolution.Convolve_1D(A, B)
	)
end

do
	print("2D convoltuions")
	print("")

	-- Referring to:
	-- http://www.songho.ca/dsp/convolution/convolution2d_example.html
	-- http://www.johnloomis.org/ece563/notes/filter/conv/convolution.html
	vdump(linear_convolution.Convolve_2D({1,2,3,4,5,6,7,8,9}, {-1,-2,-1,0,0,0,1,2,1}, 3, 3, "same"))
	print("")

	local A, B, AW, BW = {17,24,1,8,15,
						23,5,7,14,16,
						4,6,13,20,22,
						10,12,19,21,3,
						11,18,25,2,9 }, {1,3,1,0,5,0,2,1,2}, 5, 3
	local t1 = linear_convolution.Convolve_2D(A, B, AW, BW) -- "full"

	-- From a paper...
	vdump(circular_convolution.Convolve_2D({1,0,2,1}, {1,0,1,1}, 2,2))
	-- Contrast to http://www.mathworks.com/matlabcentral/answers/100887-how-do-i-apply-a-2d-circular-convolution-without-zero-padding-in-matlab
	-- but that seems to use a different padding strategy...
	print("")

	local Precomp = {}

	fft_convolution.PrecomputeKernel_2D(Precomp, #A, B, AW, BW)

	CompareMethods(2, t1,
		"Goertzels", fft_convolution.Convolve_2D(A, B, AW, BW, { method = "goertzel" }),
		"Precomputed Kernel", fft_convolution.Convolve_2D(A, Precomp, AW, BW, { method = "precomputed_kernel" }),
		"Separate FFT's", fft_convolution.Convolve_2D(A, B, AW, BW, { method = "separate" }),
		"Two FFT's", fft_convolution.Convolve_2D(A, B, AW, BW)
	)
end

do
	for _, v in ipairs{
		{1,1,1,1,0,0,0,0}, {1,3,1,1,0,0,7,0}, {2,1,1,2,9,3,4,6}
	} do
		local stock, real, n, ok = {}, {}, #v, true

		for _, r in ipairs(v) do
			stock[#stock + 1] = r
			stock[#stock + 1] = 0
			real[#real + 1] = r
		end

		print("COMPARING STOCK AND REAL (1D) FFT's")

		fft.FFT_1D(stock, n)
		real_fft.RealFFT_1D(real, n)

		for i = 1, 2 * n do
			if math.abs(stock[i] - real[i]) > 1e-9 then
				print("Problem at: " .. i)

				ok = false
			end
		end

		if ok then
			print("All good!")
			print("")
			print("COMPARING STOCK AND REAL (1D) IFFT's (recovering original data)")

			fft.IFFT_1D(stock, n)
			real_fft.RealIFFT_1D(real, n / 2)
		
			for i = 1, n do
				local j = 2 * i - 1

				if math.abs(stock[j] - v[i]) > 1e-9 then
					print("Problem with stock IFFT (real component) at: " .. i)

					ok = false
				end

				if math.abs(stock[j + 1]) > 1e-9 then
					print("Problem with stock IFFT (imaginary component) at: " .. i)

					ok = false
				end

				if math.abs(real[i] - v[i]) > 1e-9 then
					print("Problem with real IFFT at: " .. i)

					ok = false
				end
			end

			if ok then
				print("All good!")
			end
		end

		print("")
	end
end

do
	local stock = { 1, 0, 2, 0, 3, 0, 7, 0,
					2, 0, 3, 0, 1, 0, 8, 0,
					3, 0, 1, 0, 2, 0, 6, 0,
					6, 0, 7, 0, 8, 0, 2, 0 }
	local W, H = 4, 4
	local real, ss, ok = {}, {}, true

	for i = 1, #stock, 2 do
		real[#real + 1] = stock[i]
		ss[#ss + 1] = stock[i]
	end

	print("COMPARING STOCK AND REAL (2D) FFT's")

	fft.FFT_2D(stock, W, H)
	real_fft.RealFFT_2D(real, W, H)

	for i = 1, 2 * W * H do
		if math.abs(stock[i] - real[i]) > 1e-9 then
			print("Problem at: " .. i)

			ok = false
		end
	end

	if ok then
		print("All good!")
		print("")
		print("COMPARING STOCK AND REAL (2D) IFFT's (recovering original data)")

		fft.IFFT_2D(stock, W, H)
		real_fft.RealIFFT_2D(real, W / 2, H)
	
		for i = 1, W * H do
			local j = 2 * i - 1

			if math.abs(stock[j] - ss[i]) > 1e-9 then
				print("Problem with stock IFFT (real component) at: " .. i)

				ok = false
			end

			if math.abs(stock[j + 1]) > 1e-9 then
				print("Problem with stock IFFT (imaginary component) at: " .. i)

				ok = false
			end

			if math.abs(real[i] - ss[i]) > 1e-9 then
				print("Problem with real IFFT at: " .. i)

				ok = false
			end
		end

		if ok then
			print("All good!")
		end
	end
end

--[=[
	Overlap tests, could stand refinement

local cc = require("signal_ops.circular_convolution")
local fc = require("signal_ops.fft_convolution")
local lc = require("signal_ops.linear_convolution")
local circular_convolution = require("signal_ops.circular_convolution")
local fft_convolution = require("signal_ops.fft_convolution")
local linear_convolution = require("signal_ops.linear_convolution")

local fft = require("dft_ops.fft")
local real_fft = require("dft_ops.real_fft")


	do
		local S = {}
		local K = {}

		for i = 1, 50 do
			S[i] = math.random(2, 9)
		end

		for i = 1, 4 do
			K[i] = math.random(1, 7)
		end

		print("Convolution")
		local conv = fft_convolution.Convolve_1D(S, K)
		vdump(conv)
		local conv2 = fft_convolution.OverlapSave_1D(S, K)
		print("C2")
		vdump(conv2)
		local conv3 = fft_convolution.OverlapAdd_1D(S, K)
		print("C3")
		vdump(conv3)
		for i = 1, math.min(#conv, #conv2, #conv3) do
			if math.abs(conv[i] - conv2[i]) > 1e-9 then
				print("PROBLEM AT: ", i)
				break
			end
			if math.abs(conv[i] - conv3[i]) > 1e-9 then
				print("PROBLEM AT: ", i)
				break
			end
		end
		print("SAME", #conv == #conv2 and #conv == #conv3)

		local S2, K2 = {3,0,-2,0,2,1,0,-2,-1,0}, {2,2,1}
		vdump(fft_convolution.Convolve_1D(S2, K2))
		vdump(fft_convolution.OverlapSave_1D(S2, K2))
		vdump(fft_convolution.OverlapAdd_1D(S2, K2))

		local cconv = circular_convolution.Convolve_1D(S2, K2)

		vdump(cconv)

		local cconv2 = fft_convolution.OverlapAdd_1D(S2, K2, { is_circular = true })

		vdump(cconv2)
	end
--]=]

--[==[
	Analysis of using singular value decomposition and then summed separable convolutions
	to perform convolution

---[=[
	local svd = require("linear_algebra_ops.svd")
	local fftc = require("signal_ops.fft_convolution")
	local mat = {}
	local mm, nn, ii = 25, 25, 1
	for i = 1, nn do
		for j = 1, mm do
			mat[ii], ii = 1--[[math.random(22)]], ii + 1
		end
	end
	local s, u, v = svd.SVD_Square(mat, mm)--svd.SVD(mat, mm, nn)
s,u = u,s
if mm == 4 then
	vdump(s)
	vdump(u)
	vdump(v)
end

--[=[
	local dim, num = 25, 25
local tt0=os.clock()
	for NUM = 1, num do
		local sum = {}
	--	print("MATRIX", NUM)
		for j = 1, dim^2 do
			mat[j] = math.random(256)
			sum[j] = 0
		end
		local u, _, v = svd.SVD_Square(mat, dim)
		local n = #u
		for rank = 1, dim do
			local fnorm, j = 0, 1
			for ci = rank, n, dim do
				local cval = u[ci]

				for ri = rank, n, dim do
					sum[j] = sum[j] + cval * v[ri]
					fnorm, j = fnorm + (mat[j] - sum[j])^2, j + 1
				end
			end
		--	print("Approximation for rank " .. rank, fnorm)
		end
	--	print("")
	end
print("TTTT", (os.clock() - tt0) / num)
--]=]
--if true then return end
--]=]
	local oc=os.clock
	local abs,floor,random,sqrt=math.abs,math.floor,math.random,math.sqrt
	local overlap=require("signal_ops.overlap")
	local t1=oc()
	local A={}
	local B={}
	local M, N = 81, 25
	local ii,jj=random(256), random(256)
	for i = 1, M^2 do
		A[i]=ii
		ii=ii+random(16)-8
	end
	for i = 1, N^2 do
		B[i]=jj
		jj=jj+random(16)-8
	end
	local t2 = oc()
	local separable = require("signal_ops.separable")
	local kd = separable.DecomposeKernel(B, N)
	local fopts = { into = {} }
	local sopts = { into = {}, max_rank = math.ceil(N / 5 - 1) }
--[=[
	NN=N+20
	for i = 1, 20 do
	--	fftc.Convolve_2D(A, B, M, N, fopts)
		separable.Convolve_2D(A, M, kd, sopts)
	end
	local t3 = oc()
	print("VVV", t2 - t1, (t3 - t2) / 20, sopts.max_rank)
--]=]
	local o1 = fftc.Convolve_2D(A, B, M, N, fopts)
---[=[
	local rank = sopts.max_rank
	for i = 1, N do
		sopts.max_rank = i
		local t4=oc()
		local o2 = separable.Convolve_2D(A, M, kd, sopts)
		local sum, sum2 = 0, 0
		for j = 1, #o2 do
			local diff = abs(o2[j] - o1[j])
			sum, sum2 = sum + diff, sum2 + --[[floor]] (sqrt(diff))
		end
		print("APPROX", i, sum, sum / #o2, oc() - t4)
		print("SQRTAPX", sum2, sum2 / #o2)
	end
--]=]
--]==]

--[==[
	Was this anything? I guess I was trying all kinds of convolution techniques, e.g. via overlap and such...
	...flushed out some weird slownesses (with say the 2 height in Convolve_2D, which may need investigation)
	...also that seemed to be unstable, though maybe it was just misuse?
	...really, the dft/signal_ops submodules need better test batteries... although in the end I don't know if
	they're fast enough to bother improving?

	local t2=oc()
	local opts={into = {}}
	overlap.OverlapAdd_2D(A, B, M, N, opts)
	local t3=oc()
	--[[
	local tt=0
	for i = 1, 40 do
		overlap.OverlapAdd_2D(A, B, M, N, opts)
		local t4=oc()
		tt=tt+t4-t3
		t3=t4
	end
	print("T", t2-t1, t3-t2, tt / 41)
	]]
	local abs=math.abs
	local max=0
	local out = require("signal_ops.fft_convolution").Convolve_2D(A, B, M, N)
	print("N", #opts.into, #out)
	local into,n=opts.into,0
	for i = 1, #into do
		local d = abs(into[i]-out[i])
		if d > 1 then
			print(i, into[i], out[i])
			n=n+1
			if n == N then
				break
			end
		end
	end
	local t4=oc()
	local AA={}
	for i = 1, 2 * N do
		AA[i] = math.random(256)
	end
	local t5=oc()
--	require("signal_ops.fft_convolution").Convolve_2D(A, B, N, 2)
	local t6=oc()
	overlap.OverlapAdd_2D(A, B, 8, N)
	local t7=oc()
	print("OK", t3-t2,t4-t3,t5-t4,t6-t5,t7-t6)
]==]