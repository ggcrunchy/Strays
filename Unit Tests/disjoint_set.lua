--- Disjoint set (via union-find) tests.

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

local a = M.NewNode(1)
local b = M.NewNode(2)
local c = M.NewNode(3)
local d = M.NewNode(4)
local e = M.NewNode(5)
print(M.Find(a), M.Find(b), M.Find(c))
M.Union(a, b)
print(M.Find(a), M.Find(b), M.Find(c))
M.Union(a, c)
print(M.Find(a), M.Find(b), M.Find(c))
print(M.Find(d), M.Find(e))
M.Union(d, e)
print(M.Find(d), M.Find(e))
M.Union(a, e)
print(M.Find(a), M.Find(b), M.Find(c), M.Find(d), M.Find(e))