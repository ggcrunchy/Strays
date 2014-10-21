--- Joystick UI elements.

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
local abs = math.abs

-- Modules --
local colors = require("ui.Color")
local numeric_ops = require("numeric_ops")
local player = require("game.Player")
local skins = require("ui.Skin")
local touch = require("ui.Touch")

-- Coronal globals --
local display = display

-- Imports --
local ClampIn = numeric_ops.ClampIn
local GetColor = colors.GetColor
local GetSkin = skins.GetSkin
local newCircle = display.newCircle
local newGroup = display.newGroup
local MovePlayer = player.MovePlayer


-- Exports --
local M = {}

--
local function Stick (stick, axis, dstick)
	local delta = ClampIn(dstick, -1, 1)

	--
	if abs(delta) < stick.m_dead_zone then
		return 0, nil

	--
	else
		local restart

		if axis then
			restart = axis * delta < 0
		else
			restart = abs(delta) > 0
		end

		--
		if restart then
			axis = delta > 0 and stick.m_threshold or -stick.m_threshold
		end

		return delta, axis
	end
end

--
local function UpdateStick (event, stick)
	local sx, sy = stick.parent:localToContent(0, 0)

	stick.m_dx, stick.m_xaxis = Stick(stick, stick.m_xaxis, 2 * (event.x - sx) / stick.contentWidth)
	stick.m_dy, stick.m_yaxis = Stick(stick, stick.m_yaxis, 2 * (event.y - sy) / stick.contentHeight)
end

--
local function ResetStick (stick)
	stick.m_dx, stick.m_xaxis = 0
	stick.m_dy, stick.m_yaxis = 0
end

--
local OnTouch = touch.TouchHelperFunc(UpdateStick, UpdateStick, function(_, stick)
	ResetStick(stick)
end)

--
local function PollAxis (stick, axis, delta, dt)
	local change = false

	if axis then
		axis = axis + delta * dt

		if abs(axis) > stick.m_threshold then
			change = axis < 0 and "-" or "+"
			axis = 0
		end
	end

	return change, axis
end

--- Creates a new joystick.
-- @pgroup group Group to which joystick will be inserted.
-- @param skin Name of joystick's skin.
-- @number x Position in _group_.
-- @number y Position in _group_.
-- @number radius Outer radius.
-- @treturn DisplayGroup Child #1: the outer circle; Child #2: the inner circle.
-- @see ui.Skin.GetSkin
function M.Joystick (group, skin, x, y, radius)
	skin = GetSkin(skin)

	-- Build a new group and add it into the parent at the requested position. The circles
	-- will be relative to this group.
	local jgroup = newGroup()

	jgroup.x, jgroup.y = x, y

	group:insert(jgroup)

	-- Add the outer and inner circle, in that order, to the group.
	local outer = newCircle(jgroup, 0, 0, radius)
	local inner = newCircle(jgroup, 0, 0, radius * skin.joystick_innerratio)

	inner.strokeWidth = skin.joystick_innerwidth
	outer.strokeWidth = skin.joystick_outerwidth

	inner:setFillColor(GetColor(skin.joystick_innerfillcolor))
	inner:setStrokeColor(GetColor(skin.joystick_innerstrokecolor))
	outer:setFillColor(GetColor(skin.joystick_outerfillcolor))
	outer:setStrokeColor(GetColor(skin.joystick_outerstrokecolor))

	-- Install common joystick logic.
	inner:addEventListener("touch", OnTouch)

	-- Assign custom joystick state.
	inner.m_dead_zone = skin.joystick_deadzone
	inner.m_threshold = skin.joystick_threshold

	ResetStick(inner)

	---
	-- @return
	-- @return
	function jgroup:GetAxes ()
		return inner.m_dx, inner.m_dy
	end

	---
	-- @number dt
	-- @return
	-- @return
	-- @return
	-- @return
	function jgroup:Poll (dt)
		local dx, xaxis = PollAxis(inner, inner.m_xaxis, inner.m_dx, dt)
		local dy, yaxis = PollAxis(inner, inner.m_yaxis, inner.m_dy, dt)

		inner.m_xaxis, inner.m_yaxis = xaxis, yaxis

		return dx, dy, xaxis, yaxis
	end

	-- Provide the joystick.
	return jgroup
end

-- Main joystick skin --
skins.AddToDefaultSkin("joystick", {
	innerratio = 8 / 11,
	innerwidth = 5,
	innerfillcolor = { .25, .25, .25, .75 },
	innerstrokecolor = "black",
	outerwidth = 0,
	outerfillcolor = { 0, 0, 1, .5 },
	outerstrokecolor = "black",
	deadzone = .25,
	threshold = .205
})

-- Export the module.
return M