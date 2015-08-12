--- Tests for encoding and decoding 20-bit numbers in GLSL ES's highp floating point.

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

local function Decode (xy)
	local axy = math.abs(xy)

	-- Select the 2^16-wide floating point range. The first element in this range is 1 *
	-- 2^bin, while the ulp will be 2^bin / 2^16 or, equivalently, 2^(bin - 16). Then the
	-- index of axy is found by dividing its offset into the range by the ulp.
	local bin = math.floor(math.log(axy) / math.log(2))
	local num = (axy - 2^(bin)) * 2^(16. - bin)

	-- The lower 10 bits of the offset make up the y-value. The upper 6 bits, along with
	-- the bin index, are used to compute the x-value. The bin index can exceed 15, so x
	-- can assume the value 1024 without incident. It seems at first that y cannot, since
	-- 10 bits fall just short. If the original input was signed, however, this is taken
	-- to mean "y = 1024". Rather than conditionally setting it directly, though, 1023 is
	-- found in the standard way and then incremented.
	local rest = math.floor(num / 1024.)
	local y = num - rest * 1024.
	local y_bias = 1. - (xy < 0 and 0 or 1) -- step(0., xy)

	return bin * 64. + rest, y + y_bias
end

--
local function Pack (x, y)
	local signed

	if y == 1024 then
		y, signed = 1023, true
	end

	local xhi = math.floor(x / 64)
	local xlo = x - xhi * 64
	local xy = (1 + (xlo * 1024 + y) * 2^-16) * 2^xhi

	return signed and -xy or xy
end
--[[
for x = 0, 1024 do
	for y = 0, 1024 do
		local pack = Pack(x, y)
		local ux, uy = Decode(pack)
		if ux ~= x or uy ~= uy then
			print("Problem at: ", x, y)
		end
	end
end
print("DONE!")
]]
do
	-- Kernel --
	local kernel = { category = "generator", name = "raw" }

	kernel.vertexData = {
		{
			name = "r",
			default = 0, min = 0, max = 1024,
			index = 0
		},
		{
			name = "g",
			default = 0, min = 0, max = 1024,
			index = 1
		}
	}

	kernel.fragment = [[
		P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
		{
			return vec4(CoronaVertexUserData.xy / 1024., 0., 1.);
		}
	]]

	graphics.defineEffect(kernel)
end

do
	-- Kernel --
	local kernel = { category = "generator", name = "unpack" }

	kernel.vertexData = {
		{
			name = "packed",
			default = 0, min = -(1024 * 1024 - 1), max = 1024 * 1024 - 1,
			index = 0
		}
	}

	kernel.fragment = [[
		P_UV vec2 Unpack (P_DEFAULT float xy)
		{
			P_DEFAULT float axy = abs(xy);

			// Select the 2^16-wide floating point range. The first element in this range is 1 *
			// 2^bin, while the ulp will be 2^bin / 2^16 or, equivalently, 2^(bin - 16). Then the
			// index of axy is found by dividing its offset into the range by the ulp.
			P_DEFAULT float bin = floor(log2(axy));
			P_DEFAULT float num = (axy - exp2(bin)) * exp2(16. - bin);

			// The lower 10 bits of the offset make up the y-value. The upper 6 bits, along with
			// the bin index, are used to compute the x-value. The bin index can exceed 15, so x
			// can assume the value 1024 without incident. It seems at first that y cannot, since
			// 10 bits fall just short. If the original input was signed, however, this is taken
			// to mean "y = 1024". Rather than conditionally setting it directly, though, 1023 is
			// found in the standard way and then incremented.
			P_DEFAULT float rest = floor(num / 1024.);
			P_DEFAULT float y = num - rest * 1024.;
			P_DEFAULT float y_bias = 1. - step(0., xy);

			return vec2(bin * 64. + rest, y + y_bias);
		}

		P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
		{
			return vec4(Unpack(CoronaVertexUserData.x) / 1024., 0., 1.);
		}
	]]

	graphics.defineEffect(kernel)
end

local rect = display.newRect(display.contentCenterX, display.contentCenterY, 500, 200)

local list = {
	{ 0, 0 },
	{ 80, 300 },
	{ 0, 1024 },
	{ 100, 1024 },
	{ 400, 700 },
	{ 500, 500 },
	{ 1024, 0 },
	{ 1024, 1024 },
}

for i = 1, #list * 3 do
	local ii = (i - 1) / 3
	local which = (i - 1) % 3
	local j = math.floor(ii) + 1
	local r, g = list[j][1], list[j][2]

	timer.performWithDelay((i - 1) * 3000, function()
		if which == 0 then
			print("Using", r, g)
			print("Effect: raw")
			rect.fill.effect = "generator.custom.raw"
			rect.fill.effect.r, rect.fill.effect.g = r, g
		elseif which == 1 then
			print("Effect: none")
			rect.fill.effect = nil
		else
			print("Effect: packed")
			rect.fill.effect = "generator.custom.unpack"
			rect.fill.effect.packed = Pack(r, g)
			print("")
		end
	end)
end


--[=[

	P_DEFAULT vec2 UnitPair (P_DEFAULT float xy)
	{
		P_UV float axy = abs(xy);
		P_UV float frac = fract(axy);

		return vec2((axy - frac) / 1023., sign(xy) * frac + .5);
	}


--- Encodes two numbers &isin; [0, 1] into a **mediump**-range float for retrieval in GLSL.
-- @number x Number #1...
-- @number y ...and #2.
-- @treturn number Encoded pair.
function M.Encode (x, y)
	y = y - .5

	return (y < 0 and -1 or 1) * (floor(1023 * x) + abs(y))
end

--- Decodes a **mediump**-range float, assumed to be encoded as per @{Encode}.
-- @number pair Encoded pair.
-- @treturn number Number #1...
-- @treturn number ...and #2.
function M.Decode (pair)
	local apair = abs(pair)
	local xpart = floor(apair)

	return xpart / 1023, (pair < 0 and -1 or 1) * (apair - xpart) + .5
end

--- Prepares a unit pair-style parameter for addition to a kernel.
--
-- This parameter should be assigned values encoded as per @{Encode}.
-- @string name Friendly name of shader parameter.
-- @uint index Vertex userdata component index.
-- @number defx Default number #1, cf. @{Encode}...
-- @number defy ...and number #2.
-- @treturn table Vertex userdata component.
function M.VertexDatum (name, index, defx, defy)
	return {
		name = name,
		default = _Encode_(defx, defy),
		min = -1023.5, max = 1023.5,
		index = index
	}
end
]=]
