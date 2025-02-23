--!native

local Spring = require(script.Spring)
local hooke = require(script.hooke)

export type Spring = Spring.Spring

local mathHelper = {}

function mathHelper.map(
    x: number,
    inMin: number,
    inMax: number,
    outMin: number,
    outMax: number
): number
    return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

function mathHelper.mapClamp(x: number, inMin: number, inMax: number, outMin: number, outMax: number): number
    return math.clamp(
        (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin,
        math.min(outMin, outMax),
        math.max(outMin, outMax)
    )
end

function mathHelper.roundToIncrement(value: number, increment: number?): number
    if increment then
        return math.round(value / increment) * increment
    else
        return math.round(value)
    end
end

function mathHelper.roundToPlaces(value: number, decimalPlaces: number): number
    local scaleFactor = 10 ^ decimalPlaces
    return math.floor(value * scaleFactor + 0.5) / scaleFactor
end

function mathHelper.isFinite(value: number): boolean
    return value == value and value ~= math.huge and value ~= -math.huge
end

function mathHelper.fuzzyEqual(a: number, b: number, epsilon: number?): boolean
	-- selene: allow(shadowing)
    local epsilon = if epsilon then epsilon else 0.0001
    return math.abs(a - b) < epsilon
end

function mathHelper.wrap(a: number, min: number, max: number): number
    local range = min - max

    return a - (range * math.floor((a - max) / range))
end

function mathHelper.pingPong(a: number, scale: number): number
    local fractPart = (a - scale) / (scale * 2.0)
    return math.abs(((fractPart - math.floor(fractPart)) * scale * 2.0) - scale)
end

function mathHelper.lerp(start: number, goal: number, alpha: number): number
	return start + (goal - start) * alpha
end

function mathHelper.smoothstep(edge0: number, edge1: number, x: number): number
    local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

function mathHelper.magnitude(v3: Vector3): number
	return math.abs((v3.X ^2 + v3.Y ^2 + v3.Z ^2)^0.5)
end

function mathHelper.random(min: number, max: number): number
	return min + math.random() * (max - min)
end

function mathHelper.distanceBetweenPointAndLine2D(
	linePoint1: Vector2,
	linePoint2: Vector2,
	point: Vector2
): number
	local x1, y1 = linePoint1.X, linePoint1.Y
	local x2, y2 = linePoint2.X, linePoint2.Y
	local x3, y3 = point.X, point.Y

	local px = x2 - x1
	local py = y2 - y1
	local temp = (px * px + py * py)
	local u =  ((x3 - x1) * px + (y3 - y1) * py) / (temp)
	if u > 1 then
		u = 1
	elseif u < 0 then
		u = 0
	end

	local x = x1 + u * px
	local y = y1 + u * py

	local dx = x - x3
	local dy = y - y3
	return (dx * dx + dy * dy) ^ 0.5
end

function mathHelper.distanceBetweenPointAndLine3D(
	linePoint1: Vector3,
	linePoint2: Vector3,
	point: Vector3
): number
	local x1, y1, z1 = linePoint1.X, linePoint1.Y, linePoint1.Z
	local x2, y2, z2 = linePoint2.X, linePoint2.Y, linePoint2.Z
	local x3, y3, z3 = point.X, point.Y, point.Z

	local px = x2 - x1
	local py = y2 - y1
	local pz = z2 - z1
	local temp = (px * px + py * py + pz * pz)
	local u =  ((x3 - x1) * px + (y3 - y1) * py + (z3 - z1) * pz) / (temp)
	if u > 1 then
		u = 1
	elseif u < 0 then
		u = 0
	end

	local x = x1 + u * px
	local y = y1 + u * py
	local z = z1 + u * pz

	local dx = x - x3
	local dy = y - y3
	local dz = z - z3
	return (dx * dx + dy * dy + dz * dz) ^ 0.5
end

function mathHelper.distanceBetweenPointAndRay(
	rayOrigin: Vector3,
	rayDirection: Vector3,
	point: Vector3
): number
	local a = rayOrigin
	local b = rayOrigin + rayDirection
	local c = point

	local ab = b - a
	local ac = c - a

	local abac = ab:Dot(ac)
	local abab = ab:Dot(ab)

	local t = abac / abab

	if t < 0 then
		t = 0
	elseif t > 1 then
		t = 1
	end

	local d = (a + ab * t - c).Magnitude
	return d
end

function mathHelper.isPointInFOV(
	origin: Vector3,
	forward: Vector3,
	FOV: number,
	point: Vector3
): boolean
	local direction = (point - origin).Unit
	local angle = forward:Dot(direction)

	return angle <= FOV
end

function mathHelper.isPointInCFrameFOV(
	origin: CFrame,
	FOV: number,
	point: Vector3
): boolean
	local direction = (point - origin.Position).Unit
	local angle = origin.LookVector:Dot(direction)

	return angle <= FOV
end

mathHelper.Spring = Spring
mathHelper.hooke = hooke

return mathHelper
