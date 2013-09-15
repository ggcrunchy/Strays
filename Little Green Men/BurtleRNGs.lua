--- Some tests of RNG's from Bob Jenkins.

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

-- http://burtleburtle.net/bob/rand/smallprng.html
-- 32-bit version with "third rotate to improve avalanche"

local RanCtx = ffi.typeof[[
	struct { int32_t a, b, c, d; }
]]

local bxor = bit.bxor
local rot = bit.rol

local function RanVal (x)
	local e = x.a - rot(x.b, 23)

	x.a = bxor(x.b, rot(x.c, 176))
	x.b = x.c + rot(x.d, 11)
	x.c = x.d + e
	x.d = e + x.a

	return x.d
end

local function RanInit (x, seed)
	x.a, x.b, x.c, x.d = 0xf1ea5eed, seed, seed, seed

	for _ = 1, 20 do
		RanVal(x)
	end
end

-- Test
local aa = RanCtx()

RanInit(aa, 0xFD13903F)

for _ = 1, 100 do
	print(("%x"):format(RanVal(aa)))
end

--[[
	http://burtleburtle.net/bob/rand/isaac.html

	/*
	 * & is bitwise AND, ^ is bitwise XOR, a<<b shifts a by b
	 * ind(mm,x) is bits 2..9 of x, or (floor(x/4) mod 256)*4
	 * in rngstep barrel(a) was replaced with a^(a<<13) or such
	 */
	typedef  unsigned int  u4;      /* unsigned four bytes, 32 bits */
	typedef  unsigned char u1;      /* unsigned one  byte,  8  bits */
	#define ind(mm,x)  (*(u4 *)((u1 *)(mm) + ((x) & (255<<2))))
	#define rngstep(mix,a,b,mm,m,m2,r,x) \
	{ \
	  x = *m;  \
	  a = (a^(mix)) + *(m2++); \
	  *(m++) = y = ind(mm,x) + a + b; \
	  *(r++) = b = ind(mm,y>>8) + x; \
	}
	  
	static void isaac(mm,rr,aa,bb,cc)
	u4 *mm;      /* Memory: array of SIZE ALPHA-bit terms */
	u4 *rr;      /* Results: the sequence, same size as m */
	u4 *aa;      /* Accumulator: a single value */
	u4 *bb;      /* the previous result */
	u4 *cc;      /* Counter: one ALPHA-bit value */
	{
	  register u4 a,b,x,y,*m,*m2,*r,*mend;
	  m=mm; r=rr;
	  a = *aa; b = *bb + (++*cc);
	  for (m = mm, mend = m2 = m+128; m<mend; )
	  {
		rngstep( a<<13, a, b, mm, m, m2, r, x);
		rngstep( a>>6 , a, b, mm, m, m2, r, x);
		rngstep( a<<2 , a, b, mm, m, m2, r, x);
		rngstep( a>>16, a, b, mm, m, m2, r, x);
	  }
	  for (m2 = mm; m2<mend; )
	  {
		rngstep( a<<13, a, b, mm, m, m2, r, x);
		rngstep( a>>6 , a, b, mm, m, m2, r, x);
		rngstep( a<<2 , a, b, mm, m, m2, r, x);
		rngstep( a>>16, a, b, mm, m, m2, r, x);
	  }
	  *bb = b; *aa = a;
	}
]]