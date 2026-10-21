-- util — small maths helpers the engine doesn't provide.

function clamp(v, a, b)
	if v < a then
		return a
	end
	if v > b then
		return b
	end
	return v
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function sign(v)
	if v < 0 then
		return -1
	end
	return 1
end

-- atan2 from a polynomial atan (|error| < 0.005 rad), good enough for facing.
function atan2(y, x)
	local ax = abs(x)
	local ay = abs(y)
	if ax < 0.000001 and ay < 0.000001 then
		return 0
	end
	local a = 0
	if ax > ay then
		a = ay / ax
	else
		a = ax / ay
	end
	local s = a * a
	local r = ((-0.0464964749 * s + 0.15931422) * s - 0.327622764) * s * a + a
	if ay > ax then
		r = 1.5707963 - r
	end
	if x < 0 then
		r = 3.1415927 - r
	end
	if y < 0 then
		r = -r
	end
	return r
end

-- Shortest signed difference b - a between two angles.
function ang_diff(a, b)
	local d = b - a
	while d > pi do
		d = d - tau
	end
	while d < -pi do
		d = d + tau
	end
	return d
end

function dist2d(ax, ay, bx, by)
	local dx = bx - ax
	local dy = by - ay
	return sqrt(dx * dx + dy * dy)
end

function dist3d(ax, ay, az, bx, by, bz)
	local dx = bx - ax
	local dy = by - ay
	local dz = bz - az
	return sqrt(dx * dx + dy * dy + dz * dz)
end

-- Ease v towards t by rate (per second), frame-rate independent enough.
function approach(v, t, rate, dt)
	local k = clamp(rate * dt, 0, 1)
	return v + (t - v) * k
end

-- Set an entity's tint. (silt: a field assigned a constructor that mentions
-- locals miscompiles, so the table is built as its own local first.)
function tint(ent, r, g, b)
	local t = { r, g, b, 1 }
	ent.tint = t
end
