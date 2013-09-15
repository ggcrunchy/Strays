--- Lua-side scroll barrier logic as it interacts with the metacompiler.

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

-- Modules --
local mc = require("metacompiler")
local objects_helpers = require("game_objects_helpers")
local screen_effects = require("screen_effects")

-- Setup the scroll barrier type.
local Props = objects_helpers.SetupType("scroll_barriers", {
	epilogue_builder = function(_, name)
		-- Inject a warning when the wave begins.
		if name == "OnLock" then
			mc.Declare("HereComesAWave", screen_effects.HereComesAWave)

			return "HereComesAWave(object)"

		-- Inject a go signal when the wave ends.
		elseif name == "OnUnlock" then
			mc.Declare("GoGoGo", screen_effects.GoGoGo)

			return "GoGoGo(object)"
		end
	end
})