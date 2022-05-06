--- TODO

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
local controls = require("s3_utils.controls")
local movement = require("s3_utils.movement")
local pathing = require("s3_utils.pathing")
local path_utils = require("s3_utils.path_utils")
local scrolling = require("s3_utils.scrolling")
local tile_flags = require("s3_utils.tile_flags")
local tile_layout = require("s3_utils.tile_layout")
local tile_path = require("s3_utils.tile_path")

-- Solar2D globals --
local display = display
local Runtime = Runtime

--
--
--

local PathOpts = {}

-- Current segment used to build a path, if any --
local Cur

-- The goal position of any path in progress --
local Goal

-- Graphics used to mark a path destination --
local X1, X2

function PathOpts.CancelPath (object)
	display.remove(X1)
	display.remove(X2)

	tile_path.Reset(object)
	controls.SetDirectionSource(nil)

	Cur, Goal, X1, X2 = nil
end

function PathOpts.GoalPos ()
	if Goal then
		return Goal.x, Goal.y, Goal.tile
	else
		return nil
	end
end

function PathOpts.IsFollowingPath ()
	return Goal ~= nil
end

local function CurrentDirection ()
	return path_utils.CurrentDir(Cur)
end

function PathOpts.UpdateOnMove (dir, tile)
	Cur = path_utils.Advance(Cur, "facing", dir)

	Goal.tile = tile

	return CurrentDirection()
end

--
--
--

local Player, Target

Runtime:addEventListener("became_subject", function(event)
	Player = event.subject
	Target = event.target or Player

	tile_path.SetPathingOpts(Target, PathOpts)
end)

--
--
--

local function Cancel ()
	PathOpts.CancelPath(Target)
end

Runtime:addEventListener("disable_input", Cancel)

--
--
--

Runtime:addEventListener("movement_began", Cancel)

--
--
--

local MarkersLayer

Runtime:addEventListener("leave_level", function()
  MarkersLayer, Player, Target = nil

	-- n.b. other logic triggers "disable_input"
end)

--
--
--

local function AddPathState (player, paths, flags, tile, ptile, x, y)
	local px, py = tile_layout.GetPosition(tile)

	if movement.CanGo(flags, x < px and "left" or "right") then
		px = x
	end

	if movement.CanGo(flags, y < py and "up" or "down") then
		py = y
	end

	Cur = path_utils.ChooseBranch_Facing(paths, player:GetFacing())
	Goal = { x = px, y = py, tile = ptile }

	-- X marks the spot!
	X1 = display.newLine(MarkersLayer, x - 15, y - 15, x + 15, y + 15)
	X2 = display.newLine(MarkersLayer, x - 15, y + 15, x + 15, y - 15)

	X1:setStrokeColor(1, 0, 0)
	X2:setStrokeColor(1, 0, 0)

	X1.strokeWidth = 4
	X2.strokeWidth = 8
end

Runtime:addEventListener("tapped_at", function(event)
	local ref = scrolling.GetNextTarget(nil)
	local x, y = scrolling.GetScreenPosition(ref, event.x, event.y)

	-- If we tapped on a tile, plan a path to it.
	local prev = tile_flags.UseGroup(Player:GetBlock())

x, y = Player:Coordinate_GetComponents(x, y)
-- TODO: ^^ fishy, inconsistent :/
-- not quite, and have to get tile (and ptile, below) as well

	local tile = tile_layout.GetIndex_XY(x, y)
	local flags = tile_flags.GetFlags(tile)

	if flags ~= 0 then
		PathOpts.CancelPath(Target)

		local ptile = tile_layout.GetIndex_XY(Target.x, Target.y)
		local paths = pathing.FindPath(ptile, tile)

		if paths then
			AddPathState(Player, paths, flags, tile, ptile, x, y)

      Runtime:dispatchEvent{ name = "began_path" }

			controls.Clear()
			controls.SetDirectionSource(CurrentDirection)
		end
	end

	tile_flags.UseGroup(prev)
end)

--
--
--

Runtime:addEventListener("things_loaded", function(level)
  MarkersLayer = level.params:GetLayer("things")

	local w, h = tile_layout.GetSizes()

  if w < h then
    PathOpts.NearGoal = w / 3
  else
    PathOpts.NearGoal = h / 3
  end
end)