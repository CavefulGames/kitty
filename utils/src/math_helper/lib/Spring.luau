--!native

local ITERATION = 8

export type Spring = typeof(setmetatable(
	{} :: {
		target: Vector3,
		position: Vector3,
		velocity: Vector3,
		mass: number,
		force: number,
		damping: number,
		speed: number
	},
	{} :: SpringImpl
))

type SpringImpl = {
	__index: SpringImpl,
	new: (mass: number, force: number, damping: number, speed: number) -> Spring,
	shove: (self: Spring, force: Vector3) -> (),
	update: (self: Spring, deltaTime: number) -> Vector3
}

local Spring = {} :: SpringImpl

function Spring.new(mass, force, damping, speed)
	return setmetatable({
		target = Vector3.new();
		position = Vector3.new();
		velocity = Vector3.new();
		mass = mass or 5;
		force = force or 50;
		damping	= damping or 4;
		speed = speed  or 4;
	}, Spring)
end

function Spring.shove(self, force)
	local x, y, z = force.X, force.Y, force.Z
	if x ~= x or x == math.huge or x == -math.huge then
		x = 0
	end
	if y ~= y or y == math.huge or y == -math.huge then
		y = 0
	end
	if z ~= z or z == math.huge or z == -math.huge then
		z = 0
	end
	self.velocity = self.velocity + Vector3.new(x, y, z)
end

function Spring.update(self, deltaTime)
	local scaledDeltaTime = math.min(deltaTime,1) * self.speed / ITERATION

	for _ = 1, ITERATION do
		local iterationForce = self.target - self.position
		local acceleration = (iterationForce * self.force) / self.mass

		acceleration = acceleration - self.velocity * self.damping

		self.velocity = self.velocity + acceleration * scaledDeltaTime
		self.position = self.position + self.velocity * scaledDeltaTime
	end

	return self.position
end

return Spring
