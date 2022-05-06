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
local action = require("s3_utils.hud.action")
local controls = require("s3_utils.controls")
local device = require("solar2d_utils.device")
local move = require("s3_utils.hud.move")

-- Solar2D globals --
local display = display
local Runtime = Runtime
local system = system

-- Solar2D modules --
local composer = require("composer")

--
--
--

Runtime:addEventListener("level_done", function()
	device.MapAxesToKeyEvents(false)
	composer.getVariable("handle_key"):Pop()
end)

--
--
--

local ActionEvent = { name = "do_action" }

local DoActions = controls.WrapActiveAction(function()
	Runtime:dispatchEvent(ActionEvent)
end)

local SetDirection = controls.WrapActiveAction(controls.SetDirection)

-- Processes direction keys or similar input, by pretending to push GUI buttons
local function KeyEvent (event)
	local key = device.TranslateButton(event) or event.keyName

	-- Directional keys from D-pad or trackball: move in the corresponding direction.
	-- The trackball seems to produce the "down" phase followed immediately by "up",
	-- so we let the player coast along for a few frames unless interrupted.
	if key == "up" or key == "down" or key == "left" or key == "right" then
		SetDirection(key, event.phase == "up")

	-- Confirm key: attempt to perform player actions.
	elseif key == "space" then
		if event.phase == "down" then
			DoActions()
		end

	-- Propagate other / unknown keys; otherwise, indicate that we consumed the input.
	else
		return "call_next_handler"
	end

	return true
end

local Platform = system.getInfo("environment") == "device" and system.getInfo("platform")

local TappedAtEvent = { name = "tapped_at" }

-- Traps touches to the screen and interprets any taps
local AuxTrapTaps = controls.WrapActiveAction(function(event)
  local trap = event.target

  -- Began: Did another touch release recently, or is this the first in a while?
  if event.phase == "began" then
    local now = event.time

    if trap.m_last and now - trap.m_last < 550 then
      trap.m_tapped_when, trap.m_last = now
    else
      trap.m_last = now
    end

  -- Released: If this follows a second touch, was it within a certain interval?
  -- (Doesn't feel like a good fit for a tap if the press lingered for too long.)
  elseif event.phase == "ended" then
    if trap.m_tapped_when and event.time - trap.m_tapped_when < 300 then
      TappedAtEvent.x, TappedAtEvent.y = event.x, event.y

      Runtime:dispatchEvent(TappedAtEvent)
    end

    trap.m_tapped_when = nil
  end
end)

local function TrapTaps (event)
    AuxTrapTaps(event)

    return true
end

Runtime:addEventListener("things_loaded", function(level)
	local hud_group = level.params:GetGroup("hud")

	-- Add an invisible full-screen rect beneath the rest of the HUD to trap taps
	-- ("tap" events don't seem to play nice with the rest of the GUI).
	local trap = display.newRect(hud_group, 0, 0, display.contentWidth, display.contentHeight)

	trap:translate(display.contentCenterX, display.contentCenterY)
	trap:addEventListener("touch", TrapTaps)

	trap.isHitTestable, trap.isVisible = true, false

	-- Add input UI elements.
	action.AddActionButton(hud_group, DoActions)

	if Platform == "android" or Platform == "ios" then
		move.AddJoystick(hud_group)
	end

	-- Bind controller input.
	device.MapAxesToKeyEvents(true)

	-- Track events to maintain input.
	local handle_key = composer.getVariable("handle_key")

	handle_key:Clear() -- TODO: kludge because we don't go through title screen to wipe quick test
	handle_key:Push(KeyEvent)
end)

--
--
--

device.MapButtonsToAction("space", {
	Xbox360 = "A",
	MFiGamepad = "A",
	MFiExtendedGamepad = "A"
})