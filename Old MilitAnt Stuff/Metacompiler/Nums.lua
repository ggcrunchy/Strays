--- Number-based environment variables for the metacompiler system.

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

-- Standard library imports --
local ceil = math.ceil
local floor = math.floor
local fmod = math.fmod
local format = string.format
local max = math.max
local min = math.min
local random = math.random

-- Modules --
local em = require("entity_manager")
local mc = require("metacompiler")
local numeric_ops = require("numeric_ops")
local objects_helpers = require("game_objects_helpers")
local var_preds = require("var_preds")

-- Shorthand for common read calls
local function ReadBase (_, bvar, interp)
	return objects_helpers.ReadElement(_, "BaseVar", bvar, interp)
end

local function ReadNum (_, nvar)
	return objects_helpers.ReadElement(_, "NumVar", nvar, true)
end

-- AssignNum_ActionComponent_cl reader --
objects_helpers.DefineReader("AssignNum_ActionComponent_cl", function(_, nvar)
	local family, name = ReadBase(_, nvar, false)

	return format("%s:SetNumber(%s, %s)", family, name, ReadNum(_, nvar))
end)

-- Mutate ops --
local Ops = { ['+'] = "Add", ['-'] = "Sub", ['*'] = "Mul", ['÷'] = "Div" }

-- ArithmeticMutateNum_ActionComponent_cl reader --
objects_helpers.DefineReader("ArithmeticMutateNum_ActionComponent_cl", function(_, bvar, nvar, op)
	local family, name = ReadBase(_, bvar, false)
	local num = ReadNum(_, nvar)

	if Ops[op] then
		return format("%s:%sNumber(%s, %s)", family, Ops[op], name, num)
	else
		if op == "Mod" then
			op = mc.Declare("math_fmod", fmod)
		elseif op == "Max" then
			op = mc.Declare("math_max", max)
		elseif op == "Min" then
			op = mc.Declare("math_min", min)
		end

		return format("%s:SetNumber(%s, %s(%s:GetNumber(%s), %s))", family, name, op, family, name, num)
	end
end)

-- SimpleMutateNum_ActionComponent_cl reader --
objects_helpers.DefineReader("SimpleMutateNum_ActionComponent_cl", function(_, bvar, op)
	local family, name = ReadBase(_, bvar, false)

	return format("%s:%sNumber(%s)", family, op == "Decrement" and "Dec" or "Inc", name)
end)

-- CompareNums_ConditionComponent_cl reader --
objects_helpers.DefineReader("CompareNums_ConditionComponent_cl", function(_, nvar1, nvar2, op)
	return format("%s %s %s", ReadNum(_, nvar1), op, ReadNum(_, nvar2))
end)

-- Interval containment ops --
local IntervalOps = {
	interval_cc = function(nvar, a, b) return a <= nvar and nvar <= b end,
	interval_oc = function(nvar, a, b) return a < nvar and nvar <= b end,
	interval_co = function(nvar, a, b) return a <= nvar and nvar < b end,
	interval_oo = function(nvar, a, b) return a < nvar and nvar < b end
}

-- IntervalContainsNum_ConditionComponent_cl reader --
objects_helpers.DefineReader("IntervalContainsNum_ConditionComponent_cl", function(_, nvar, left, right, open_on_left, open_on_right)
	local op = "interval_cc"

	if open_on_left and open_on_right then
		op = "interval_oo"
	elseif open_on_left then
		op = "interval_oc"
	elseif open_on_right then
		op = "interval_co"
	end

	return format("%s(%s, %s, %s)", mc.Declare(op, IntervalOps[op]), ReadNum(_, nvar), ReadNum(_, left), ReadNum(_, right))
end)

-- NumVar reader --
objects_helpers.DefineReader("NumVar", function(_, nvar, interp)
	local type, a, b = em.PushNumVar(nvar)

	-- Variable --
	if type == "Variable" then
		local family, name, global = ReadBase(_, nvar, interp)

		if family then
			return format("%s:GetNumber(%s)", family, name)
		else
			return objects_helpers.ReadElement(_, "Property", name, 0, global)
		end

	-- Constant --
	elseif type == "Constant" then
		return format(var_preds.IsInteger(a) and "%i" or "%f", a)

	-- Random integer / number --
	else
		a, b = numeric_ops.SwapIf(a > b, a, b)

		mc.Declare("math_random", random)

		if type == "RandomInteger" then
			return format("math_random(%i, %i)", ceil(a), floor(b))
		else
			return format("(%f + math_random() * %f)", a, b - a)
		end
	end
end)