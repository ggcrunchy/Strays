--- Test used for flood-fill operation.

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

local b = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)

b:setFillColor(.7)

do
	-- Kernel --
	local kernel = { category = "filter", name = "grid4x4" }

	kernel.vertexData = {
		-- These indicate which cells in the underlying 4x4 grid are active. The following
		-- diagram shows the correspondence between cell and bit index:
		--
		-- +----+----+----+----+
		-- |  0 |  1 |  2 |  3 |
		-- +----+----+----+----+
		-- |  4 |  5 |  6 |  7 |
		-- +----+----+----+----+
		-- |  8 |  9 | 10 | 11 |
		-- +----+----+----+----+
		-- | 12 | 13 | 14 | 15 |
		-- +----+----+----+----+
		{
			name = "bits",
			default = 0, min = 0, max = 65535,
			index = 0
		},

		-- These indicate which cells around the underlying 4x4 grid are active, for purposes
		-- of filtering. The following diagram shows cell / bit index correspondence:
		--
		--     |  0 |  1 |  2 |  3 |
		-- ----+----+----+----+----+----
		--   4 |    |    |    |    |  8
		-- ----+----+----+----+----+----
		--   5 |    |    |    |    |  9
		-- ----+----+----+----+----+----
		--   6 |    |    |    |    | 10
		-- ----+----+----+----+----+----
		--   7 |    |    |    |    | 11
		-- ----+----+----+----+----+----
		--     | 12 | 13 | 14 | 15 |
		{
			name = "neighbors",
			default = 0, min = 0, max = 65535,
			index = 1
		},

		-- Center x, for image sheets...
		{
			name = "x",
			default = 0, min = -65536, max = 65536,
			index = 2
		},

		-- ...and center y.
		{
			name = "y",
			default = 0, min = -65536, max = 65536,
			index = 3
		}
	}

	-- 
	kernel.vertex = [[
#define USE_NEIGHBORS
	#ifdef USE_NEIGHBORS
		varying P_UV float v_Top, v_Left, v_Right, v_Bottom;
	#endif

	#ifdef IMAGE_SHEET
		varying P_UV vec2 v_UV;
	#endif

	#if !defined(GL_FRAGMENT_PRECISION_HIGH) || defined(USE_NEIGHBORS)
		varying P_UV float v_Low, v_High;
	#endif

		P_POSITION vec2 VertexKernel (P_POSITION vec2 pos)
		{
		#if !defined(GL_FRAGMENT_PRECISION_HIGH) || defined(USE_NEIGHBORS)
			// In devices lacking high-precision fragment shaders, break the bit pattern
			// into two parts. For simplicity, do this when using neighbors as well.
			v_Low = mod(CoronaVertexUserData.x, 256.); // x = bits
			v_High = (CoronaVertexUserData.x - v_Low) / 256.;
		#endif

		#ifdef IMAGE_SHEET
			v_UV = step(CoronaVertexUserData.zw, pos); // zw = center
		#endif

		#ifdef USE_NEIGHBORS
			v_Top = mod(CoronaVertexUserData.y, 16.); // y = neighbors
			v_Left = mod(floor(CoronaVertexUserData.y * (1. / 16.)), 16.);
			v_Right = mod(floor(CoronaVertexUserData.y * (1. / 256.)), 16.);
			v_Bottom = floor(CoronaVertexUserData.y * (1. / 4096.));
		#endif

			return pos; // when no defines were provided, this is just a vertex pass-through
		}
	]]

	kernel.fragment = [[
#define USE_NEIGHBORS
	#ifdef USE_NEIGHBORS
		varying P_UV float v_Top, v_Left, v_Right, v_Bottom;
	#endif

	#ifdef IMAGE_SHEET
		varying P_UV vec2 v_UV;
	#endif
		
	#if !defined(GL_FRAGMENT_PRECISION_HIGH) || defined(USE_NEIGHBORS)
		varying P_UV float v_Low, v_High;
	#endif

	#ifdef USE_NEIGHBORS
		P_UV float AddFactor (P_UV float neighbor, P_UV vec2 pos, P_UV float offset, P_UV float which)
		{
			P_UV float cell = dot(floor(pos), vec2(1., 4.));
			P_UV float high = step(8., cell);
			P_UV float n = mix(offset, cell - high * 8., which), v = mix(neighbor, mix(v_Low, v_High, high), which);
			P_UV float power = exp2(n);

			return step(power, mod(v, 2. * power));
		}
	#endif

		P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
		{
			// Fit the position to a 4x4 grid and flatten that to an index in [0, 15].
		#ifdef IMAGE_SHEET
			P_UV vec2 scaled = floor(v_UV * 4.);
		#else
			P_UV vec2 scaled = floor(uv * 4.);
		#endif

			P_UV float cell = dot(scaled, vec2(1., 4.));

		#if defined(GL_FRAGMENT_PRECISION_HIGH) && !defined(USE_NEIGHBORS)
			// With high precision available, it is safe to go up to 2^16, thus all integer
			// patterns are already representable.
			P_DEFAULT float power = exp2(cell), value = CoronaVertexUserData.x;
		#else
			// Since medium precision only promises integers up to 2^10, the vertex kernel
			// will have broken the bit pattern apart as two 8-bit numbers. Choose the
			// appropriate half and power-of-2. This path is also used in the presence of
			// neighbors, since the vertex kernel is then necessary anyhow and AddFactor()
			// can be implemented without much hassle if `value` is known to be mediump.
			P_UV float high = step(8., cell);
			P_UV float power = exp2(cell - high * 8.), value = mix(v_Low, v_High, high);
		#endif

			// Scale the sample: by 1, if the bit was set, otherwise, by 0.
			P_UV float factor = step(power, mod(value, 2. * power));

		#ifdef USE_NEIGHBORS
			factor *= .5;

			factor += .125 * AddFactor(v_Top, scaled - vec2(0., 1.), scaled.x, step(0., scaled.y - 1.));
			factor += .125 * AddFactor(v_Left, scaled - vec2(1., 0.), scaled.y, step(0., scaled.x - 1.));
			factor += .125 * AddFactor(v_Right, scaled + vec2(1., 0.), scaled.y, step(scaled.x + 1., 3.));
			factor += .125 * AddFactor(v_Bottom, scaled + vec2(0., 1.), scaled.x, step(scaled.y + 1., 3.));
		#endif

			return CoronaColorScale(texture2D(CoronaSampler0, uv) * factor);
		}
	]]

	graphics.defineEffect(kernel)
end

timer.performWithDelay(100, coroutine.wrap(function(e)
	local CellCount, FrameUnitDim = 4, 4
	local SpriteDim = CellCount * FrameUnitDim

	--
	local cw, ch = display.contentWidth, display.contentHeight

	--
	local function GetRect (...)
		local cell = display.newRect(0, 0, SpriteDim, SpriteDim)

		cell.anchorX, cell.anchorY = 0, 0

		cell:setFillColor(...)

		cell.fill.effect = "filter.custom.grid4x4"

		return cell
	end

	local R, G, B = .2, .7, .3

	local cells = {}

	local nx, ny = math.ceil(cw / SpriteDim), math.ceil(ch / SpriteDim)
	local xmax, ymax = nx * CellCount, ny * CellCount
	local xx, yy = math.floor(xmax / 2), math.floor(ymax / 2)

	local function Index (x, y)
		return (y - 1) * xmax + x
	end

	local function Cell (index, n)
		local x = (index - 1) % n + 1
		local y = (index - x) / n + 1

		return x, y
	end

	setmetatable(cells, {
		__index = function(t, k)
			local rect = GetRect(R, G, B)
			local col, row = Cell(k, nx)

			rect.x, rect.y = (col - 1) * SpriteDim, (row - 1) * SpriteDim

			t[k] = rect

			return rect
		end
	})

	local s1, s2, used = {}, {}, {}
	local i1 = Index(xx, yy)

	s1[#s1 + 1], used[i1] = i1, true

	local Funcs = {
		-- Left --
		function(x, y, xoff, yoff)
			local delta, nbit_self, nbit_other

			if xoff == 0 then
				if x > 1 then
					delta, nbit_self, nbit_other = -1, 2^(4 + yoff), 2^(8 + yoff)
				else
					return
				end
			end

			return Index(x - 1, y), delta, nbit_self, nbit_other
		end,

		-- Right --
		function(x, y, xoff, yoff)
			local delta, nbit_self, nbit_other

			if xoff == 3 then
				if x < xmax then
					delta, nbit_self, nbit_other = 1, 2^(8 + yoff), 2^(4 + yoff)
				else
					return
				end
			end

			return Index(x + 1, y), delta, nbit_self, nbit_other
		end,

		-- Up --
		function(x, y, xoff, yoff)
			local delta, nbit_self, nbit_other

			if yoff == 0 then
				if y > 1 then
					delta, nbit_self, nbit_other = -nx, 2^xoff, 2^(12 + xoff)
				else
					return
				end
			end

			return Index(x, y - 1), delta, nbit_self, nbit_other
		end,

		-- Down --
		function(x, y, xoff, yoff)
			local delta, nbit_self, nbit_other

			if yoff == 3 then
				if y < ymax then
					delta, nbit_self, nbit_other = nx, 2^(12 + xoff), 2^xoff
				else
					return
				end
			end

			return Index(x, y + 1), delta, nbit_self, nbit_other
		end
	}

	--
	local floor, max, random, ipairs = math.floor, math.max, math.random, ipairs

	while true do
		local n, n2 = #s1, #s2

		for _ = 1, 35 do
			--
			local to_process = random(40, 50)

			if n < to_process then
				for _ = n2, max(1, n2 - to_process), -1 do
					local index = random(n2)

					n, s1[n + 1] = n + 1, s2[index]
					s2[index] = s2[n2]
					n2, s2[n2] = n2 - 1
				end
			end

			--
			for _ = n, max(1, n - to_process), -1 do
				local index = random(n)
				local x, y = Cell(s1[index], xmax)
				local xb, yb = floor((x - 1) * .25), floor((y - 1) * .25)
				local xoff, yoff = x - xb * 4 - 1, y - yb * 4 - 1
				local bit = 2^(yoff * 4 + xoff)
				local ci = yb * nx + xb + 1
				local ceffect = cells[ci].fill.effect

				--
				ceffect.bits = ceffect.bits + bit

				--
				for _, func in ipairs(Funcs) do
					local si, delta, nbit_self, nbit_other = func(x, y, xoff, yoff)

					if si then
						if delta then
							local neffect = cells[ci + delta].fill.effect
							local cn, nn = ceffect.neighbors, neffect.neighbors

							if cn % (2 * nbit_self) < nbit_self then
								ceffect.neighbors = cn + nbit_self
							end

							if nn % (2 * nbit_other) < nbit_other then
								neffect.neighbors = nn + nbit_other
							end
						end

						if not used[si] then
							s2[n2 + 1], used[si], n2 = si, true, n2 + 1
						end
					end
				end

				--
				s1[index] = s1[n]
				n, s1[n] = n - 1
			end
		end

		coroutine.yield()
	end
end), 0)