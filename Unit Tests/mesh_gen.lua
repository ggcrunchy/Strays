--- Testing mesh gen module.

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

local mesh_gen = require("s3_utils.mesh_gen")
local COLS,ROWS=9,20--15,30--50,20
local uvs, verts, indices = --mesh_utils.NewLattice(COLS,ROWS, 300, 150)
--[[
mesh_gen.NewQuadrantRing{
	inner_radius = 30, outer_radius = 200,
	ncurve = COLS, nradius = ROWS,
	kind = "upper_left"
}
--]]
--[[
mesh_gen.NewNub{
	kind = "bottom", ncurve = COLS + 1, nradius = ROWS, --[=[inner_radius = 30, ]=]outer_radius = 200
}
--]]
--[[
mesh_gen.NewQuadrantArc{
	kind = "lower_left", ncurve = COLS + 1, nradius = ROWS, radius = 30, width = 90, height = 90
}
--]]
--[[
mesh_gen.NewTJunction{
	kind = "left", ncurve = COLS + 1, nradius = ROWS, radius = 30, width = 90, height = 180
}
--]]
---[[
mesh_gen.NewCross{
	ncurve = COLS + 1, nradius = ROWS, radius = 30, width = 180, height = 180
}
--]]

local mesh = display.newMesh{
	mode = "indexed", indices = indices, uvs = uvs, vertices = verts
}

mesh:translate(display.contentCenterX, display.contentCenterY)

local cx = mesh.x
local cbounds = mesh.contentBounds
local xc = cbounds.xMin
local xl, xr = xc - mesh.height / 2, xc + mesh.height / 2

local dv = .5 / COLS

local n = (#uvs / 2) / (COLS + 1)

--mesh.isVisible = false