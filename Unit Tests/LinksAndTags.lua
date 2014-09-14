--- Links and tags unit test.

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
local button = require("ui.Button")
local scenes = require("utils.Scenes")

-- Corona modules --
local composer = require("composer")

-- Test scene --
local Scene = composer.newScene()

--
function Scene:create ()
	button.Button(self.view, nil, 20, 20, 200, 50, scenes.Opener{ name = "scene.Title" }, "Go Back")
end

Scene:addEventListener("create")

--
function Scene:show (event)
if event.phase == "will" then
	return
end
local links = require("editor.Links")
local tags = require("editor.Tags")

local Objs = {}

local function C (name, tag)
	local c = display.newCircle(self.view, 0, 0, 5)

	c.isVisible = false

	c.m_name = name

	links.SetTag(c, tag)

	Objs[#Objs + 1] = c
end

local function print1 (...)
	print("  ", ...)
end

local function print2 (...)
	print("  ", "  ", ...)
end

links.SetRemoveFunc(function(object)
	print1("Goodbye, " .. object.m_name)
end)

-- Define tag: so far so good
tags.New("MIRBLE", { sub_links = { "Burp", "Slerp", "Derp" } })
tags.New("ANIMAL")
tags.New("DOG", { "ANIMAL" })
tags.New("CAT", { "ANIMAL", "MIRBLE" })
tags.New("WOB", { "CAT" })

-- Create and Set tags: so far so good
C("j", "MIRBLE")
C("k", "ANIMAL")
C("l", "DOG")
C("m", "CAT")
C("n", "WOB")

for _, v in ipairs(Objs) do
	local tag = links.GetTag(v) -- Get tag: good

	print("object:", v.m_name)
	print("tag:", tag)

	local function P (tt)
		if type(tt) ~= "string" then
			print2(tt.m_name)
		elseif tt ~= tag then
			print2(tt)
		end
	end

	-- Children: good
	print1("CHILDREN!")

	for _, tt in tags.TagAndChildren(tag) do
		P(tt)
	end

	-- Multi-children: good
	print1("MULTI-CHILDREN (tag + ANIMAL)")

	for _, tt in tags.TagAndChildren_Multi({ tag, "ANIMAL" }) do
		P(tt)
	end

	-- Parents: good
	print1("PARENTS!")

	for _, tt in tags.TagAndParents(tag) do
		P(tt)
	end

	-- Multi-parents: good
	print1("MULTI-PARENTS (tag + WOB)")

	for _, tt in tags.TagAndParents_Multi({ tag, "WOB" }) do
		P(tt)
	end

	print("")

	-- Sublinks: good
	print1("Sublinks")

	for _, tt in tags.Sublinks(tag) do
		P(tt)
	end

	-- Has child: good
	print1("Has child: WOB", tags.HasChild(tag, "WOB"))
	print1("Has child: DOG", tags.HasChild(tag, "DOG"))
	print1("Has child: MOOP", tags.HasChild(tag, "MOOP"))

	-- Is: good
	print1("Is: MIRBLE", tags.Is(tag, "MIRBLE"))
	print1("Is: WOB", tags.Is(tag, "WOB"))
	print1("Is: GOOM", tags.Is(tag, "GOOM"))

	-- Has sublink: good
	print1("Has sublink: Derp", tags.HasSublink(tag, "Derp"))
	print1("Has sublink: nil", tags.HasSublink(tag, nil))
	print1("Has sublink: OOMP", tags.HasSublink(tag, "OOMP"))

	-- Tagged: good
	print1("Tagged")

	for _, tname in tags.TagAndChildren(tag) do
		for tt in links.Tagged(tname) do
			P(tt)
		end
	end
end

local Messages = {}

local function Print (message)
	if not Messages[message] then
		print1(message)

		Messages[message] = true
	end
end

-- Create links with can_link, sub_links
local SubLinks = {}

local From = #Objs

local function LinkMessage (message, sub1, sub2)
	return message .. ": (" .. tostring(sub1) .. ", " ..tostring(sub2) .. ")"
end

for i = 1, 20 do
	local options = {}
	local sub_links = {}

	for j = 1, i % 3 do
		sub_links[j] = "SL_" .. ((i + 2) % 5)
	end

	options.sub_links = sub_links

	if i > 5 then
		function options.can_link (o1, o2, sub1, sub2)
			local can_link, message
			local num = (sub2 or ""):match("SL_(%d+)") or 0 / 0

			if i <= 10 then
				can_link = num % 2 == 0
				message = LinkMessage("5 to 10, link to evens", sub1, sub2)
			elseif i <= 15 then
				can_link = num % 2 == 1
				message = LinkMessage("11 to 15, link to odds", sub1, sub2)
			else
				can_link = sub2 == nil or num % 3 == 0
				message = LinkMessage("16 to 20, link to 3 * n / nil", sub1, sub2)
			end

			if can_link and Print then
				Print(message)
			end

			return can_link
		end
	end

	SubLinks[i] = sub_links

	tags.New("tag_" .. i, options)

	C("object_" .. i, "tag_" .. i)
end

-- Can link: good?
print("What can link?")

local link_options = {}

local Links = {}

for i = 1, 20 do
	for j = 1, 20 do
		if i ~= j then
			local o1, o2 = Objs[From + i], Objs[From + j]

			for k = 1, #SubLinks[i] + 1 do
				for l = 1, #SubLinks[j] + 1 do
					link_options.sub1 = SubLinks[i][k]
					link_options.sub2 = SubLinks[j][l]

					if links.CanLink(o1, o2, link_options) then
						Links[#Links + 1] = { From + i, From + j, link = links.LinkObjects(o1, o2, link_options) }

						assert(Links[#Links].link, "Invalid link")
					end
				end
			end
		end
	end
end

Print = nil

print("Number of links: ", #Links)
print("Let's break some!")

local function LinkIndex (i)
	return i % #Links + 1
end

for _, v in ipairs{ 100, 200, 300, 400, 500, 600 } do
	local i = LinkIndex(v)
	local intact, o1, o2, sub1, sub2 = Links[i].link:GetObjects()

	print1("Link " .. i .. " intact?", intact, o1 and o1.m_name, o2 and o2.m_name, sub1, sub2)

	Links[i].link:Break()
end

print("State of one of those...")

print1("Link ", LinkIndex(200), Links[LinkIndex(200)].link:GetObjects())

print("Let's destroy some objects!")

for _, v in ipairs{ 50, 150, 250, 350, 450 } do
	local i = LinkIndex(v)
	local intact, o1, o2 = Links[i].link:GetObjects()

	if intact then
		local which

		if i % 2 == 0 then
			print("Link " .. i .. ", breaking object 1")

			which = o1
		else
			print("Link " .. i .. ", breaking object 2")

			which = o2
		end

		print1("Valid before?", Links[i].link:IsValid())

		which:removeSelf()

		print1("Valid after?", Links[i].link:IsValid())
	end
end

-- Links...
local index = LinkIndex(173)
local link = Links[index].link
local intact, lo, _, s1 = link:GetObjects()

local function Obj (obj, sub, self)
	if obj == self then
		return "SELF"
	else
		return obj.m_name .. " (" .. tostring(sub) .. ")"
	end
end

print("Links belonging to link " .. index .. ", SELF = " .. Obj(lo, s1))

for link in links.Links(lo, s1) do
	local _, obj1, obj2, sub1, sub2 = link:GetObjects()

	print1("LINK: ", Obj(obj1, sub1, lo) .. " <-> " .. Obj(obj2, sub2, lo))
end

for i = -1, 7 do
	local sub = i ~= -1 and "SL_" .. i or nil

	print("Has links (" .. tostring(sub) .. ")?", links.HasLinks(lo, sub))
end


end

Scene:addEventListener("show")

--
function Scene:hide ()
	-- ??
end

Scene:addEventListener("hide")

return Scene

--[[
Needs a home:

-- Listen to events.
dispatch_list.AddToMultipleLists{
	-- Build Level --
	build_level = function(level)
		-- ??
		-- Iterate list of links, dispatch out to objects? (some way to look up values from keys...)
	end,

	-- Load Level WIP --
	load_level_wip = function(level)
		-- ??
		-- SetArray() -> lookup tag, key combos?
	end,

	-- Save Level WIP --
	save_level_wip = function(level)
		-- ??
		-- GetArray() -> save tag, key combos?
	end,

	-- Verify Level --
	verify_level = function(verify)
		-- ??
		-- Iterate list of links and ask objects?
	end
}
]]