--- Older navigation scheme from editor, since superseded by draggable menus.

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

--[[
-- Tab buttons to choose views... --
local TabButtons = {}

for _, name in ipairs(Names) do
	TabButtons[#TabButtons + 1] = {
		label = strings.SplitIntoWords(name, "on_pattern"),

		onPress = function()
			SetCurrent(EditorView[name])

			return true
		end
	}
end]]



-- ... and the tabs themselves --
--local Tabs


--[[
-- --
local TabsMax = 7

-- --
local TabsToRotate = 3

-- --
local TabOptions, TabRotate, TabW

--
if #TabButtons > TabsMax then
	local params = {
		time = 175,

		onComplete = function(object)
			object.m_going = false
		end
	}

	function TabRotate (inc)
		Tabs.m_going, params.x = true, Tabs.x + inc

		transition.to(Tabs, params)
	end

	function TabW (n)
		return ceil(n * display.contentWidth / TabsMax)
	end

	TabOptions = { left = TabW(1), width = TabW(#TabButtons) }
end
]]

--[[
		-- Load the view-switching tabs.
		Tabs = tabs_patterns.TabBar(self.view, TabButtons, TabOptions)

		-- If there were enough tab options, add clipping and scroll buttons.
		if TabOptions then
			local shown = TabsMax - 2
			local cont, n = display.newContainer(TabW(shown), Tabs.height), #TabButtons - shown

			self.view:insert(cont)
			cont:translate(display.contentCenterX, Tabs.height / 2)
			cont:insert(Tabs, true)

			Tabs.x = TabW(.5 * n)

			local x, w = 0, TabW(1)

			-- TODO: Hack!
			tabs_patterns.TabsHack(self.view, Tabs, shown, function() return TabW(x + 1), x end, 0, TabW(shown))
			-- /TODO

			local lscroll = common_ui.ScrollButton(self.view, "lscroll", 0, 0, function()
				local amount = 0

				for i = 1, Tabs.m_going and 0 or TabsToRotate do
					if x > 0 then
						x, amount = x - 1, amount + w
					end
				end

				if amount ~= 0 then
					TabRotate(amount)
				end
			end)
			local rscroll = common_ui.ScrollButton(self.view, "rscroll", 0, 0, function()
				local amount = 0

				for i = 1, Tabs.m_going and 0 or TabsToRotate do
					if x < n then
						x, amount = x + 1, amount - w
					end
				end

				if amount ~= 0 then
					TabRotate(amount)
				end
			end)

			lscroll.x, rscroll.x = w / 4, display.contentWidth - TabW(1) + w / 4

			lscroll:translate(lscroll.width / 2, lscroll.height / 2)
			rscroll:translate(rscroll.width / 2, rscroll.height / 2)
		end
]]



		--[[
			local button = button.Button_XY(self.view, "1.25%", "from_bottom -" .. (i * 13.54 - 1.04) .. "%", "12.5%", "10.4%", func, text)

			button:translate(button.width / 2, button.height / 2)
]]