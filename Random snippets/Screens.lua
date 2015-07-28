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
-- Standard library imports --
local assert = assert
local pairs = pairs
local setmetatable = setmetatable

-- Modules --
local array_ops = require("array_ops")
local cache_ops = require("cache_ops")
local class = require("class")
local flow_ops = require("flow_ops")
local func_ops = require("func_ops")
local iterators = require("iterators")
local var_ops = require("var_ops")
local var_preds = require("var_preds")

-- Classes --
require("class.SectionGroup")
require("class.TaskQueue")

-- Imports --
local CallOrGet = func_ops.CallOrGet
local CollectArgsInto = var_ops.CollectArgsInto
local Filter = array_ops.Filter
local IsCallable = var_preds.IsCallable
local newGroup = display.newGroup
local NoOp = func_ops.NoOp
local WaitUntil = flow_ops.WaitUntil

-- Cached routines --
local _CleanupEventQueues_
local _GetEventQueue_

-- Exports --
local M = {}

-- Section group --
local SG = class.New("SectionGroup")

-- Event queues --
local Queues = {}

for _, when in iterators.Args("enter_trap", "enter_update", "between_frames") do
	Queues[when] = class.New("TaskQueue")
end

do
	-- Cleanup argument --
	local Arg

	-- Cleanup descriptor --
	local How

	-- Default function for unmarked tasks --
	local DefFunc

	-- Task marks --
	local Marks = setmetatable({}, {
		__index = function()
			return DefFunc
		end,
		__mode = "k"
	})

	-- Queue cleanup helper
	local function Cleanup (task)
		return Marks[task](task, How, Arg)
	end

	-- Cleans up event queues before major switches
	-- how: Event cleanup descriptor
	-- all_groups: If true, cleanup queues in all section groups
	-- def_func: Optional function to call on unmarked tasks
	-- omit: Optional queue to ignore during cleanup
	-- arg: Cleanup argument
	function M.CleanupEventQueues (how, all_groups, def_func, omit, arg)
		assert(def_func == nil or IsCallable(def_func), "Invalid default function")

		Arg = arg
		How = how
		DefFunc = def_func ~= nil and def_func or NoOp

		for name, queue in pairs(Queues) do
			if name ~= omit then
				if #queue > 0 then
					local tasks = queue:Gather(true)

					Filter(tasks, Cleanup)

					queue:Clear()
					queue:Add_Array(tasks)
				end
			end
		end
	end

	-- Marks a task with a function to call on cleanup
	-- task: Task to mark
	-- cleanup: Cleanup function
	function M.MarkTask (task, cleanup)
		assert(IsCallable(task), "Uncallable task")
		assert(IsCallable(cleanup), "Uncallable cleanup function")

		Marks[task] = cleanup
	end
end

-- Cache for close / open arguments --
local ArgsCache = cache_ops.TableCache("unpack_and_wipe")

-- Unpack helper
local function Unpack (args, count)
	return ArgsCache(args, count, false)
end

--
local function AddToQueue (func)
	_GetEventQueue_("between_frames"):Add(func)
end

--
local function WrapBuilder (func)
	return function(name, no_delay, extra_arg, ...)
		local count, args = CollectArgsInto(ArgsCache("pull"), ...)

		local function Wrapper ()
			func(name, count, args, extra_arg)
		end

		if no_delay then
			return Wrapper
		else
			return function()
				AddToQueue(Wrapper)
			end
		end
	end
end

-- Helper to close a section
local CloseSection = WrapBuilder(function(name, count, args)
	SG:Close(CallOrGet(name), Unpack(args, count))
end)

-- Shorthand for CloseSection
local function CS (name, no_delay, ...)
	return CloseSection(name, no_delay, nil, ...)
end

--- Closes a section.
-- @param name Section name.
-- @param ... Arguments to section close.
function M.Close (name, ...)
	AddToQueue(CS(name, true, ...))
end

-- Builds a section close routine
-- name: Section name
-- ...: Arguments to section close
-- Returns: Closure to close section
function M.Closer (name, ...)
	return CS(name, false, ...)
end

--- DOCMAYBE
function M.Close_Direct (name, ...)
	return CS(name, true, ...)
end

-- Gets a section group's event queue
-- event: Event name
-- Returns: Queue handle
function M.GetEventQueue (event)
	return assert(Queues[event], "Invalid event queue")
end

---
-- @return Global section group.
function M.GetSectionGroup ()
	return SG
end

-- Loads a section, handling common functionality
-- name: Section name
-- proc: Section procedure
-- ...: Load arguments
function M.Load (name, proc, lookup, ...)
	local data = {}

	-- Wrap the procedure in a routine that handles common logic. Load the section.
	SG:Load(name, function(state, ...)
		local queue

		-- On("close") --
		if state == "close" then
			data.group:removeSelf()

			data.group = nil

			-- Sift out section-specific messages.
			_CleanupEventQueues_("close_section", false, nil, "between_frames", name)

		-- On("open") --
		elseif state == "open" then
			data.group = newGroup()
			
		-- On("trap") --
		elseif state == "trap" then
			queue = Queues.enter_trap

		-- On("update")
		elseif state == "update" then
			queue = Queues.enter_update
		end

		-- Do section-specific logic.
		if queue then
			queue(data)
		end

		return proc(state, data, ...)
	end, ...)
end

-- Helper to open a section
local OpenSection = WrapBuilder(function(name, count, args, clear_sections)
	local from = SG:Current()
	local to = CallOrGet(name)

	if from then
		SG:Send(from, "message:going_to", to)
	end

	if clear_sections then
		SG:Clear()
	end

	SG:Send(to, "message:coming_from", from)
	SG:Open(to, Unpack(args, count))
end)

-- Shorthand for OpenSection, dialog version
local function OSD (name, no_delay, ...)
	return OpenSection(name, no_delay, false, ...)
end

-- Opens a section dialog and waits for it to close
-- name: Section name
-- ...: Arguments to section enter
function M.OpenAndWait (name, ...)
	local is_done

	AddToQueue(OSD(name, true, function()
		is_done = true
	end, ...))

    WaitUntil(function()
        return is_done
    end)
end

-- Opens a section dialog
-- name: Section name
-- ...: Arguments to section enter
function M.Dialog (name, ...)
	AddToQueue(OSD(name, true, ...))
end

-- Builds a section dialog open routine
-- name: Section name
-- ...: Arguments to section enter
-- Returns: Closure to open dialog
function M.DialogOpener (name, ...)
	return OSD(name, false, ...)
end

-- 
function M.Dialog_Direct (name, ...)
	return OSD(name, true, ...)
end

-- Shorthand for OpenSection, screen version
local function OSS (name, no_delay, ...)
	return OpenSection(name, no_delay, true, ...)
end

-- Opens a single-layer section; closes other sections
-- name: Section name
-- ...: Arguments to section enter
function M.Screen (name, ...)
	AddToQueue(OSS(name, true, ...))
end

-- Builds a section screen open routine
-- name: Section name
-- ...: Arguments to section enter
-- Returns: Closure to open screen
function M.ScreenOpener (name, ...)
	return OSS(name, false, ...)
end

-- 
function M.Screen_Direct (name, ...)
	return OSS(name, true, ...)
end

-- Cache some routines.
_CleanupEventQueues_ = M.CleanupEventQueues
_GetEventQueue_ = M.GetEventQueue

-- Export the module.
return M