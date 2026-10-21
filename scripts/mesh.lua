-- mesh — a tiny builder over mod()'s polygon form (from Roomer).
--
-- A mesh is a point list `p`, a face list `f` (1-based point indices) and one
-- palette uv per face `fu`. Everything is authored in world-ish units and
-- packed with scale = MESH_SCALE, then shown on an entity scaled back down by
-- 1/MESH_SCALE, which keeps small details (eyes, knobs) from snapping to the
-- engine's 1/16-unit vertex grid.
--
-- silt notes: table constructors that hold locals are only ever written as a
-- `local x = {...}` statement and then stored, and call results are hoisted
-- into locals before being passed on (see petrichor64's SILT-BUGS.md).

MESH_SCALE = 4
Mesh = {}

function Mesh.new()
	local m = {}
	local p = {}
	local f = {}
	local fu = {}
	m.p = p
	m.f = f
	m.fu = fu
	m.np = 0
	m.nf = 0
	m.tf = 0
	m.ox = 0
	m.oy = 0
	m.oz = 0
	m.rot = 0
	return m
end

-- Optional transform applied to every point added: rotate m.rot quarter
-- turns about z, then offset by (ox, oy, oz). tf == 1 additionally lays the
-- mesh on its back (front +x becomes up, up becomes +y) for the sleeping pose.
function Mesh.pt(m, x, y, z)
	local tx = x
	local ty = y
	local tz = z
	if m.tf == 1 then
		tx = y
		ty = z
		tz = x
	end
	local r = m.rot
	local ax = tx
	if r == 1 then
		tx = -ty
		ty = ax
	elseif r == 2 then
		tx = -tx
		ty = -ty
	elseif r == 3 then
		tx = ty
		ty = -ax
	end
	local v = { tx + m.ox, ty + m.oy, tz + m.oz }
	local n = m.np + 1
	m.np = n
	m.p[n] = v
	return n
end

function Mesh.face4(m, a, b, c, d, uv)
	local f = { a, b, c, d }
	local n = m.nf + 1
	m.nf = n
	m.f[n] = f
	m.fu[n] = uv
end

function Mesh.face3(m, a, b, c, uv)
	local f = { a, b, c }
	local n = m.nf + 1
	m.nf = n
	m.f[n] = f
	m.fu[n] = uv
end

function Mesh.facen(m, list, uv)
	local n = m.nf + 1
	m.nf = n
	m.f[n] = list
	m.fu[n] = uv
end

-- Axis-aligned box with a colour per face: top, south(-y), east(+x),
-- north(+y), west(-x), bottom.
function Mesh.box6(m, x0, y0, z0, x1, y1, z1, ct, cs, ce, cn, cw, cb)
	local p1 = Mesh.pt(m, x0, y0, z0)
	local p2 = Mesh.pt(m, x1, y0, z0)
	local p3 = Mesh.pt(m, x1, y1, z0)
	local p4 = Mesh.pt(m, x0, y1, z0)
	local p5 = Mesh.pt(m, x0, y0, z1)
	local p6 = Mesh.pt(m, x1, y0, z1)
	local p7 = Mesh.pt(m, x1, y1, z1)
	local p8 = Mesh.pt(m, x0, y1, z1)
	Mesh.face4(m, p5, p6, p7, p8, ct)
	Mesh.face4(m, p1, p2, p6, p5, cs)
	Mesh.face4(m, p2, p3, p7, p6, ce)
	Mesh.face4(m, p3, p4, p8, p7, cn)
	Mesh.face4(m, p4, p1, p5, p8, cw)
	Mesh.face4(m, p1, p4, p3, p2, cb)
end

function Mesh.box(m, x0, y0, z0, x1, y1, z1, c)
	Mesh.box6(m, x0, y0, z0, x1, y1, z1, c, c, c, c, c, c)
end

-- Box with a different top colour (cushions, counters, table tops).
function Mesh.boxt(m, x0, y0, z0, x1, y1, z1, c, ctop)
	Mesh.box6(m, x0, y0, z0, x1, y1, z1, ctop, c, c, c, c, c)
end

-- A box by centre and half sizes, handy for legs and little parts.
function Mesh.cbox(m, cx, cy, z0, hx, hy, z1, c)
	local x0 = cx - hx
	local x1 = cx + hx
	local y0 = cy - hy
	local y1 = cy + hy
	Mesh.box6(m, x0, y0, z0, x1, y1, z1, c, c, c, c, c, c)
end

-- n-sided frustum around (cx, cy): bottom radius r0 at z0, top radius r1 at
-- z1. r1 = 0 makes a cone. Used for pots, lamps, teapots and tree tops.
function Mesh.cyl(m, cx, cy, z0, z1, r0, r1, n, cside, ctop, cbot)
	local bot = {}
	local top = {}
	local i = 0
	local a = 0
	local ca = 0
	local sa = 0
	local x = 0
	local y = 0
	for i = 1, n do
		a = (i - 1) / n * tau + tau / (n * 2)
		ca = cos(a)
		sa = sin(a)
		x = cx + ca * r0
		y = cy + sa * r0
		bot[i] = Mesh.pt(m, x, y, z0)
		x = cx + ca * r1
		y = cy + sa * r1
		top[i] = Mesh.pt(m, x, y, z1)
	end
	local j = 0
	for i = 1, n do
		j = i % n + 1
		Mesh.face4(m, bot[i], bot[j], top[j], top[i], cside)
	end
	if r1 > 0 then
		local capt = {}
		for i = 1, n do
			capt[i] = top[i]
		end
		Mesh.facen(m, capt, ctop)
	end
	local capb = {}
	for i = 1, n do
		capb[i] = bot[n - i + 1]
	end
	Mesh.facen(m, capb, cbot)
end

-- A rounded blob: an n-gon prism whose top and bottom are bevelled in, so a
-- box reads as soft (heads, cushions, the cat's body).
function Mesh.blob(m, cx, cy, z0, z1, r, bev, n, c)
	local za = z0 + bev
	local zb = z1 - bev
	local ri = r - bev
	Mesh.cyl(m, cx, cy, z0, za, ri, r, n, c, c, c)
	Mesh.cyl(m, cx, cy, za, zb, r, r, n, c, c, c)
	Mesh.cyl(m, cx, cy, zb, z1, r, ri, n, c, c, c)
end

-- A flat horizontal quad (rugs, decals, screen faces lie in other planes via
-- Mesh.vquad below).
function Mesh.flat(m, x0, y0, x1, y1, z, c)
	local p1 = Mesh.pt(m, x0, y0, z)
	local p2 = Mesh.pt(m, x1, y0, z)
	local p3 = Mesh.pt(m, x1, y1, z)
	local p4 = Mesh.pt(m, x0, y1, z)
	Mesh.face4(m, p1, p2, p3, p4, c)
end

-- A vertical quad facing -y (towards the camera) at y.
function Mesh.vquad(m, x0, x1, y, z0, z1, c)
	local p1 = Mesh.pt(m, x0, y, z0)
	local p2 = Mesh.pt(m, x1, y, z0)
	local p3 = Mesh.pt(m, x1, y, z1)
	local p4 = Mesh.pt(m, x0, y, z1)
	Mesh.face4(m, p1, p2, p3, p4, c)
end

-- A flat n-gon disc (round rugs, plates, saucers).
function Mesh.disc(m, cx, cy, z, r, n, c)
	local list = {}
	local i = 0
	local a = 0
	local x = 0
	local y = 0
	local ca = 0
	local sa = 0
	for i = 1, n do
		a = (i - 1) / n * tau
		ca = cos(a)
		sa = sin(a)
		x = cx + ca * r
		y = cy + sa * r
		list[i] = Mesh.pt(m, x, y, z)
	end
	Mesh.facen(m, list, c)
end

function Mesh.finish(m, name)
	local d = { p = m.p, f = m.f, fu = m.fu, t = "pal", scale = MESH_SCALE }
	mod(name, d)
end

-- Makes an entity for a mesh authored in world coordinates (origin at 0,0,0).
function Mesh.place(name)
	local e = make(name, 0, 0, 0, 1)
	e.scale = 1 / MESH_SCALE
	return e
end

-- Makes an entity for a mesh authored around its own origin, put at x,y,z.
function Mesh.spawn(name, x, y, z)
	local e = make(name, x, y, z, 1)
	e.scale = 1 / MESH_SCALE
	return e
end

-- A square beam from (ax,ay,az) to (bx,by,bz), w thick. Used for robot legs,
-- antennae and anything that has to sit at an angle. The cross-section axes
-- (u, v) and the beam direction d form a right-handed basis, so the faces
-- come out wound the same way as box6's.
function Mesh.beam(m, ax, ay, az, bx, by, bz, w, c)
	local dx = bx - ax
	local dy = by - ay
	local dz = bz - az
	local dl = sqrt(dx * dx + dy * dy + dz * dz)
	if dl < 0.0001 then
		return
	end
	dx = dx / dl
	dy = dy / dl
	dz = dz / dl
	-- u = d x up (or d x +x when the beam is vertical)
	local ux = dy
	local uy = -dx
	local uz = 0
	if abs(dz) > 0.95 then
		ux = 0
		uy = dz
		uz = -dy
	end
	local ul = sqrt(ux * ux + uy * uy + uz * uz)
	local h = w * 0.5
	ux = ux / ul * h
	uy = uy / ul * h
	uz = uz / ul * h
	-- v = d x u
	local vx = dy * uz - dz * uy
	local vy = dz * ux - dx * uz
	local vz = dx * uy - dy * ux
	local p1 = Mesh.pt(m, ax - ux - vx, ay - uy - vy, az - uz - vz)
	local p2 = Mesh.pt(m, ax + ux - vx, ay + uy - vy, az + uz - vz)
	local p3 = Mesh.pt(m, ax + ux + vx, ay + uy + vy, az + uz + vz)
	local p4 = Mesh.pt(m, ax - ux + vx, ay - uy + vy, az - uz + vz)
	local p5 = Mesh.pt(m, bx - ux - vx, by - uy - vy, bz - uz - vz)
	local p6 = Mesh.pt(m, bx + ux - vx, by + uy - vy, bz + uz - vz)
	local p7 = Mesh.pt(m, bx + ux + vx, by + uy + vy, bz + uz + vz)
	local p8 = Mesh.pt(m, bx - ux + vx, by - uy + vy, bz - uz + vz)
	Mesh.face4(m, p5, p6, p7, p8, c)
	Mesh.face4(m, p1, p2, p6, p5, c)
	Mesh.face4(m, p2, p3, p7, p6, c)
	Mesh.face4(m, p3, p4, p8, p7, c)
	Mesh.face4(m, p4, p1, p5, p8, c)
	Mesh.face4(m, p1, p4, p3, p2, c)
end
