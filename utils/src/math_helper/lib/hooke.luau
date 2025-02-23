--!native

local V0 = Vector3.new()

return function(k: number, b: number): (Vector3) -> Vector3
	k = k or 0.075
	b = b or 0.215
	b = 1 - b

	local vel = V0
	local position = V0

	return function(target: Vector3)
		vel = b * vel + k * (target - position)
		position += vel
		return position
	end
end
