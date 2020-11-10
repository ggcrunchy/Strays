--- Testing interval module.

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

local interval = require("tektite_core.array.interval")
local Sequence = require("tektite_base_classes.Container.Sequence")

-- index = M.IndexAfterInsert (index, new_start, new_count, new_size, add_spot)
-- index = M.IndexAfterRemove (index, new_start, new_count, new_size, add_spot, can_migrate)
-- index, count = M.IntervalAfterInsert (old_start, old_count, new_start, new_count)
-- index, count = M.IntervalAfterRemove (old_start, old_count, new_start, new_count)

local function P (func, message, a, b, ...)
	local ok, A, B = pcall(func, a, b, ...)

	if not ok then
		print(message, "Failure!")
		return a, b
	elseif B then
		print(message, A, B)
		return A, B
	else
		print(message, A)
		return A
	end
end

local function IDXI (...)
	return P(interval.IndexAfterInsert, "Index after insert: ", ...)
end

local function IDXR (...)
	return P(interval.IndexAfterRemove, "Index after remove: ", ...)
end

local function INTI (...)
	return P(interval.IntervalAfterInsert, "Interval after insert: ", ...)
end

local function INTR (...)
	return P(interval.IntervalAfterRemove, "Interval after remove: ", ...)
end

-- Null index, insert
IDXI(0, 2, 0, 2) -- empty interval
IDXI(0, 1, 8, 12) -- valid interval

-- Null index, remove
IDXR(0, 2, 0, 2) -- empty interval
IDXR(0, 1, 8, 12) -- valid interval

-- Null interval, insert
INTI(0, 0, 0, 2) -- empty interval
INTI(0, 0, 8, 12) -- valid interval
INTI(2, 0, 0, 2) -- empty interval, invalid start
INTI(4, 0, 8, 12) -- valid interval, invalid start

-- Null interval, remove
INTR(0, 0, 0, 2) -- empty interval
INTR(0, 0, 8, 12) -- valid interval
INTR(2, 0, 0, 2) -- empty interval, invalid start
INTR(4, 0, 8, 12) -- valid interval, invalid start

-- Valid index, insert
IDXI(3, 2, 0, 4) -- empty interval, within
IDXI(3, 2, 0, 2) -- empty interval, outside
IDXI(3, 2, 1, 7) -- insert before, within
IDXI(3, 2, 1, 4) -- insert before, at end
IDXI(1, 1, 2, 2) -- insert at end, empty, not add spot
IDXI(1, 1, 2, 2, true) -- insert at end, empty, add spot

-- Valid index, remove

-- Valid interval, insert

-- Valid interval, remove