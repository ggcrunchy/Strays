--- Testing for dialog sections.

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

	-- Enumerate Properties --
	-- arg1: Dialog
	elseif what == "enum_props" then
--[[
local TEST = arg1:BeginSection()
--]]
		arg1:AddCheckbox{ text = "Add to shapes?", value_name = "add_to_shapes" }
--[[
arg1:EndSection()
timer.performWithDelay(250, function(e)
		if e.count % 2 == 1 then
			arg1:Collapse(TEST)
		else
			arg1:Expand(TEST)
		end
	end, 200)
--]]

local function CB (a)
	arg1:AddCheckbox{ text = a .. "?", value_name = a }
end
		arg1:AddCheckbox{ text = "Reappear after a while?", value_name = "reappear" }
local A = arg1:BeginSection()
CB"a"
CB"b"
CB"c"
arg1:EndSection()
CB"d"
local B = arg1:BeginSection()
CB"e"
CB"f"
arg1:EndSection()
CB"g"

--arg1:EndSection()
timer.performWithDelay(750, function(e)
	if arg1.parent then
		arg1:FlipTwoStates(A, B)
	end
	A, B = B, A
end, 0)