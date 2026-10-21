-- world — the level's solid boxes, its mesh, and the collision every body
-- (frog, bugs) moves through.
--
-- The level is a list of axis-aligned boxes W.b[i] = {x0,y0,z0,x1,y1,z1}.
-- Bodies are z-up cylinders standing on their feet: {x,y,z,vx,vy,vz,r,h}.

W = {}
W.b = {}
W.n = 0
STEP = 0.4 -- how high a grounded body can step up without jumping
KILL_Z = -30 -- fall below this and you're gone

function W.add(x0, y0, z0, x1, y1, z1, kind)
	local b = { x0 = x0, y0 = y0, z0 = z0, x1 = x1, y1 = y1, z1 = z1, kind = kind }
	local n = W.n + 1
	W.n = n
	W.b[n] = b
	return b
end

-- A box by centre and size, standing on z0.
function W.tower(cx, cy, sx, sy, z0, z1, kind)
	local hx = sx * 0.5
	local hy = sy * 0.5
	return W.add(cx - hx, cy - hy, z0, cx + hx, cy + hy, z1, kind)
end

-- The layout. Main island at z=0, a second island east across a gap,
-- towers and floating platforms climbing up to the spire the exit sits on.
function W.layout()
	W.add(-32, -32, -6, 32, 32, 0, "island")
	W.add(42, -12, -5, 66, 12, 2, "island")
	-- stepping stones across the gap
	W.tower(36, 0, 3, 3, 0.5, 1.5, "plat")
	-- towers on the main island
	W.tower(10, 8, 4, 4, 0, 6, "tower")
	W.tower(-12, 12, 6, 6, 0, 3, "tower")
	W.tower(-14, -12, 4, 4, 0, 10, "tower")
	W.tower(14, -14, 6, 6, 0, 4, "tower")
	W.tower(18, -14, 2, 2, 4, 7, "tower")
	W.tower(-22, 2, 3, 8, 0, 2, "tower")
	W.tower(22, 20, 5, 5, 0, 5, "tower")
	-- floating platforms
	W.tower(2, -6, 4, 4, 8, 9, "plat")
	W.tower(-12, -1, 4, 4, 14, 15, "plat")
	W.tower(18, 2, 4, 4, 7, 8, "plat")
	W.tower(56, 0, 4, 4, 9, 10, "plat")
	W.tower(4, 22, 3, 3, 10, 11, "plat")
	-- the spire: the exit pad appears on top of it
	W.tower(-4, 8, 3, 3, 0, 20, "spire")
	-- crates and low walls on the east island
	W.tower(50, 6, 2, 2, 2, 4, "tower")
	W.tower(60, -6, 3, 3, 2, 5, "tower")
	W.tower(48, -7, 4, 1, 2, 3, "tower")
end

-- Checkerboard the top of a box in 4x4 squares.
function W.checker(m, b, ca, cb)
	local s = 4
	local x = b.x0
	local y = 0
	local ix = 0
	local iy = 0
	local x1 = 0
	local y1 = 0
	local c = ca
	while x < b.x1 - 0.01 do
		y = b.y0
		iy = 0
		x1 = x + s
		if x1 > b.x1 then
			x1 = b.x1
		end
		while y < b.y1 - 0.01 do
			y1 = y + s
			if y1 > b.y1 then
				y1 = b.y1
			end
			c = ca
			if (ix + iy) % 2 == 1 then
				c = cb
			end
			Mesh.flat(m, x, y, x1, y1, b.z1, c)
			y = y1
			iy = iy + 1
		end
		x = x1
		ix = ix + 1
	end
end

function W.build_mesh()
	local m = Mesh.new()
	local i = 0
	local b = nil
	local cx = 0
	local cy = 0
	local zt = 0
	for i = 1, W.n do
		b = W.b[i]
		zt = b.z1 - 0.04
		if b.kind == "island" then
			-- body sits just under the checker so the two never z-fight
			Mesh.box(m, b.x0, b.y0, b.z0, b.x1, b.y1, zt, C.dirt)
			W.checker(m, b, C.chk_a, C.chk_b)
			cx = (b.x0 + b.x1) * 0.5
			cy = (b.y0 + b.y1) * 0.5
			Mesh.cyl(m, cx, cy, b.z0 - 14, b.z0, 2, (b.x1 - b.x0) * 0.45, 8, C.dirt_dk, C.dirt, C.dirt_dk)
		elseif b.kind == "plat" then
			Mesh.boxt(m, b.x0, b.y0, b.z0, b.x1, b.y1, b.z1, C.plat, C.plat_top)
			cx = (b.x0 + b.x1) * 0.5
			cy = (b.y0 + b.y1) * 0.5
			Mesh.cyl(m, cx, cy, b.z0 - 1.6, b.z0, 0.05, (b.x1 - b.x0) * 0.5, 6, C.stripe, C.plat, C.stripe)
		elseif b.kind == "spire" then
			Mesh.box6(m, b.x0, b.y0, b.z0, b.x1, b.y1, b.z1, C.tw_top2, C.stripe, C.tw_a, C.stripe, C.tw_a, C.tw_a)
		else
			if i % 2 == 0 then
				Mesh.boxt(m, b.x0, b.y0, b.z0, b.x1, b.y1, b.z1, C.tw_a, C.tw_top)
			else
				Mesh.boxt(m, b.x0, b.y0, b.z0, b.x1, b.y1, b.z1, C.tw_b, C.tw_top2)
			end
		end
	end
	Mesh.finish(m, "level")
	W.ent = Mesh.place("level")
end

function W.init()
	W.b = {}
	W.n = 0
	W.layout()
	W.build_mesh()
end

-- Does a circle (x, y, r) overlap box b's footprint? Returns the push-out
-- vector (or nil) to move the circle clear of it.
function W.circle_push(b, x, y, r)
	local cx = clamp(x, b.x0, b.x1)
	local cy = clamp(y, b.y0, b.y1)
	local dx = x - cx
	local dy = y - cy
	local d2 = dx * dx + dy * dy
	if d2 >= r * r then
		return nil
	end
	local out = {}
	if d2 > 0.000001 then
		local d = sqrt(d2)
		out.x = dx / d * (r - d)
		out.y = dy / d * (r - d)
		return out
	end
	-- centre is inside the footprint: leave by the nearest side
	local l = x - b.x0 + r
	local rr = b.x1 - x + r
	local dn = y - b.y0 + r
	local up = b.y1 - y + r
	out.x = 0
	out.y = 0
	local best = l
	out.x = -l
	if rr < best then
		best = rr
		out.x = rr
	end
	if dn < best then
		best = dn
		out.x = 0
		out.y = -dn
	end
	if up < best then
		out.x = 0
		out.y = up
	end
	return out
end

function W.over(b, x, y, r)
	local cx = clamp(x, b.x0, b.x1)
	local cy = clamp(y, b.y0, b.y1)
	local dx = x - cx
	local dy = y - cy
	return dx * dx + dy * dy < r * r
end

-- Move a body by its velocity for dt, sliding along walls, stepping up
-- small ledges, landing on tops and bonking on undersides.
-- Sets body.ground (true while standing) and body.hitwall.
function W.move(o, dt)
	local i = 0
	local b = nil
	local push = nil
	local tol = 0.05
	if o.ground == true then
		tol = STEP
	end
	local nx = o.x + o.vx * dt
	local ny = o.y + o.vy * dt
	o.hitwall = false
	for i = 1, W.n do
		b = W.b[i]
		if o.z < b.z1 - tol and o.z + o.h > b.z0 then
			push = W.circle_push(b, nx, ny, o.r)
			if push ~= nil then
				nx = nx + push.x
				ny = ny + push.y
				o.hitwall = true
				-- kill the velocity going into the wall
				local pl = sqrt(push.x * push.x + push.y * push.y)
				if pl > 0.000001 then
					local px = push.x / pl
					local py = push.y / pl
					local vn = o.vx * px + o.vy * py
					if vn < 0 then
						o.vx = o.vx - px * vn
						o.vy = o.vy - py * vn
					end
				end
			end
		end
	end
	o.x = nx
	o.y = ny
	local nz = o.z + o.vz * dt
	local land = -1000
	local feet_r = o.r * 0.75
	for i = 1, W.n do
		b = W.b[i]
		if W.over(b, nx, ny, feet_r) then
			if o.vz <= 0 and o.z >= b.z1 - tol and nz <= b.z1 + 0.001 then
				if b.z1 > land then
					land = b.z1
				end
			elseif o.vz > 0 and o.z + o.h <= b.z0 + 0.05 and nz + o.h > b.z0 then
				nz = b.z0 - o.h
				o.vz = 0
			end
		end
	end
	if land > -1000 then
		o.z = land
		o.vz = 0
		o.ground = true
	else
		o.z = nz
		o.ground = false
	end
end

-- Highest solid top under (x, y) at or below z (+ a little). -100 = void.
function W.ground_below(x, y, z)
	local best = -100
	local i = 0
	local b = nil
	for i = 1, W.n do
		b = W.b[i]
		if x >= b.x0 and x <= b.x1 and y >= b.y0 and y <= b.y1 then
			if b.z1 <= z + 0.1 and b.z1 > best then
				best = b.z1
			end
		end
	end
	return best
end

function W.inside(x, y, z)
	local i = 0
	local b = nil
	for i = 1, W.n do
		b = W.b[i]
		if x > b.x0 and x < b.x1 and y > b.y0 and y < b.y1 and z > b.z0 and z < b.z1 then
			return true
		end
	end
	return false
end

-- Slab test of one ray against one box. Returns entry t or -1.
function W.ray_box(b, ox, oy, oz, dx, dy, dz)
	local tmin = 0
	local tmax = 100000
	local inv = 0
	local t1 = 0
	local t2 = 0
	local tt = 0
	-- x
	if abs(dx) < 0.000001 then
		if ox < b.x0 or ox > b.x1 then
			return -1
		end
	else
		inv = 1 / dx
		t1 = (b.x0 - ox) * inv
		t2 = (b.x1 - ox) * inv
		if t1 > t2 then
			tt = t1
			t1 = t2
			t2 = tt
		end
		if t1 > tmin then
			tmin = t1
		end
		if t2 < tmax then
			tmax = t2
		end
	end
	-- y
	if abs(dy) < 0.000001 then
		if oy < b.y0 or oy > b.y1 then
			return -1
		end
	else
		inv = 1 / dy
		t1 = (b.y0 - oy) * inv
		t2 = (b.y1 - oy) * inv
		if t1 > t2 then
			tt = t1
			t1 = t2
			t2 = tt
		end
		if t1 > tmin then
			tmin = t1
		end
		if t2 < tmax then
			tmax = t2
		end
	end
	-- z
	if abs(dz) < 0.000001 then
		if oz < b.z0 or oz > b.z1 then
			return -1
		end
	else
		inv = 1 / dz
		t1 = (b.z0 - oz) * inv
		t2 = (b.z1 - oz) * inv
		if t1 > t2 then
			tt = t1
			t1 = t2
			t2 = tt
		end
		if t1 > tmin then
			tmin = t1
		end
		if t2 < tmax then
			tmax = t2
		end
	end
	if tmax < tmin then
		return -1
	end
	return tmin
end

-- Nearest hit distance of a ray (unit dir) against the level, or maxt.
function W.ray(ox, oy, oz, dx, dy, dz, maxt)
	local best = maxt
	local i = 0
	local t = 0
	local b = nil
	for i = 1, W.n do
		b = W.b[i]
		t = W.ray_box(b, ox, oy, oz, dx, dy, dz)
		if t >= 0 and t < best then
			best = t
		end
	end
	return best
end

-- Is the straight line between two points free of level geometry?
function W.clear(ax, ay, az, bx, by, bz)
	local dx = bx - ax
	local dy = by - ay
	local dz = bz - az
	local d = sqrt(dx * dx + dy * dy + dz * dz)
	if d < 0.001 then
		return true
	end
	local ux = dx / d
	local uy = dy / d
	local uz = dz / d
	local t = W.ray(ax, ay, az, ux, uy, uz, d)
	return t >= d - 0.05
end
