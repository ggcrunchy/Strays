--- Colored corners testing.

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

local index, y, x = 1, 25

for row = 1, 17 do
	if row == 17 then
		index = 1
	end

	x = 300

	local nums = {}

	for col = 1, 17 do
		local color

		if col == 17 then
			color = Colors[index - 16]
		else
			color = Colors[index]

			if row < 17 then
				local below = row < 16 and index + 16 or col
				local right = col < 16 and 1 or -15

				nums[#nums + 1] = tostring(color + 4 * Colors[below] + 16 * Colors[below + right] + 64 * Colors[index + right])
			end

			index = index + 1
		end

		local circ = display.newCircle(self.view, x, y, 8)

		if color == R then
			circ:setFillColor(.6, 0, 0)
		elseif color == G then
			circ:setFillColor(0, .6, 0)
		elseif color == B then
			circ:setFillColor(0, 0, .6)
		elseif color == Y then
			circ:setFillColor(.8, .8, 0)
		end

		x = x + 20
	end

	if row < 17 then
		print(table.concat(nums, ", "))
	end

	y = y + 20
end