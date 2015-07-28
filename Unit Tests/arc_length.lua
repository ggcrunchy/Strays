--- Some arc length tests.

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

local ss=require("tektite_core.number.sampling")
local lut={}
ss.Init(lut)
ss.AddSample(lut, -1, 3)
ss.AddSample(lut, 2, 5)
ss.AddSample(lut, 2.5, 3)
ss.AddSample(lut, 4, -2)
ss.AddSample(lut, 5, 5)
vdump(lut)
ss.UpdateSample(lut, 3, 2.7, 3.1)
vdump(lut)

print("")

local res = {}

for _, x in ipairs{ -15, -1, 0, 2.3, 2.5, 2.7, 2.9, 4.9, 5, 6 } do
	print("LOOKING UP (normal)", x)
	ss.Lookup(lut, res, x)
	vdump(res)
	print("")
end

for _, x in ipairs{ -.3, 0, .1, .2, .6, .9, 1, 1.2 } do
	print("LOOKING UP (0-1)", x)
	ss.Lookup_01(lut, res, x)
	vdump(res)
	print("")
end