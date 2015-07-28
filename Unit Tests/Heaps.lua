-- PAIRING HEAP TESTS:

local ph = require("pairing_heap")

local function AuxDump (node, indent)
	while node do
		print(indent, node.key)

		if node.child then
			AuxDump(node.child, indent .. "\t")
		end

		node = node.right
	end
end

local function Dump (H, what)
	print(what or "", " Dumping: ")
	print("")

	AuxDump(H.root, "")

	print("")
end

local H = ph.New()

local aaa = ph.Insert(H, 6) Dump(H, "insert 6")
local bbb = ph.Insert(H, 4) Dump(H, "insert 4")
local ccc = ph.Insert(H, 27) Dump(H, "insert 27")
ph.Insert(H, 8) Dump(H, "insert 8")
print("find min: ", ph.FindMin(H))
--ph.Delete(H, aaa) Dump(H, "delete (27)")
ph.DecreaseKey(H, bbb, 3) Dump(H, "decreased (4) -> (3)")
ph.Insert(H, 27) Dump(H, "insert 27")
ph.DecreaseKey(H, ccc, 24) Dump(H, "decreased (27) -> (24)")
ph.DecreaseKey(H, aaa, 2) Dump(H, "decreased (6) -> (2)")
ph.DeleteMin(H) Dump(H, "delete min")
print("find min: ", ph.FindMin(H))
ph.DeleteMin(H) Dump(H, "delete min")
print("find min: ", ph.FindMin(H))
ph.Insert(H, 64) Dump(H, "insert 64")
print("find min: ", ph.FindMin(H))
ph.Insert(H, 39) Dump(H, "insert 39")
ph.DeleteMin(H) Dump(H, "delete min")
print("find min: ", ph.FindMin(H))
ph.DeleteMin(H) Dump(H, "delete min")
print("find min: ", ph.FindMin(H))



-- FIBONACCI HEAP TESTS:

local fh = require("fibonacci_heap")

local function N (node, what)
	if node then
		return what .. " = " .. node.key
	end
end

local function AuxDump (node, indent)
	local first

	while node and node ~= first do
		first = first or node

		local lnode, rnode = fh.GetNeighbors(node)
		print(indent, node.key, N(lnode, "L"), N(rnode, "R"))

		if node.child then
			AuxDump(node.child, indent .. "\t")
		end

		node = node.right
	end
end

local function Dump (H, what)
	print(what or "", " Dumping: ")
	print("")

	AuxDump(H.root, "")

	print("")
end

local H = fh.New()

local seq = { 2, 5, 12, 3, 6, -1, 2, 34, -1, -1, 6, 14, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 }

for _, elem in ipairs(seq) do
	if elem ~= -1 then
		fh.Insert(H, elem) Dump(H, "insert " .. elem)
	else
		print("find min: ", fh.FindMin(H))
		fh.DeleteMin(H) Dump(H, "delete min")
	end
end