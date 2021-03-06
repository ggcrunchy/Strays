--- Helper for scene transitions.

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
local random = math.random

-- Corona modules --
local composer = require("composer")

-- Cached module references --
local _GoToScene_
local _Send_
local _SetListenFunc_

-- Exports --
local M = {}

--
--
--

-- Arguments to composer.gotoScene --
local Args = {}

--- Utility that augments `composer.gotoScene`.
-- @ptable args Arguments to forward to `composer.gotoScene`.
--
-- The **name** field contains the scene name.
--
-- If the **effect** key is **"none"**, no transition effect is played. Otherwise, the array
-- part of _args_ may be populated with transition names, in which case one is randomly
-- chosen as the effect. If neither of those is the case, the **effect** key is used.
--
-- The **params** and **time** keys are the same as for `composer.gotoScene`.
function M.GoToScene (args)
	Args.params = args.params

	if #args > 0 then
		Args.effect = args[random(#args)]
	elseif args.effect ~= "none" then
		Args.effect = args.effect
	end

	if args.effect ~= "none" then
		Args.time = args.time
	end

	composer.gotoScene(args.name, Args)

	Args.effect, Args.params, Args.time = nil
end

--- DOCME
function M.HideOverlay (...)
	_Send_("message:hide_overlay")

	composer.hideOverlay(...)
end

--- Factory.
-- @ptable args Arguments to @{GoToScene}.
-- @treturn function When called, will open the scene as per the arguments.
function M.Opener (args)
	return function()
		_GoToScene_(args)
	end
end

-- Current routine which listens (and responds) to messages sent to the scene --
local ListenFunc

--- Sends a message to the scene, which may send a response. If no listener has been
-- installed, this is a no-op.
-- @param what Message to send.
-- @param ... Message payload.
-- @return Results returned by scene listener.
-- @see SetListenFunc
function M.Send (what, ...)
	if ListenFunc then
		return ListenFunc(what, ...)
	end
end

--- Setter.
-- @tparam ?|callable|nil func Scene listener to install, or **nil** to clear the listener.
-- @treturn ?callable Previous scene listener, or **nil** if absent.
function M.SetListenFunc (func)
	local cur = ListenFunc

	ListenFunc = func

	return cur
end

do
	local Name, Effect

	local function GoBack (what)
		if what == "message:wants_to_go_back" then
			composer.gotoScene(Name, Effect)
		end
	end

	--- Variant of @{SetListenFunc} for the common case of only handling "go back to the
	-- previous scene" behavior.
	-- @string name Name of return scene; if absent, uses `composer.getSceneName("previous")`.
	-- @string[opt="fade"] effect Effect to play on going back, or **"none"** to go immediately.
	-- @treturn ?callable Previous scene listener, or **nil** if absent.
	function M.SetListenFunc_GoBack (name, effect)
		Name = name or composer.getSceneName("previous")

		if effect == "none" then
			Effect = nil
		else
			Effect = effect or "fade"
		end

		return _SetListenFunc_(GoBack)
	end
end

--- Convenience function, e.g. for callbacks: will @{Send} **"message:wants\_to\_go\_back"**
-- to the current scene listener.
function M.WantsToGoBack ()
	_Send_("message:wants_to_go_back")
end

_GoToScene_ = M.GoToScene
_Send_ = M.Send
_SetListenFunc_ = M.SetListenFunc

return M