--- The erstwhile "table view" patterns, abandoned on account of bugginess.

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
local ipairs = ipairs
local remove = table.remove

-- Modules --
local embedded_free_list = require("tektite_core.array.embedded_free_list")
local file_utils = require("corona_utils.file")
local layout_dsl = require("corona_ui.utils.layout_dsl")

-- Corona globals --
local display = display
local native = native
local timer = timer

-- Corona modules --
local widget = require("widget")

-- Cached module references --
local _Listbox_

-- Exports --
local M = {}

-- --
local RowAdder = {
	isCategory = false,
	lineHeight = 16,
	lineColor = { .45 },
	rowColor = { default = { 1 }, over = { 0, 0, 1, .75 } }
}

--
local function GetText (index, stash)
	return stash and stash[index]
end

--
local function Highlight (row)
	row.alpha = .5
end

--
local function GetListbox (row)
	return row.parent.parent
end

---
local function TouchEvent (func, listbox, index, str)
	if func then
		func{ listbox = listbox, index = index, str = str or "" }
	end
end

-- Each of the arguments is a function that takes _event_.**index** as argument, where
-- _event_ is the parameter of **onEvent** or **onRender**.
-- @callable press Optional, called when a listbox row is pressed.
-- @callable release Optional, called when a listbox row is released.
-- @callable get_text Returns a row's text string.
-- @treturn table Argument to `tableView:insertRow`.

--
local function AddToStash (L, stash, str, free)
	RowAdder.id, free = embedded_free_list.GetInsertIndex(stash, free)

	stash[RowAdder.id] = str

	L:insertRow(RowAdder)

	return free
end

--- Creates a listbox, built on top of `widget.newTableView`.
-- @pgroup group Group to which listbox will be inserted.
-- @ptable options bool hide If true, the listbox starts out hidden.
-- @treturn DisplayObject Listbox object.
-- TODO: Update, reincorporate former Adder docs...
function M.Listbox (group, options)
	local lopts, x, y = layout_dsl.ProcessWidgetParams(options, { width = 300, height = 150 })

	-- On Render --
	local get_text, selection, stash, free = GetText

	if options and options.get_text then
		local getter = options.get_text

		function get_text (index, stash)
			local item = GetText(index, stash)

			return getter(item) or item
		end
	end

	function lopts.onRowRender (event)
		local row = event.row
		local text, index = display.newText(row, "", 0, 0, native.systemFont, 20), row.id--index
print("onRowRender INDEX", index, GetListbox(row):getNumRows())
		local str = get_text(index, stash)

		text:setFillColor(0)

		text.text = str or ""
		text.anchorX, text.x = 0, 15
		text.y = row.height / 2

		if str == selection then
			Highlight(row)
		end
	end

	-- On Touch --
	local press, release, old_row = options and options.press, options and options.release

	function lopts.onRowTouch (event)
		local row = event.target
		local index, listbox = row.index, GetListbox(row)
print("onRowTouch INDEX", index, listbox:getNumRows(), row.index)
		local phase, str = event.phase, get_text(row.id--[[index]], stash)

		-- Listbox item pressed...
		if phase == "press" then
			--
			selection = str

			TouchEvent(press, listbox, index, str)

			-- Show row at full opacity, while held.
			event.row.alpha = 1

		-- ...and released.
		elseif phase == "release" then
			TouchEvent(release, listbox, index, str)

			-- Unmark the previously selected row (if any), and mark the new row.
			if old_row then
				old_row.alpha = 1
			end

			Highlight(event.row)

			old_row = event.row
		end

		return true
	end

	--
	local Listbox = widget.newTableView(lopts)

	layout_dsl.PutObjectAt(Listbox, x, y)

	group:insert(Listbox)

	--- DOCME
	function Listbox:Append (str)
		stash = stash or {}

	--	stash[#stash + 1] = str

--		self:insertRow(RowAdder)
		free = AddToStash(self, stash, str, free)
	end

	--- DOCME
	function Listbox:AppendList (list)
		stash = stash or {}

		for i = 1, #list do
		--	RowAdder.id, free = embedded_free_list.GetInsertIndex()

		--	stash[RowAdder.id--[[#stash + 1]] ] = list[i]

		--	self:insertRow(RowAdder)
			free = AddToStash(self, stash, list[i], free)
		end
	end

	--- DOCME
	function Listbox:AssignList (list)
		self:Clear()
		self:AppendList(list)
	end

	--- DOCME
	function Listbox:Clear ()
		selection, stash, free = nil

		self:deleteAllRows()
	end

	--- DOCME
	function Listbox:ClearSelection ()
		selection = nil
	end

	--- DOCME
	function Listbox:Delete (index)
		if stash then
			local id = self:getRowAtIndex(index).id

			if get_text(id--[[index]], stash) == selection then
				selection = nil
			end

		--	remove(stash, index)
			free = embedded_free_list.RemoveAt(stash, id--[[index]], free)
		end
print("DE", index)
		self:deleteRow(index)
	end

	--- DOCME
	function Listbox:Find (str)
	--	for i = 1, #(str and stash or "") do
		for i = 1, str and self:getNumRows() or 0 do
			local row = self:getRowAtIndex(i)

			if row and get_text(row.id--[[i]], stash) == str then
				return i
			end
		end

		return nil
	end

	--- DOCME
	function Listbox:GetSelection ()
		return selection
	end

	--
	Listbox.isVisible = not (options and options.hide)

	return Listbox
end

-- Cache module references.
_Listbox_ = M.Listbox

-- Export the module.
return M