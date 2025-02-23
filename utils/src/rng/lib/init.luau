local rng = {}

function rng.range(range: number | NumberRange): number
	if type(range) == "number" then
		return range
	else
		local min = range.Min
		return min + math.random() * (range.Max - min)
	end
end

function rng.betweenFloats(min: number, max: number): number
	return min + math.random() * (max - min)
end

-- original code inspired by https://github.com/chancejs/chancejs/blob/master/chance.js#L720
function rng.weighted<V>(arr: { V }, weights: { number }, trim: boolean?): () -> V
	if #arr ~= #weights then
		error("Length of array and weights must match")
	end

	local sum = 0
	for _, weight in ipairs(weights) do
		if type(weight) ~= "number" then
			error("All weights must be numbers")
		end

		if weight > 0 then
			sum += weight
		end
	end

	if sum == 0 then
		error("No valid entries in array weights")
	end

	local selected = math.random() * sum

	return function()
		local total = 0
		local lastGoodIdx = -1
		local chosenIdx: number

		for i, weight in weights do
			total = total + weight
			if weight > 0 then
				if selected <= total then
					chosenIdx = i
					break
				end
				lastGoodIdx = i
			end

			if i == #weights then
				chosenIdx = lastGoodIdx
			end
		end

		local chosen = arr[chosenIdx]

		if trim then
			table.remove(arr, chosenIdx)
			table.remove(weights, chosenIdx)
		end

		return chosen
	end
end

function rng.weightedKey<K, V>(tbl: { [K]: V }, weightGettingFunction: (k: K, v: V) -> number, trim: boolean?): () -> K
	local keys = {}
	local weights = {}

	for k, v in tbl do
		local weight = weightGettingFunction(k, v)
		if weight > 0 then
			table.insert(keys, k)
			table.insert(weights, weight)
		end
	end

	return rng.weighted(keys, weights, trim)
end

function rng.chance(chance: number): boolean
	return math.random() < chance
end

function rng.chancePercent(percent: number): boolean
	return math.random() * 100 < percent
end

return rng
