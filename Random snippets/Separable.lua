--- Some stuff for separable / non-separable kernels that I half-ported from MATLAB, namely
-- from [Separate Kernel in 1D kernels](http://www.mathworks.com/matlabcentral/fileexchange/28218-separate-kernel-in-1d-kernels):
--
-- Copyright (c) 2010, Dirk-Jan Kroon
-- All rights reserved.
--
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
--
--  * Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
--  * Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in
--    the documentation and/or other materials provided with the distribution
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

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
local abs = math.abs
local huge = math.huge
local log = math.log
local random = math.random

-- Exports --
local M = {}

-- 
local function Filter1DToFilterND (par, data, K1)
	if not K1 then
		Kt = ones(data.sizeH)
 
		for i = 1, data.n do
		--		 p = par(data.sep_parb(i) : data.sep_pare(i))
		--		 p = p(:)
			dim = ones(1, data.n)
		--		 dim(i) = data.sep_parl(i)
		--		 Ki = reshape(p(:), dim)
			dim = data.sizeH
		--		 dim(i) = 1
		--		 Kt = Kt .* repmat(Ki, dim)
		end
	else
		Kt = ones(data.sizeHreal)

		for i = 1, data.n do
			dim = data.sizeHreal
		--		dim(i) = 1
		--		Kt = Kt .* repmat(K1{i}, dim)
		end
	end

	return Kt
end

--
local function FilterCorrSign (par, data)
	local t = 0
	Ert = zeros(1, length(par))
	ERR = huge

--	par = sign(rand(size(par)) - 0.5) .* par

	while t < ERR do
		-- Calculate the approximation of the ND kernel if using the 1D kernels.
		KN = Filter1DToFilterND(par, data)

		-- Calculate the absolute error.
	--	ERR = sum(abs(data.H(:) - KN(:)))

		-- Flip the sign of every 1D filter value, and look if the error improves.
		for i = 1, length(par) do
		--	par2 = par
		--	par2(i) = -par2(i)

			KN = Filter1DToFilterND(par2, data)

		--	Ert(i) = sum(abs(data.H(:) - KN(:)))
		end

		-- Flip the sign of the 1D filter value with the largest improvement
		t, j = min(Ert)

		if t < ERR then
--			par(j) = -par(j)
		end

		return par
	end
end

--
local function RemoveZeroRows (H)
	local pz = 0

	-- Remove whole columns / rows / planes with zeros, because we know beforehand that they
	-- will give a kernel 1D value of 0 and will otherwise increase the error in the end result.
	preserve_zeros = zeros(numel(H), 2)

	sizeH = size(H)

	for i = 1, ndims(H) do
--		H2D = reshape(H, size(H,1), [])
		check_zero = not any(H2D, 2)

		if any(check_zero) then
			zero_rows = find(check_zero)

			for j = 1, length(zero_rows) do
				pz = pz + 1
--				preserve_zeros(pz, :) = [i zero_rows(j)]
--				sizeH(1) = sizeH(1) - 1
			end

--			H2D(check_zero, :) = []
			H = reshape(H2D, sizeH)
		end

		H = shiftdim(H, 1)
--		sizeH = circshift(sizeH, [0 -1])
		H = reshape(H, sizeH)
	end

--	preserve_zeros = preserve_zeros(1 : pz, :)

	return H, preserve_zeros
end

-- numel() = what I call area elsewhere
-- ndims() = obvious
-- size() = array of dims, e.g. { W, H }
-- length() = max(W, H, etc.), apparently

--
local function InitializeDataStruct (H)
	data.sizeHreal = size(H)
	data.nreal = ndims(H)

	H, preserve_zeros = RemoveZeroRows(H)

	data.H = H

	data.n = ndims(H)
	data.preserve_zeros = preserve_zeros

--	data.H(H == 0) = eps
	data.sizeH = size(data.H)

--	data.sep_parb = cumsum([1 data.sizeH(1 : data.n - 1)])
	data.sep_pare = cumsum(data.sizeH)
	data.sep_parl = data.sep_pare - data.sep_parb + 1

--	data.par = (1 : numel(H)) + 1

	return data
end

--
local function RestoreZeroRows (data, K1)
	-- Re-add the 1D kernel values responding to a whole column / row or plane of zeros.
	for i = 1, size(data.preserve_zeros, 1) do
		di = data.preserve_zeros(i, 1)
		pos = data.preserve_zeros(i, 2)

		if di > length(K1) then
--			K1{di} = 1
		end

--		val = K1{di}
--		val = val(:)
--		val = [val(1 : pos - 1); 0; val(pos : end)]
		dim = ones(1, data.nreal)
--		dim(di) = length(val)
--		K1{di} = reshape(val, dim)
	end

	return K1
end

--
local function MakeMatrix (data)
	M = zeros(numel(data.H), sum(data.sizeH))
	--	 K1 = (1 : numel(data.H))'

	for i = 1, data.n do
	--		p = data.par(data.sep_parb(i) : data.sep_pare(i))
	--		p = p(:)
		dim = ones(1, data.n)
	--		dim(i) = data.sep_parl(i)
	--		Ki = reshape(p(:), dim)
		dim = data.sizeH
	--		dim(i) = 1
		K2 = repmat(Ki, dim) - 1
	--		M(sub2ind(size(M), K1(:), K2(:))) = 1
	end
 
	return M
end 

--
local function ValueListToFilter1D (par, data)
--[[
	C = cell(dim) creates a cell array of empty matrices. If dim is a scalar, C is dim-by-dim. If dim is a vector, C is dim(1)-by-...-dim(N), where N is the number of elements of dim.

	C = cell(dim1,...,dimN) creates cell array C, where C is dim1-by-...-dimN.

dim1,...,dimN
	Scalar integers that specify the dimensions of C.

	C
	Cell array. Each cell contains an empty, 0-by-0 array of type double.

Conversion to Column Vector

	Convert a matrix or array to a column vector using the colon operator as a single index:

	A = rand(3,4);
	B = A(:);

Use curly braces to construct or get the contents of cell arrays.
]]
	K = cell(1, data.n)

	for i = 1, data.n do
	--		 p = par(data.sep_parb(i) : data.sep_pare(i))
	--		 p = p(:)
		dim = ones(1, data.n)
	--		 dim(i) = data.sep_parl(i) -> dim = { 1, 1, ..., sep_parl[i], ..., 1, 1 }
	--		 K{i}=reshape(p(:), dim)
	end
 
	return K 
end 

--- (Documentation edited from original, see Mathworks link.)
--
-- This function will separate (do decomposition of) any 2D, 3D or N-D kernel into 1D
-- kernels. Of course, only a sub-set of kernels are separable e.g. a Gaussian kernel,
-- but it will give least-squares solutions for non-separable kernels.
--
-- [K1 KN ERR]=SeparateKernel(H);
--   
-- inputs,
--   H : The 2D, 3D ..., ND kernel
--   
-- outputs,
--   K1 : Cell array with the 1D kernels
--   KN : Approximation of the ND input kernel by the 1D kernels
--   ERR : The sum of absolute difference between approximation and input kernel
--
-- 
-- How the algorithm works:
-- If we have a separable kernel like
-- 
--  H = [1 2 1
--       2 4 2
--       3 6 3];
--
-- We like to solve unknown 1D kernels,
--  a=[a(1) a(2) a(3)]
--  b=[b(1) b(2) b(3)]
--
-- We know that,
--  H = a'*b
--
--      b(1)    b(2)    b(3)
--       --------------------
--  a(1)|h(1,1) h(1,2) h(1,3)
--  a(2)|h(2,1) h(2,2) h(2,3)
--  a(3)|h(3,1) h(3,2) h(3,3)
--
-- Thus,
--  h(1,1) == a(1)*b(1)
--  h(2,1) == a(2)*b(1)
--  h(3,1) == a(3)*b(1)
--  h(4,1) == a(1)*b(2)
-- ...
--
-- We want to solve this by using fast matrix (least squares) math,
--
--  c = M * d; 
--  
--  c a column vector with all kernel values H
--  d a column vector with the unknown 1D kernels 
--
-- But matrices "add" values and we have something like  h(1,1) == a(1)*b(1);
-- We solve this by taking the log at both sides 
-- (We replace zeros by a small value. Whole lines/planes of zeros are
--  removed at forehand and re-added afterwards)
--
--  log( h(1,1) ) == log(a(1)) + log b(1))
--
-- The matrix is something like this,
--
--      a1 a2 a3 b1 b2 b3    
-- M = [1  0  0  1  0  0;  h11
--      0  1  0  1  0  0;  h21
--      0  0  1  1  0  0;  h31
--      1  0  0  0  1  0;  h21
--      0  1  0  0  1  0;  h22
--      0  0  1  0  1  0;  h23
--      1  0  0  0  0  1;  h31
--      0  1  0  0  0  1;  h32
--      0  0  1  0  0  1]; h33
--
-- Least squares solution
--  d = exp(M\log(c))
--
-- with the 1D kernels
--
--  [a(1);a(2);a(3);b(1);b(2);b(3)] = d
--
-- The Problem of Negative Values!!!
--
-- The log of a negative value is possible it gives a complex value, log(-1) = i*pi
-- if we take the expontential it is back to the old value, exp(i*pi) = -1 
--
--  But if we use the solver with on of the 1D vectors we get something like, this :
--
--  input         result        abs(result)    angle(result) 
--   -1     -0.0026 + 0.0125i     0.0128         1.7744 
--    2      0.0117 + 0.0228i     0.0256         1.0958 
--   -3     -0.0078 + 0.0376i     0.0384         1.7744  
--    4      0.0234 + 0.0455i     0.0512         1.0958
--    5      0.0293 + 0.0569i     0.0640         1.0958
-- 
-- The absolute value is indeed correct (difference in scale is compensated
-- by the order 1D vectors)
--
-- As you can see the angle is correlated with the sign of the values. But I
-- didn't found the correlation yet. For some matrices it is something like
--
--  sign=mod(angle(solution)*scale,pi) == pi/2;
--
-- In the current algorithm, we just flip the 1D kernel values one by one.
-- The sign change which gives the smallest error is permanently swapped. 
-- Until swapping signs no longer decreases the error
--
-- Examples,
--   a=permute(rand(5,1),[1 2 3 4])-0.5;
--   b=permute(rand(5,1),[2 1 3 4])-0.5;
--   c=permute(rand(5,1),[3 2 1 4])-0.5;
--   d=permute(rand(5,1),[4 2 3 1])-0.5;
--   H = repmat(a,[1 5 5 5]).*repmat(b,[5 1 5 5]).*repmat(c,[5 5 1 5]).*repmat(d,[5 5 5 1]);
--   [K,KN,err]=SeparateKernel(H);
--   disp(['Summed Absolute Error between Real and approximation by 1D filters : ' num2str(err)]);
--
--   a=permute(rand(3,1),[1 2 3])-0.5;
--   b=permute(rand(3,1),[2 1 3])-0.5;
--   c=permute(rand(3,1),[3 2 1])-0.5;
--   H = repmat(a,[1 3 3]).*repmat(b,[3 1 3 ]).*repmat(c,[3 3 1 ])
--   [K,KN,err]=SeparateKernel(H); err
--
--   a=permute(rand(4,1),[1 2 3])-0.5;
--   b=permute(rand(4,1),[2 1 3])-0.5;
--   H = repmat(a,[1 4]).*repmat(b,[4 1]);
--   [K,KN,err]=SeparateKernel(H); err
--
-- Function is written by D.Kroon, uses "log idea" from A. J. Hendrikse, University of Twente
-- (July 2010).
-- @array kernel 2D, 3D ..., N-D kernel.
-- @uint kcols Number of columns in _kernel_. (TODO: Actually do 3D, etc.?)
-- @treturn array Cell array with the 1D kernels. DOCMEMORE!
-- @treturn array Approximation of _kernel_ by the 1D kernels. DOCMEMORE?
-- @treturn number The sum of absolute difference between approximation and _kernel_.
function M.SeparateKernel (kernel, kcols)
	-- We first make some structure which contains information about the transformation from
	-- kernel to 1D kernel array, number of dimensions, and other stuff.
--	data = InitializeDataStruct(kernel)

	-- Make the matrix of c = M * d.
--	M = MakeMatrix(data)
--[[
Solve systems of linear equations Ax = B for x
Syntax
	x = A\B, thus
	d = M \ c
]]
	-- Solve c = M * d with least squares.
--	par = exp(M \ log(abs(data.H(:))))

	-- Improve the values by solving the remaining difference.
--	KN = Filter1DToFilterND(par, data)
--	par2 = exp(M \ log(abs(KN(:) ./ data.H(:))))
--	par = par ./ par2

	-- Change the sign of a 1D filtering value if it decrease the error.
--	par = FilterCorrSign(par, data)

	-- Split the solution d in separate 1D kernels.
--	K1 = ValueListToFilter1D(par, data)

	-- Re-add the removed zero rows/planes to the 1D vectors.
--	K1 = RestoreZeroRows(data, K1)

	-- Calculate the approximation of the ND kernel if using the 1D kernels.
--	KN = Filter1DToFilterND(par, data, K1)

	-- Calculate the absolute error.
--	ERR = sum(abs(H(:) - KN(:)))
end

--[[
find()
Find indices and values of nonzero elements
Syntax
	ind = find(X)
	ind = find(X, k)
	ind = find(X, k, 'first')
	ind = find(X, k, 'last')
	[row,col] = find(X, ...)
	[row,col,v] = find(X, ...)

	Description

	ind = find(X) locates all nonzero elements of array X, and returns the linear indices of those elements in vector ind. If X is a row vector, then ind is a row vector; otherwise, ind is a column vector. If X contains no nonzero elements or is an empty array, then ind is an empty array.

	ind = find(X, k) or ind = find(X, k, 'first') returns at most the first k indices corresponding to the nonzero entries of X. k must be a positive integer, but it can be of any numeric data type.

	ind = find(X, k, 'last') returns at most the last k indices corresponding to the nonzero entries of X.

	[row,col] = find(X, ...) returns the row and column indices of the nonzero entries in the matrix X. This syntax is especially useful when working with sparse matrices. If X is an N-dimensional array with N > 2, col contains linear indices for the columns. For example, for a 5-by-7-by-3 array X with a nonzero element at X(4,2,3), find returns 4 in row and 16 in col. That is, (7 columns in page 1) + (7 columns in page 2) + (2 columns in page 3) = 16.

	[row,col,v] = find(X, ...) returns a column or row vector v of the nonzero entries in X, as well as row and column indices. If X is a logical expression, then v is a logical array. Output v contains the non-zero elements of the logical array obtained by evaluating the expression X. For example,

	A= magic(4)
	A =
		16     2     3    13
		 5    11    10     8
		 9     7     6    12
		 4    14    15     1

	[r,c,v]= find(A>10);

	r', c', v'
	ans =
		 1     2     4     4     1     3
	ans =
		 1     2     2     3     4     4
	ans =
		 1     1     1     1     1     1
	Here the returned vector v is a logical array that contains the nonzero elements of N where

	N=(A>10)
]]

--[[
reshape()
Reshape array
Syntax
	B = reshape(A,m,n)
	B = reshape(A,[m n])
	B = reshape(A,m,n,p,...)
	B = reshape(A,[m n p ...])
	B = reshape(A,...,[],...)

	Description

	B = reshape(A,m,n) or B = reshape(A,[m n]) returns the m-by-n matrix B whose elements are taken column-wise from A. An error results if A does not have m*n elements.

	B = reshape(A,m,n,p,...) or B = reshape(A,[m n p ...]) returns an n-dimensional array with the same elements as A but reshaped to have the size m-by-n-by-p-by-.... The product of the specified dimensions, m*n*p*..., must be the same as numel(A).

	B = reshape(A,...,[],...) calculates the length of the dimension represented by the placeholder [], such that the product of the dimensions equals numel(A). The value of numel(A) must be evenly divisible by the product of the specified dimensions. You can use only one occurrence of [].
]]

--[[
repmat()
Syntax
	B = repmat(A,n)example
	B = repmat(A,sz1,sz2,...,szN)example
	B = repmat(A,sz)example
	Description
	example
	B = repmat(A,n) returns an n-by-n tiling of A. The size of B is size(A) * n

	example
	B = repmat(A,sz1,sz2,...,szN) specifies a list of scalars, sz1,sz2,...,szN, to describe an N-D tiling of A. The size of B is [size(A,1)*sz1, size(A,2)*sz2,...,size(A,n)*szN]. For example, repmat([1 2; 3 4],2,3) returns a 4-by-6 matrix.

	example
	B = repmat(A,sz) specifies a row vector, sz, instead of a list of scalars, to describe the tiling of A. This syntax returns the same output as the previous syntax. For example, repmat([1 2; 3 4],[2 3]) returns the same result as repmat([1 2; 3 4],2,3).
]]

--[[
cumsum()
Cumulative sum
Syntax
	B = cumsum(A)
	B = cumsum(A,dim)
	Description
	example
	B = cumsum(A) returns an array of the same size as the array A containing the cumulative sum.

	If A is a vector, then cumsum(A) returns a vector containing the cumulative sum of the elements of A.

	If A is a matrix, then cumsum(A) returns a matrix containing the cumulative sums for each column of A.

	If A is a multidimensional array, then cumsum(A) acts along the first nonsingleton dimension.

	example
	B = cumsum(A,dim) returns the cumulative sum of the elements along dimension dim. For example, if A is a matrix, then cumsum(A,2) returns the cumulative sum of each row.
]]

--[[
circshift()
Shift array circularly
The default behavior of circshift(A,K), where K is a scalar, will change in a future release. The new default behavior will be to operate along the first array dimension of A whose size does not equal 1. Use circshift(A,[K 0]) to retain current behavior.

Syntax
	Y = circshift(A,K)example
	Y = circshift(A,K,dim)example
	Description
	example
	Y = circshift(A,K) circularly shifts the elements in array A by K positions. Specify K as an integer to shift the rows of A, or as a vector of integers to specify the shift amount in each dimension.

	example
	Y = circshift(A,K,dim) circularly shifts the values in array A by K positions along dimension dim. Inputs K and dim must be scalars.
]]

--[[
shiftdim()
Shift dimensions
Syntax
	B = shiftdim(X,n)
	[B,nshifts] = shiftdim(X)

	Description

	B = shiftdim(X,n) shifts the dimensions of X by n. When n is positive, shiftdim shifts the dimensions to the left and wraps the n leading dimensions to the end. When n is negative, shiftdim shifts the dimensions to the right and pads with singletons.

	[B,nshifts] = shiftdim(X) returns the array B with the same number of elements as X but with any leading singleton dimensions removed. A singleton dimension is any dimension for which size(A,dim) = 1. nshifts is the number of dimensions that are removed.

	If X is a scalar, shiftdim has no effect.
]]

--[[
sub2ind()
Convert subscripts to linear indices
	Syntax
	linearInd = sub2ind(matrixSize, rowSub, colSub)
	linearInd = sub2ind(arraySize, dim1Sub, dim2Sub, dim3Sub, ...)

	Description

	linearInd = sub2ind(matrixSize, rowSub, colSub) returns the linear index equivalents to the row and column subscripts rowSub and colSub for a matrix of size matrixSize. The matrixSize input is a 2-element vector that specifies the number of rows and columns in the matrix as [nRows, nCols]. The rowSub and colSub inputs are positive, whole number scalars or vectors that specify one or more row-column subscript pairs for the matrix. Example 3 demonstrates the use of vectors for the rowSub and colSub inputs.

	linearInd = sub2ind(arraySize, dim1Sub, dim2Sub, dim3Sub, ...) returns the linear index equivalents to the specified subscripts for each dimension of an N-dimensional array of size arraySize. The arraySize input is an n-element vector that specifies the number of dimensions in the array. The dimNSub inputs are positive, whole number scalars or vectors that specify one or more row-column subscripts for the matrix.

	All subscript inputs can be single, double, or any integer type. The linearInd output is always of class double.

	If needed, sub2ind assumes that unspecified trailing subscripts are 1. See Example 2, below.
]]

--[[
sum()
Sum of array elements
Syntax
	S = sum(A)example
	S = sum(A,dim)example
	S = sum(___,type)example
	Description
	example
	S = sum(A) returns the sum of the elements of A along the first array dimension whose size does not equal 1:

	If A is a vector, then sum(A) returns the sum of the elements.

	If A is a nonempty, nonvector matrix, then sum(A) treats the columns of A as vectors and returns a row vector whose elements are the sums of each column.

	If A is an empty 0-by-0 matrix, then sum(A) returns 0, a 1-by-1 matrix.

	If A is a multidimensional array, then sum(A) treats the values along the first array dimension whose size does not equal 1 as vectors and returns an array of row vectors. The size of this dimension becomes 1 while the sizes of all other dimensions remain the same.

	example
	S = sum(A,dim) sums the elements of A along dimension dim. The dim input is a positive integer scalar.

	example
	S = sum(___,type) accumulates in and returns an array in the class specified by type, using any of the input arguments in the previous syntaxes. type can be 'double' or 'native'.
]]

--[[
(:)
	The colon operator generates a sequence of numbers that you can use in creating or indexing into arrays. SeeGenerating a Numeric Sequence for more information on using the colon operator.

	Numeric Sequence Range

	Generate a sequential series of regularly spaced numbers from first to last using the syntax first:last. For an incremental sequence from 6 to 17, use

	N = 6:17
	Numeric Sequence Step

	Generate a sequential series of numbers, each number separated by a step value, using the syntax first:step:last. For a sequence from 2 through 38, stepping by 4 between each entry, use

	N = 2:4:38
	Indexing Range Specifier

	Index into multiple rows or columns of a matrix using the colon operator to specify a range of indices:

	B = A(7, 1:5);          % Read columns 1-5 of row 7.
	B = A(4:2:8, 1:5);      % Read columns 1-5 of rows 4, 6, and 8.
	B = A(:, 1:5);          % Read columns 1-5 of all rows.
	Conversion to Column Vector

	Convert a matrix or array to a column vector using the colon operator as a single index:

	A = rand(3,4);
	B = A(:);
	Preserving Array Shape on Assignment

	Using the colon operator on the left side of an assignment statement, you can assign new values to array elements without changing the shape of the array:

	A = rand(3,4);
	A(:) = 1:12;
]]

-- ./ Guess: member-wise divide

--[[
X{1}

	Use curly braces to construct or get the contents of cell arrays.

	Cell Array Constructor

	To construct a cell array, enclose all elements of the array in curly braces:

	C = {[2.6 4.7 3.9], rand(8)*6, 'C. Coolidge'}
	Cell Array Indexing

	Index to a specific cell array element by enclosing all indices in curly braces:

	A = C{4,7,2}
	For more information, see Cell Arrays
]]

--[[
 \
Solve systems of linear equations Ax = B for x
Syntax
	x = A\B
	x = mldivide(A,B)
	Description
	example
	x = A\B solves the system of linear equations A*x = B. The matrices A and B must have the same number of rows. MATLAB® displays a warning message if A is badly scaled or nearly singular, but performs the calculation regardless.

	If A is a scalar, then A\B is equivalent to A.\B.

	If A is a square n-by-n matrix and B is a matrix with n rows, then x = A\B is a solution to the equation A*x = B, if it exists.

	If A is a rectangular m-by-n matrix with m ~= n, and B is a matrix with m rows, then A\B returns a least-squares solution to the system of equations A*x= B.

	x = mldivide(A,B) is an alternative way to execute x = A\B, but is rarely used. It enables operator overloading for classes. 
]]

--[[
length()
Length of vector or largest array dimension
Syntax
	numberOfElements = length(array)

	Description

	numberOfElements = length(array) finds the number of elements along the largest dimension of an array. array is an array of any MATLAB® data type and any valid dimensions. numberOfElements is a whole number of the MATLAB double class.

	For nonempty arrays, numberOfElements is equivalent to max(size(array)). For empty arrays, numberOfElements is zero.
]]

--[[
numel()
Number of array elements
Syntax
	n = numel(A)
	Description
	example
	n = numel(A) returns the number of elements, n, in array A, equivalent to prod(size(A)).
]]

--[[
size()
Array dimensions
Syntax
	d = size(X)
	[m,n] = size(X)
	m = size(X,dim)
	[d1,d2,d3,...,dn] = size(X),

	Description

	d = size(X) returns the sizes of each dimension of array X in a vector, d, with ndims(X) elements.

	If X is a scalar, then size(X) returns the vector [1 1]. Scalars are regarded as a 1-by-1 arrays in MATLAB®.
	If X is a table, size(X) returns a two-element row vector consisting of the number of rows and the number of variables in the table. Variables in the table can have multiple columns, but size only counts the variables and rows.
	[m,n] = size(X) returns the size of matrix X in separate variables m and n.

	m = size(X,dim) returns the size of the dimension of X specified by scalar dim.

	[d1,d2,d3,...,dn] = size(X), for n > 1, returns the sizes of the dimensions of the array X in the variables d1,d2,d3,...,dn, provided the number of output arguments n equals ndims(X). If n does not equal ndims(X), the following exceptions hold:

	n < ndims(X)
	di equals the size of the ith dimension of X for 0<i<n, but dn equals the product of the sizes of the remaining dimensions of X, that is, dimensions n through ndims(X).
	n > ndims(X)
	size returns ones in the "extra" variables, that is, those corresponding to ndims(X)+1 through n.
	Note   For a Java array, size returns the length of the Java array as the number of rows. The number of columns is always 1. For a Java array of arrays, the result describes only the top level array.
]]