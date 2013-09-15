--- Alert-based environment variables for the metacompiler system.

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
local format = string.format
local tostring = tostring

-- Modules --
local em = require("entity_manager")
local mc = require("metacompiler")
local objects_helpers = require("game_objects_helpers")

-- 
local function GlobalAlert (alert, payload)
	-- TODO: Logic!!
end

--
local function ReadAlert (_, avar, var)
	local alert, type, global, pstring = em.PushAlertVar(avar)
	local extra = ""

	-- String payload --
	if pstring then
		extra = format(", %q", pstring)

	-- Boolean payload --
	elseif type ~= "None" then
		extra = format(", %s", tostring(type == "True"))
	end

	--
	if global then
		mc.Declare("global_receiver", em.GetGlobalReceiver)

		var = "global_receiver()"
	end

	mc.Declare("em_alert", em.Alert)

	return format("em_alert(%s, %q%s)", var or "object", alert, extra)
end

-- Alert_ActionComponent_cl reader --
objects_helpers.DefineReader("Alert_ActionComponent_cl", ReadAlert)

-- Alert_ConditionComponent_cl reader --
objects_helpers.DefineReader("Alert_ConditionComponent_cl", function(_, avar, negate, var)
	return (negate and "not " or "") .. ReadAlert(_, avar, var)
end)