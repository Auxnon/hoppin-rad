-- tongue — the frog's grappling tongue and its kick.
--
-- LMB fires the tongue along the aim (with a little aim assist). If it
-- catches a bug, the bug is reeled in and held in front of you; RMB then
-- kicks it away as a missile that blows up whatever it hits. RMB with
-- nothing held is a short-range kick that launches whatever is in front.
-- The tongue also fetches power cells and hearts.

TG = {}
TONGUE_MAX = 16
TONGUE_OUT = 75
TONGUE_BACK = 90
REEL = 26
HOLD_DIST = 2.6
KICK_SPEED = 30
KICK_RANGE = 2.8
ASSIST = 0.985 -- cos of the aim-assist cone (~10 degrees)

function tongue_init()
	local tip = make("tip", 0, 0, PARK, 1)
	tip.scale = 1 / MESH_SCALE
	TG.ent = tip
	TG.line = nil
	local foot = make("foot", 0, 0, PARK, 1)
	foot.scale = 1 / MESH_SCALE
	TG.foot = foot
	tongue_reset()
end

function tongue_reset()
	TG.state = "idle"
	TG.len = 0
	TG.target = nil
	TG.ttype = ""
	TG.maxlen = TONGUE_MAX
	local tip = TG.ent
	if tip ~= nil then
		tip.z = PARK
	end
	local ln = TG.line
	if ln ~= nil then
		ln.z = PARK
	end
end

function tongue_mouth(v)
	local m = {}
	m.x = v.ex + v.fx * 0.6 - v.ux * 0.55
	m.y = v.ey + v.fy * 0.6 - v.uy * 0.55
	m.z = v.ez + v.fz * 0.6 - v.uz * 0.55
	return m
end

-- Best thing to lick along the aim: a bug, a cell or a heart in the assist
-- cone with a clear line. Returns target, type, distance.
function tongue_pick(v)
	local best = nil
	local btype = ""
	local bd = 0
	local bdot = ASSIST
	local i = 0
	local e = nil
	local dx = 0
	local dy = 0
	local dz = 0
	local d = 0
	local dot = 0
	local cz = 0
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false and e.state ~= "flung" and e.state ~= "held" then
			cz = e.z + e.h * 0.5
			dx = e.x - v.ex
			dy = e.y - v.ey
			dz = cz - v.ez
			d = sqrt(dx * dx + dy * dy + dz * dz)
			if d < TONGUE_MAX and d > 0.5 then
				dot = (dx * v.fx + dy * v.fy + dz * v.fz) / d
				-- bigger bugs are easier to hit up close
				dot = dot + e.r / d * 0.12
				if dot > bdot and W.clear(v.ex, v.ey, v.ez, e.x, e.y, cz) then
					bdot = dot
					best = e
					btype = "bug"
					bd = d
				end
			end
		end
	end
	for i = 1, IT.n do
		e = IT.list[i]
		if e.got == false and e.active == true then
			dx = e.x - v.ex
			dy = e.y - v.ey
			dz = e.z - v.ez
			d = sqrt(dx * dx + dy * dy + dz * dz)
			if d < TONGUE_MAX and d > 0.5 then
				dot = (dx * v.fx + dy * v.fy + dz * v.fz) / d + 0.004
				if dot > bdot and W.clear(v.ex, v.ey, v.ez, e.x, e.y, e.z) then
					bdot = dot
					best = e
					btype = "item"
					bd = d
				end
			end
		end
	end
	local r = {}
	r.t = best
	r.kind = btype
	r.d = bd
	return r
end

function tongue_fire()
	if TG.state ~= "idle" or P.held ~= nil or G.dead == true then
		return
	end
	local v = player_view()
	local pick = tongue_pick(v)
	TG.state = "out"
	TG.len = 0
	TG.target = pick.t
	TG.ttype = pick.kind
	if pick.t ~= nil then
		TG.maxlen = pick.d
	else
		local wall = W.ray(v.ex, v.ey, v.ez, v.fx, v.fy, v.fz, TONGUE_MAX)
		TG.maxlen = wall
	end
	TG.dx = v.fx
	TG.dy = v.fy
	TG.dz = v.fz
	sfx_tongue()
end

-- Where the tip is this frame (world space).
function tongue_tip(v)
	local m = tongue_mouth(v)
	local t = {}
	if TG.state == "reel" and TG.target ~= nil then
		local e = TG.target
		t.x = e.x
		t.y = e.y
		t.z = e.z
		if TG.ttype == "bug" then
			t.z = e.z + e.h * 0.5
		end
		return t
	end
	-- aim the tongue at a moving target while it's still flying out
	local dx = TG.dx
	local dy = TG.dy
	local dz = TG.dz
	if TG.state == "out" and TG.target ~= nil then
		local e = TG.target
		local tz = e.z
		if TG.ttype == "bug" then
			tz = e.z + e.h * 0.5
		end
		dx = e.x - m.x
		dy = e.y - m.y
		dz = tz - m.z
		local d = sqrt(dx * dx + dy * dy + dz * dz)
		if d > 0.001 then
			dx = dx / d
			dy = dy / d
			dz = dz / d
		end
		TG.maxlen = d
		TG.dx = dx
		TG.dy = dy
		TG.dz = dz
	end
	t.x = m.x + dx * TG.len
	t.y = m.y + dy * TG.len
	t.z = m.z + dz * TG.len
	return t
end

function tongue_update(dt)
	local v = player_view()
	if TG.state == "out" then
		if TG.target ~= nil and TG.ttype == "bug" then
			local e = TG.target
			if e.dead == true or e.state == "flung" then
				TG.target = nil
			end
		end
		TG.len = TG.len + TONGUE_OUT * dt
		if TG.len >= TG.maxlen then
			TG.len = TG.maxlen
			if TG.target ~= nil then
				TG.state = "reel"
				if TG.ttype == "bug" then
					enemy_grab(TG.target)
				end
				sfx_catch()
			else
				TG.state = "back"
			end
		end
	elseif TG.state == "back" then
		TG.len = TG.len - TONGUE_BACK * dt
		if TG.len <= 0 then
			tongue_reset()
		end
	elseif TG.state == "reel" then
		tongue_reel(v, dt)
	end
	tongue_draw(v)
	foot_draw(v, dt)
end

-- Pull the caught thing towards the mouth; bugs end up held, items collected.
function tongue_reel(v, dt)
	local e = TG.target
	if e == nil then
		tongue_reset()
		return
	end
	if TG.ttype == "bug" and (e.dead == true or e.state ~= "reel") then
		tongue_reset()
		return
	end
	-- reel to the same spot enemy_held_update keeps a bug at
	local dn = 0.6
	if TG.ttype == "bug" then
		dn = 1.15 + e.h * 0.5
	end
	local hx = v.ex + v.fx * HOLD_DIST - v.ux * dn
	local hy = v.ey + v.fy * HOLD_DIST - v.uy * dn
	local hz = v.ez + v.fz * HOLD_DIST - v.uz * dn
	local cz = e.z
	local dx = hx - e.x
	local dy = hy - e.y
	local dz = hz - cz
	local d = sqrt(dx * dx + dy * dy + dz * dz)
	local step = REEL * dt
	if d <= step + 0.3 then
		if TG.ttype == "bug" then
			enemy_hold(e)
			P.held = e
			sfx_catch()
		else
			item_collect(e)
		end
		tongue_reset()
		return
	end
	e.x = e.x + dx / d * step
	e.y = e.y + dy / d * step
	e.z = e.z + dz / d * step
	local m = tongue_mouth(v)
	TG.len = dist3d(m.x, m.y, m.z, e.x, e.y, cz)
end

function tongue_draw(v)
	if TG.state == "idle" then
		return
	end
	local m = tongue_mouth(v)
	local t = tongue_tip(v)
	local a = { 0, 0, 0 }
	local b = { t.x - m.x, t.y - m.y, t.z - m.z }
	local l = { a, b }
	local lu = { C.tongue }
	local data = { l = l, lw = 0.045, lu = lu, t = "pal", scale = MESH_SCALE }
	mod("tongue", data)
	if TG.line == nil then
		local nl = make("tongue", m.x, m.y, m.z, 1)
		nl.scale = 1 / MESH_SCALE
		TG.line = nl
	end
	local ln = TG.line
	ln.x = m.x
	ln.y = m.y
	ln.z = m.z
	local tip = TG.ent
	tip.x = t.x
	tip.y = t.y
	tip.z = t.z
end

-- Kick: fling the held bug along the aim, or launch whatever is in front.
function player_kick()
	if G.dead == true or P.kick_t > 0.1 then
		return
	end
	P.kick_t = 0.3
	local v = player_view()
	local kx = v.fx
	local ky = v.fy
	local kz = v.fz + 0.08
	if P.held ~= nil then
		local e = P.held
		P.held = nil
		enemy_fling(e, kx * KICK_SPEED, ky * KICK_SPEED, kz * KICK_SPEED)
		sfx_kick(true)
		return
	end
	local i = 0
	local e = nil
	local dx = 0
	local dy = 0
	local dz = 0
	local d = 0
	local hit = false
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false and e.state ~= "flung" then
			dx = e.x - P.x
			dy = e.y - P.y
			dz = e.z + e.h * 0.5 - (P.z + 0.8)
			d = sqrt(dx * dx + dy * dy)
			if d < KICK_RANGE + e.r and abs(dz) < 1.6 and d > 0.001 then
				if (dx * v.fx + dy * v.fy) / d > 0.45 then
					enemy_fling(e, kx * KICK_SPEED * 0.8, ky * KICK_SPEED * 0.8, 5 + kz * KICK_SPEED * 0.5)
					hit = true
				end
			end
		end
	end
	sfx_kick(hit)
end

-- The webbed foot swings out from the bottom of the view on a kick.
function foot_draw(v, dt)
	local f = TG.foot
	if P.kick_t <= 0 then
		f.z = PARK
		return
	end
	local k = P.kick_t / 0.3
	-- out fast, back slower
	local ext = 0
	if k > 0.7 then
		ext = (1 - k) / 0.3
	else
		ext = k / 0.7
	end
	local fwd = 0.6 + ext * 1.2
	local down = 0.9 - ext * 0.45
	local side = 0.25
	f.x = v.ex + v.fx * fwd - v.ux * down + v.rx * side
	f.y = v.ey + v.fy * fwd - v.uy * down + v.ry * side
	f.z = v.ez + v.fz * fwd - v.uz * down
	f.rz = P.yaw
	f.ry = -v.pitch
end
