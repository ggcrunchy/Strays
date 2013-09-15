--- DOCMAYBE

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
	Bucketwidth[1] = (MaxTS - MinTS) / NTop

	bucket_k = floor((TS - RStart[i]) / Bucketwidth[i])

	Bucketwidth[i + 1] = Bucketwidth[i] / THRES
]]

-- TODO: Need to read paper again :/ 
-- No link :( (not sure where I found my copy... it's behind a paywall everywhere I search online)
	local Threshold = 50

	local function New ()
		local Top, Bottom, Rungs
		local NTop, NBottom = 0, 0
		local MinTimeStamp, MaxTimeStamp

		--
		local function InsertToTail (list, event, ts)
			--?
		end

		--
		local function Enqueue (event, time_stamp)
			--
			if time_stamp >= Top.start then
				InsertToTail(Top, event, time_stamp)

				NTop = NTop + 1

				return
			end

			--
			local index, nrungs, rung = 0, #(Rungs or "")

			repeat
				index = index + 1
				rung = Rungs[index]
			until index > nrungs or time_stamp >= rung.cur

			--
			if index <= nrungs then -- found
				local bucket_k = (time_stamp - rung.start) / BucketWidth[index]

				InsertToTail(rung[bucket_k], event, time_stamp) -- ???
				-- Inc(NBucket[x, bk])

			--
			elseif NBottom > Threshold then

			--
			else
			end
		end

		--
		local function Dequeue ()
		end

		--
		return Enqueue, Dequeue
	end
	local function Enqueue ()
--[[
		if TS >= TopStart then
			InsertIntoTailOf(Top)
			NTop = NTop + 1
			return
		end
		while TS < RCur[x] and x <= NRung do
			x = x + 1
		end
]]
		if x <= NRung then -- found
--[=[
			bucket_k = (TS - RStart[x]) / Bucketwidth[x] -- minus sign?
			InsertIntoTailOf(Rung[x], bucket_k)
			Increment(NBucket(x, bucket_k))
]=]
		elseif NBot > THRES then
			CreateNewRung(NBot)
			TransferBottomToIt()
			-- insert event in new rung
			bucket_k = (TS - RStart[NRung]) / Bucketwidth[NRung] -- minus?
			InsertIntoTailOf(Rung[NRung], bucket_k)
			Increment(NBucket(NRung, bucket_k))
		else
			InsertInto(Bottom) -- using sequential search
			NBot = NBot + 1
		end
	end

	local function Dequeue ()
		if not Empty(Bottom) then
			return NextFrom(Bottom)
		elseif NRung > 0 then
			bucket_k = RecurseRung()
			if Last() then
				NRung = NRung - 1
			end
			SortFromTo(bucket_k, Bottom)
		else
			Bucketwidth[1] = (MaxTS - MinTS) / NTop -- minus?
			TopStart = MaxTS
			RStart[1], RCur[1] = MinTS, MinTS
			TransferToRung1(Top)
			bucket_k = RecurseRung()
			SortFromAndCopyTo(bucket_k, Bottom)
		end
		return FirstFrom(Bottom)
	end

	local function RecurseRung ()
-- ::find_bucket::
		while NBucket(NRung, k) == 0 do
			k = k + 1
			RCur[NRung] = RCur[NRung] + Bucketwidth[NRung]
		end
		if NBucket(NRung, k) > THRES then
			CreateNewRung(NBucket(NRung, k))
			RecopyEventsFromBucketToNewRung()
--			goto find_bucket
		end
		return k
	end

	local function CreateNewRung (nevent)
		NRung = NRung + 1
		-- nevent is the number of events to be recopied
		Bucketwidth[NRung] = Bucketwidth[NRung - 1] / nevent
		RStart[NRung], RCur[NRung] = RCur[NRung - 1], RCur[NRung - 1]
	end