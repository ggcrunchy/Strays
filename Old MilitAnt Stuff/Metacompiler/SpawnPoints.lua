--- Lua-side spawn point logic as it interacts with the metacompiler.

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
local match = string.match

-- Modules --
local mc = require("metacompiler")
local objects_helpers = require("game_objects_helpers")

-- Spawn point variable substitutions --
local Subs = mc.NewVarInterpTable()

-- Setup the spawn point type.
local Props = objects_helpers.SetupType("spawn_points", {
	epilogue_builder = function(_, name)
		if name == "OnKill" then
			return "ZoneVars:IncNumber($(KILLER):kill_count)"
-- elseif name == "OnSpawn" and enemy:GetSpawnPoint():USE_POWER_BAR
-- "declare("power_bar", power_bar), Hook up to HUD"
		end
	end,
	subs = Subs
})

-- Body for 'KILLER' substitution
local function AuxKILLER (object)
	return ""
end

-- 'KILLER' variable: substitute identifier for enemy killer.
-- Valid when name is "OnKill".
function Subs.KILLER (name, var)
	if name == "OnKill" then
		mc.Declare("GetKiller", AuxKILLER)

		return "%s", "GetKiller(object)"
	end
end