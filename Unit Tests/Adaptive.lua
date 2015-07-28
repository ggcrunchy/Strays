--- Tests for adaptive tables.

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

local adaptive = require("tektite_core.table.adaptive")

do -- empty set
	local set

	print("ITER EMPTY SET")
	
	vdump(set)

	for k, v in adaptive.IterSet(set) do
		print("IES", k, v)
	end

	set = adaptive.AddToSet(set, nil)
	
	vdump(set)
	print("")
end

do -- empty array
	local arr

	print("ITER EMPTY ARRAY")
	
	vdump(arr)

	for i, v in adaptive.IterArray(arr) do
		print("IEA", i, v)
	end

	arr = adaptive.Append(arr, nil)
	
	vdump(arr)
	print("")
end

do -- one-element set
	local set

	set = adaptive.AddToSet(set, "one elem")

	for k, v in adaptive.IterSet(set) do
		print("Iter 1-Elem. Set", k, v)
	end
	
	vdump(set)

	print("REMOVE?")

	set = adaptive.RemoveFromSet(set, 338)

	vdump(set)

	print("REMOVE")

	set = adaptive.RemoveFromSet(set, "one elem")

	vdump(set)
	print("")
end

do -- one-element array
	local arr

	arr = adaptive.Append(arr, "DOG")

	for i, v in adaptive.IterArray(arr) do
		print("Iter 1-Elem. Array", i, v)
	end

	vdump(arr)

	print("REMOVE?")

	arr = adaptive.RemoveFromArray(arr, 338)

	vdump(arr)

	print("REMOVE")

	arr = adaptive.RemoveFromArray(arr, "DOG")

	vdump(arr)
	print("")
end

do -- one (table)-element set
	local tv, set = {}

	set = adaptive.AddToSet(set, tv)

	for k, v in adaptive.IterSet(set) do
		print("Iter 1 Table-Elem. Set", k, v)
	end
	
	vdump(set)

	print("REMOVE?")

	set = adaptive.RemoveFromSet(set, 338)

	vdump(set)

	print("REMOVE")

	set = adaptive.RemoveFromSet(set, tv)

	vdump(set)
	print("")
end

do -- one (table)-element array
	local tv, arr = {}

	arr = adaptive.Append(arr, tv)

	for i, v in adaptive.IterArray(arr) do
		print("Iter 1 Table-Elem. Array", i, v)
	end

	vdump(arr)

	print("REMOVE?")

	arr = adaptive.RemoveFromArray(arr, 338)

	vdump(arr)

	print("REMOVE")

	arr = adaptive.RemoveFromArray(arr, tv)

	vdump(arr)
	print("")
end

do -- set: table, then other
	local set

	set = adaptive.AddToSet(set, {})
	set = adaptive.AddToSet(set, "one elem")

	for k, v in adaptive.IterSet(set) do
		print("Iter 2-Elem. Set (table, then other)", k, v)
	end
	
	vdump(set)
	print("")
end

do -- array: table, then other
	local arr

	arr = adaptive.Append(arr, {})
	arr = adaptive.Append(arr, "DOG")

	for i, v in adaptive.IterArray(arr) do
		print("Iter 2-Elem. Array (table, then other)", i, v)
	end

	vdump(arr)
	print("")
end

do -- set: other, then table
	local set

	set = adaptive.AddToSet(set, "one elem")
	set = adaptive.AddToSet(set, {})

	for k, v in adaptive.IterSet(set) do
		print("Iter 2-Elem. Set (other, then table)", k, v)
	end
	
	vdump(set)
	print("")
end

do -- array: other, then table
	local arr

	arr = adaptive.Append(arr, "DOG")
	arr = adaptive.Append(arr, {})

	for i, v in adaptive.IterArray(arr) do
		print("Iter 2-Elem. Array (other, then table)", i, v)
	end

	vdump(arr)
	print("")
end

local a1 = { "dog", "cat", {} }
local a2 = { "cat" }
local a3 = { nil }
local a4 = { { "mirmal" } }

local s1 = { dog = true, cat = true, [{}] = true }
local s2 = { cat = true }
local s3 = { }
local s4 = { [{ "mirmal" }] = true }

local a = { a1, a2, a3, a4 }
local s = { s1, s2, s3, s4 }

-- Test 1 --
--[[
local Func
local function P (a)
	print("BEFORE")
	vdump(a)
	print("AFTER")
	vdump(Func(a))
	print("")
end
Func = adaptive.SimplifyArray
P(a1)
P(a2)
P(a3)
P(a4)
Func = adaptive.SimplifySet
P(s1)
P(s2)
P(s3)
P(s4)
--]]

-- Test 2 --
--[[
for k, v in pairs(a) do
	print("MEMBER ARRAY", k)
	vdump(v)
	adaptive.SimplifyArray_Member(a, k)
	print("")
end

vdump(a)
print("")

for k, v in pairs(s) do
	print("MEMBER SET", k)
	vdump(v)
	adaptive.SimplifySet_Member(s, k)
	print("")
end

vdump(s)
print("")
--]]