--- Metal-ish WIP (since superseded).

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

local effect = { category = "filter", name = "uv" }

if true then
	local includer = require("solar2d_utils.includer")
	local iq = require("s3_utils.snippets.noise.iq")
	local texels = require("s3_utils.snippets.operations.texels")
	local unit_exclusive = require("s3_utils.snippets.operations.unit_inclusive")

	effect.vertexData = {
		unit_exclusive.VertexDatum("center", 0, 0, 0),
		{ name = "col", index = 1, default = 0 },
		{ name = "row", index = 2, default = 0 },
		{ name = "dim", index = 3 }
	}

	includer.AugmentKernels({
		requires = { iq.IQ1, iq.FBM4, texels.SEAMLESS_COMBINE, unit_exclusive.UNIT_PAIR },
		varyings = { ldir_xy = "vec2" },

		vertex = [[

		P_POSITION vec2 VertexKernel (P_POSITION vec2 pos)
		{
	//		ldir_xy = (CoronaVertexUserData.yz + WHEN_LT(UnitPair(CoronaVertexUserData.x), CoronaTexCoord.xy)) * CoronaVertexUserData.w;
	ldir_xy = 2. * (CoronaTexCoord - UnitPair(CoronaVertexUserData.x));
			return pos;
		}
	]],

		fragment = [[
		#ifdef GL_OES_standard_derivatives
			#extension GL_OES_standard_derivatives : enable
		#endif

		#define FBM(uv) FBM4((uv) * vec2(27.4, 23.2))
		#define AMBIENT vec3(.07)
		#define DIFFUSE .1
		#define SPEC_EXPONENT 30.
		#define SURFACE vec3(.875, .9, .875)
		#define LIGHT_COLOR vec3(1.)
		#define REFLECTION .2

		P_UV float Env (P_UV vec3 ldir, P_UV vec3 n)
		{
			return IQ(reflect(ldir, n).xy);
		}

		P_UV vec2 GetHeightDeltas (P_UV vec2 uv)
		{
			P_UV float fbm0 = FBM(uv);

		#ifdef GL_OES_standard_derivatives
			P_UV vec2 duv_dx = dFdx(uv), duv_dy = dFdy(uv);
		#else
			P_UV vec2 duv_dx = vec2(CoronaTexelSize.x, 0.), duv_dy = vec2(0., CoronaTexelSize.y);
		#endif

			P_UV float fbmx = FBM(uv + duv_dx);
			P_UV float fbmy = FBM(uv + duv_dy);

			return vec2(fbmx - fbm0, fbmy - fbm0);
		}

		P_UV vec2 Lit (P_UV float nl, P_UV float nh, P_UV float spec)
		{
			P_UV float k = max(nl, 0.);

			return vec2(k, spec * max(nh, 0.) * sign(k));
		}

		P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
		{
	//    uv = fract(2. * uv);
			P_UV vec4 coords = PrepareSeamlessCombine(uv);
			P_UV vec2 d = SEAMLESS_EVALUATE_AND_COMBINE(GetHeightDeltas, uv, coords);
			P_UV vec3 n = cross(vec3(CoronaTexelSize.x, 0., d.x), vec3(0., CoronaTexelSize.y, d.y));

			n = normalize(n);

			P_UV vec3 ldir = vec3(ldir_xy, 0.);

			ldir.z = sqrt(max(1. - dot(ldir, ldir), 0.));
			
			ldir = normalize(ldir);

			P_UV vec3 vn = vec3(0., 0., -1.);
			P_UV vec3 hn = normalize(vn + ldir);
			P_UV vec2 lv = Lit(dot(ldir, n), dot(hn, n), SPEC_EXPONENT);
			P_COLOR vec3 c = SURFACE * (AMBIENT + lv.x * DIFFUSE * LIGHT_COLOR + (lv.y * LIGHT_COLOR + REFLECTION * Env(ldir, n)));

			return vec4(clamp(c, 0., 1.), 1.);
		}
	]]

	}, effect)
else
	effect.fragment = [[
		P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
		{
			return vec4(uv, 0., 1.);
		}
	]]
end

graphics.defineEffect(effect)

mesh.fill.effect = "filter.custom.uv"