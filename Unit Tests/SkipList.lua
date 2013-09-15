--- Testing skip lists.

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

---[=[
local sl = require("skip_list")

local bb = ffi.typeof[[
	struct {
		uint32_t comp;
		int serial;
	}
]]

ffi.metatype(bb, {
	__lt = function(a, b)
		return a.comp < b.comp
	end
})

local bb_inf = bb(-1, 0)

local slc = sl.NewType(bb_inf)
local a = slc(4)
local n = {}
local k = {}

for i = 1, 20 do
	local x = math.random(10, 98)
	local v = bb(x, 1)
	print("Inserting into A: {", v.comp, v.serial, "}")
	n[#n+1] = a:InsertValue(v)
	print("n = ", n[#n].n)
	if i > 0 and i % 5 == 0 then
		v.serial = math.random(2, 4)
		print("Insert another with serial", v.serial)
		k[#k+1] = #n
		n[#n+1] = a:InsertValue(v)
	end
end

local sld = sl.NewType(1 / 0, "double")
local b = sld(5)
local o = {}

o[1] = b:InsertValue(3.3)
o[2] = b:InsertValue(234343)
o[3] = b:InsertValue(90)

local function Print (list)
	print("")

	for n = list.n - 1, 0, -1 do
		local t = {}
		local s = {}
		local c = list
		local next = list:GetNextNodeAt(n)
		local good = true
local badi, oi
		while c ~= nil do
			c = c:GetNextNode()
			if c ~= nil then
				if n == 0 then
					t[#t + 1] = tostring(c.data.comp)
					s[#s + 1] = " " .. tostring(c.data.serial)
				elseif c.n <= n then
					t[#t + 1] = "->"
				else
					t[#t + 1] = "**"
					good = good and next == c
					if not badi and not good then
						badi=tostring(c.data.comp)
						oi=tostring(next.data.comp)
					end
					next = c:GetNextNodeAt(n)
				end
			else
				if not good then
					t[#t + 1] = "Broken! " .. badi .. " " .. oi
				else
					t[#t + 1] = "End"
				end
				print(table.concat(t, " "))
				print(table.concat(s, " "))
			end
		end
	end
end

print("A")
Print(a)

print("")
print("Finding...")

local v = bb()

v.comp = n[12].data.comp

print("12: ", n[12].data.comp)

local n12 = a:FindNode(v).data

print("12", n12.comp, n12.serial)

v.comp = n[17].data.comp

print("17: ", n[17].data.comp)

local n17 = a:FindNode(v).data

print("17", n17.comp, n12.serial)

v.comp = 32323

print("32323: ", nil)

local n32323 = a:FindNode(v)

print("32323", n32323)

print("")
print("Removing duplicates")

for i = #k, 1, -1 do
	local v = n[k[i]]
	print("")
	print("Removing: ", v.data.comp, v.data.serial)
	print("")
	a:RemoveNode(v)
	Print(a)
	table.remove(n, k[i])
end

print("")
print("Removing values")

for _ = 1, 3 do
	print("")
	local i = math.random(#n)
	print("Removing: ", n[i].data.comp, n[i].data.serial)
	print("")
	a:RemoveValue(n[i].data)
	Print(a)
	table.remove(n, i)
end

print("")
print("Insert or find values")

print("")
print("Adding new: ", 99, 6)

local nv = bb(99, 6)
a:InsertOrFindValue(nv)
Print(a)

print("")
print("Trying to add dup of #9: ", n[9].data.comp, n[9].data.serial)
local tdv = bb(n[9].data.comp, n[9].data.serial)
a:InsertOrFindValue(tdv)
Print(a)

print("")
print("Trying to add mod (to serial of 5) of #6: ", n[6].data.comp, n[6].data.serial)
local tmv = bb(n[6].data.comp, 5)
a:InsertOrFindValue(tmv)
Print(a)

print("")
print("B")

local bv = b
while true do
	bv = bv:GetNextNode()
	if bv ~= nil then
		print("Bv", bv.data, bv.n)
	else
		break
	end
end

print("")
--]=]