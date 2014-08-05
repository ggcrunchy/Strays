--- Testing of JPEG files. (As is, more or less matches PNG tests.)

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

local jpeg = require("image_ops.jpeg")
local JPEG = jpeg.Load(system.pathForFile("IMAGE_NAME.jpg", system.ResourceDirectory))
if JPEG then
	print("YAY", JPEG:GetDims())
else
	print(":(")
end
local bmp = require("ui.Bitmap").Bitmap(display.getCurrentStage())
local pixels, w, h = JPEG:GetPixels(), JPEG:GetDims()
bmp:Resize(w, h)
local index = 1
for y = 0, h - 1 do
	for x = 0, w - 1 do
		bmp:SetPixel(x, y, pixels[index] / 255, pixels[index + 1] / 255, pixels[index + 2] / 255, 1)--pixels[index + 3])

		index = index + 4
	end
end