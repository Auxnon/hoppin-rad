-- enemy — the robot bugs.
--
--  grasshopper: kicks you if you're in front of it on the ground, otherwise
--               crouches and leaps in a high arc to land on your head.
--  beetle:      trundles after you, revs, then charges horns-first.
--  gnat:        hovers, lines up, and dives at you.
--
-- Shared states: "reel" (on the tongue), "held" (in front of the frog),
-- "flung" (kicked: a missile until it hits something and blows up).

EN = {}
EN.list = {}
EN.n = 0
EGRAV = 22

function enemy_add(kind, x, y, z)
	local e = {}
	e.kind = kind
	e.x = x
	e.y = y
	e.z = z
	e.hx = x
	e.hy = y
	e.hz = z
	e.vx = 0
	e.vy = 0
	e.vz = 0
	e.yaw = rnd(tau)
	e.ground = false
	e.state = "idle"
	e.t = rnd(0.5, 2)
	e.cd = 0
	e.dead = false
	e.boom = -1
	e.anim = 0
	e.spin = 0
	e.touch_dmg = false
	e.hold_t = 0
	if kind == "gh" then
		e.r = 0.65
		e.h = 1.3
		e.asset = "gh_idle"
	elseif kind == "bt" then
		e.r = 0.85
		e.h = 1.0
		e.asset = "bt_0"
		e.touch_dmg = true
	else
		e.r = 0.55
		e.h = 0.7
		e.asset = "gn_0"
		e.touch_dmg = true
		e.hz = z
	end
	local ent = make(e.asset, x, y, z, 1)
	ent.scale = 1 / MESH_SCALE
	e.ent = ent
	local n = EN.n + 1
	EN.n = n
	EN.list[n] = e
	return e
end

function enemy_spawn_all()
	enemy_add("gh", 6, -10, 0)
	enemy_add("gh", -8, -14, 0)
	enemy_add("gh", 16, 12, 0)
	enemy_add("gh", -20, 18, 0)
	enemy_add("gh", 12, -14, 4)
	enemy_add("gh", 50, 2, 2)
	enemy_add("gh", 58, 6, 2)
	enemy_add("gh", 22, 20, 5)
	enemy_add("bt", -4, -18, 0)
	enemy_add("bt", 20, -4, 0)
	enemy_add("bt", 54, -4, 2)
	enemy_add("gn", 0, 4, 6)
	enemy_add("gn", -14, -2, 17)
	enemy_add("gn", 18, 2, 10)
	enemy_add("gn", 56, 0, 12)
end

function enemy_set_asset(e, name)
	if e.asset ~= name then
		e.asset = name
		local ent = e.ent
		ent.asset = name
	end
end

-- Turn towards an angle at rate rad/s.
function enemy_turn(e, ang, rate, dt)
	local d = ang_diff(e.yaw, ang)
	local s = rate * dt
	if d > s then
		d = s
	elseif d < -s then
		d = -s
	end
	e.yaw = e.yaw + d
end

function enemy_to_player(e)
	local r = {}
	r.dx = P.x - e.x
	r.dy = P.y - e.y
	r.dz = P.z - e.z
	r.d = sqrt(r.dx * r.dx + r.dy * r.dy)
	r.ang = atan2(r.dy, r.dx)
	return r
end

-- ---------------------------------------------------------------- tongue/kick

function enemy_grab(e)
	e.state = "reel"
	e.vx = 0
	e.vy = 0
	e.vz = 0
	local ent = e.ent
	tint(ent, 1, 0.8, 0.9)
end

function enemy_hold(e)
	e.state = "held"
	e.hold_t = 0
end

-- Let go (frog hurt, died, or the bug wriggled free).
function enemy_release(e)
	e.state = "idle"
	e.t = 1
	e.cd = 1
	e.vz = 5
	local ent = e.ent
	tint(ent, 1, 1, 1)
	if P.held == e then
		P.held = nil
	end
end

function enemy_fling(e, vx, vy, vz)
	if P.held == e then
		P.held = nil
	end
	if TG.target == e then
		tongue_reset()
	end
	e.state = "flung"
	e.vx = vx
	e.vy = vy
	e.vz = vz
	e.t = 2.5
	e.yaw = atan2(vy, vx)
	local ent = e.ent
	tint(ent, 1, 0.6, 0.4)
end

function enemy_kill(e, scored)
	if e.dead == true then
		return
	end
	e.dead = true
	e.state = "dead"
	local cz = e.z + e.h * 0.5
	fx_burst(e.x, e.y, cz, 10, 7)
	sfx_boom()
	local ent = e.ent
	ent.z = PARK
	if P.held == e then
		P.held = nil
	end
	if TG.target == e then
		tongue_reset()
	end
	if scored == true then
		P.kills = P.kills + 1
	end
	local roll = rnd()
	if roll < 0.3 then
		item_drop_heart(e.x, e.y, cz)
	end
end

-- A flung bug blows up: it and anything near it.
function enemy_explode(e)
	local x = e.x
	local y = e.y
	local z = e.z
	enemy_kill(e, true)
	local i = 0
	local o = nil
	local d = 0
	for i = 1, EN.n do
		o = EN.list[i]
		if o.dead == false and o.state ~= "held" then
			d = dist3d(x, y, z, o.x, o.y, o.z)
			if d < 3.2 then
				-- chain reaction, a beat later
				if o.boom < 0 then
					o.boom = 0.12
				end
			end
		end
	end
end

-- ---------------------------------------------------------------- per kind

function gh_update(e, dt)
	local tp = enemy_to_player(e)
	if e.state == "idle" then
		enemy_set_asset(e, "gh_idle")
		e.t = e.t - dt
		if e.ground == true then
			e.vx = approach(e.vx, 0, 6, dt)
			e.vy = approach(e.vy, 0, 6, dt)
		end
		if e.t <= 0 and e.ground == true then
			-- little wander hop
			e.yaw = e.yaw + rnd(-1.2, 1.2)
			local cy = cos(e.yaw)
			local sy = sin(e.yaw)
			e.vx = cy * 2.5
			e.vy = sy * 2.5
			e.vz = 6
			e.t = rnd(1.5, 3)
		end
		if tp.d < 16 and abs(tp.dz) < 8 and G.dead == false then
			e.state = "chase"
		end
	elseif e.state == "chase" then
		enemy_turn(e, tp.ang, 5, dt)
		e.cd = e.cd - dt
		if e.ground == true then
			e.vx = approach(e.vx, 0, 8, dt)
			e.vy = approach(e.vy, 0, 8, dt)
			enemy_set_asset(e, "gh_idle")
			local facing = abs(ang_diff(e.yaw, tp.ang))
			if e.cd <= 0 then
				if tp.d < 2.9 and abs(tp.dz) < 1.5 and facing < 0.6 then
					e.state = "windup"
					e.t = 0.45
					sfx_warn()
				elseif tp.d < 15 then
					e.state = "crouch"
					e.t = 0.5
				end
			end
		end
		if tp.d > 24 or G.dead == true then
			e.state = "idle"
		end
	elseif e.state == "windup" then
		enemy_set_asset(e, "gh_kick0")
		enemy_turn(e, tp.ang, 3, dt)
		e.t = e.t - dt
		local ent = e.ent
		local fl = 0.6 + 0.4 * sin(e.t * 60)
		tint(ent, 1, fl, fl)
		if e.t <= 0 then
			e.state = "kick"
			e.t = 0.3
			tint(ent, 1, 1, 1)
			-- the kick lands now if you're still in front
			local cy = cos(e.yaw)
			local sy = sin(e.yaw)
			if tp.d < 3.3 and abs(tp.dz) < 1.7 and tp.d > 0.01 then
				local dot = (tp.dx * cy + tp.dy * sy) / tp.d
				if dot > 0.45 then
					player_hurt(1, cy * 14, sy * 14, 7)
				end
			end
			sfx_whoosh()
		end
	elseif e.state == "kick" then
		enemy_set_asset(e, "gh_kick1")
		e.t = e.t - dt
		if e.t <= 0 then
			e.state = "chase"
			e.cd = rnd(0.9, 1.5)
		end
	elseif e.state == "crouch" then
		enemy_set_asset(e, "gh_crouch")
		enemy_turn(e, tp.ang, 6, dt)
		e.t = e.t - dt
		if e.t <= 0 then
			gh_leap(e, tp)
		end
	elseif e.state == "air" then
		enemy_set_asset(e, "gh_air")
		-- coming down on the frog's head?
		if e.vz < 0 then
			local d = dist2d(e.x, e.y, P.x, P.y)
			if d < e.r + P.r + 0.2 and e.z > P.z + 0.8 and e.z < P.z + P.h + 0.6 then
				local dx = (P.x - e.x) / (d + 0.01)
				local dy = (P.y - e.y) / (d + 0.01)
				if player_hurt(1, dx * 9, dy * 9, -2) then
					G.msg = "SQUASHED!"
					G.msg_t = 1.2
				end
				e.vz = 9
				e.vx = -e.vx * 0.4
				e.vy = -e.vy * 0.4
			end
		end
		if e.ground == true then
			e.state = "land"
			e.t = 0.3
			e.vx = 0
			e.vy = 0
		end
	elseif e.state == "land" then
		enemy_set_asset(e, "gh_crouch")
		e.t = e.t - dt
		if e.t <= 0 then
			e.state = "chase"
			e.cd = rnd(0.6, 1.6)
		end
	end
end

-- Jump in an arc that comes down right where the frog will be.
function gh_leap(e, tp)
	local lead = 0.35
	local tx = P.x + P.vx * lead
	local ty = P.y + P.vy * lead
	local dx = tx - e.x
	local dy = ty - e.y
	local d = sqrt(dx * dx + dy * dy)
	local tt = clamp(d / 8, 0.8, 1.4)
	-- aim to land a touch above the frog's feet so we come down on top
	local dz = P.z + 0.6 - e.z
	e.vx = dx / tt
	e.vy = dy / tt
	e.vz = (dz + 0.5 * EGRAV * tt * tt) / tt
	e.state = "air"
	e.ground = false
	sfx_hop()
end

function bt_update(e, dt)
	local tp = enemy_to_player(e)
	e.anim = e.anim + dt
	local sp = 0
	if e.state == "idle" then
		e.t = e.t - dt
		if e.t <= 0 then
			e.yaw = e.yaw + rnd(-1.5, 1.5)
			e.t = rnd(1.5, 3)
		end
		sp = 1.6
		if tp.d < 14 and abs(tp.dz) < 3 and G.dead == false then
			e.state = "chase"
		end
	elseif e.state == "chase" then
		enemy_turn(e, tp.ang, 2.2, dt)
		sp = 3
		e.cd = e.cd - dt
		local facing = abs(ang_diff(e.yaw, tp.ang))
		if e.cd <= 0 and tp.d < 9 and facing < 0.25 then
			e.state = "rev"
			e.t = 0.6
			sfx_warn()
		end
		if tp.d > 20 or G.dead == true then
			e.state = "idle"
		end
	elseif e.state == "rev" then
		enemy_turn(e, tp.ang, 1.5, dt)
		e.t = e.t - dt
		local ent = e.ent
		local fl = 0.6 + 0.4 * sin(e.t * 50)
		tint(ent, 1, fl, fl)
		sp = 0
		if e.t <= 0 then
			tint(ent, 1, 1, 1)
			e.state = "charge"
			e.t = 1.1
		end
	elseif e.state == "charge" then
		sp = 10
		e.anim = e.anim + dt * 2
		e.t = e.t - dt
		if e.t <= 0 or e.hitwall == true then
			e.state = "chase"
			e.cd = 1.5
		end
	end
	-- don't walk off ledges (unless charging, which is on you)
	local cy = cos(e.yaw)
	local sy = sin(e.yaw)
	if e.ground == true and sp > 0 then
		local ax = e.x + cy * (e.r + 0.4)
		local ay = e.y + sy * (e.r + 0.4)
		local gz = W.ground_below(ax, ay, e.z + 0.3)
		if gz < e.z - 1.2 then
			if e.state == "charge" then
				e.state = "chase"
				e.cd = 1
			end
			e.yaw = e.yaw + pi
			sp = 0
		end
	end
	if e.ground == true then
		e.vx = cy * sp
		e.vy = sy * sp
	end
	local fr = flr(e.anim * 8) % 2
	if fr == 0 then
		enemy_set_asset(e, "bt_0")
	else
		enemy_set_asset(e, "bt_1")
	end
end

-- Gnats fly: no gravity, no level collision beyond staying above ground.
function gn_update(e, dt)
	local tp = enemy_to_player(e)
	e.anim = e.anim + dt
	local fr = flr(e.anim * 20) % 2
	if fr == 0 then
		enemy_set_asset(e, "gn_0")
	else
		enemy_set_asset(e, "gn_1")
	end
	local pz = P.z + 1.0
	local dzp = pz - e.z
	local d3 = sqrt(tp.d * tp.d + dzp * dzp)
	if e.state == "idle" then
		-- lazy circles around home
		e.t = e.t + dt
		local a = e.t * 0.8
		local ca = cos(a)
		local sa = sin(a)
		local tx = e.hx + ca * 3
		local ty = e.hy + sa * 3
		local tz = e.hz + sin(e.t * 2) * 0.4
		e.vx = (tx - e.x) * 2
		e.vy = (ty - e.y) * 2
		e.vz = (tz - e.z) * 2
		local ma = atan2(e.vy, e.vx)
		enemy_turn(e, ma, 4, dt)
		e.cd = e.cd - dt
		if d3 < 13 and e.cd <= 0 and G.dead == false then
			e.state = "aim"
			e.t = 0.7
			sfx_buzz()
		end
	elseif e.state == "aim" then
		enemy_turn(e, tp.ang, 8, dt)
		e.vx = approach(e.vx, 0, 6, dt)
		e.vy = approach(e.vy, 0, 6, dt)
		e.vz = approach(e.vz, 0, 6, dt)
		e.t = e.t - dt
		local ent = e.ent
		local fl = 0.6 + 0.4 * sin(e.t * 50)
		tint(ent, 1, fl, fl)
		if e.t <= 0 then
			tint(ent, 1, 1, 1)
			local s = 11 / (d3 + 0.01)
			e.vx = tp.dx * s
			e.vy = tp.dy * s
			e.vz = dzp * s
			e.state = "dive"
			e.t = 1.2
		end
	elseif e.state == "dive" then
		e.t = e.t - dt
		if e.t <= 0 then
			e.state = "rise"
			e.t = 0
		end
	elseif e.state == "rise" then
		e.vx = (e.hx - e.x) * 0.8
		e.vy = (e.hy - e.y) * 0.8
		e.vz = (e.hz - e.z) * 1.2
		e.t = e.t + dt
		if e.t > 2 then
			e.state = "idle"
			e.t = 0
			e.cd = 1.5
		end
	end
	e.x = e.x + e.vx * dt
	e.y = e.y + e.vy * dt
	e.z = e.z + e.vz * dt
	local gz = W.ground_below(e.x, e.y, e.z + 0.2)
	if e.z < gz + 0.4 then
		e.z = gz + 0.4
		if e.vz < 0 then
			e.vz = 0
		end
	end
	if W.inside(e.x, e.y, e.z + 0.3) then
		e.state = "rise"
		e.t = 0
	end
end

-- ---------------------------------------------------------------- shared

function enemy_flung_update(e, dt)
	e.vz = e.vz - 6 * dt
	local nx = e.x + e.vx * dt
	local ny = e.y + e.vy * dt
	local nz = e.z + e.vz * dt
	e.spin = e.spin + dt * 18
	e.x = nx
	e.y = ny
	e.z = nz
	e.t = e.t - dt
	local cz = e.z + e.h * 0.5
	if W.inside(e.x, e.y, cz) or e.t <= 0 or e.z < KILL_Z then
		enemy_explode(e)
		return
	end
	-- hit another bug?
	local i = 0
	local o = nil
	local d = 0
	for i = 1, EN.n do
		o = EN.list[i]
		if o ~= e and o.dead == false and o.state ~= "held" and o.state ~= "flung" then
			d = dist3d(e.x, e.y, cz, o.x, o.y, o.z + o.h * 0.5)
			if d < e.r + o.r + 0.4 then
				enemy_explode(e)
				return
			end
		end
	end
end

function enemy_held_update(e, dt)
	local v = player_view()
	e.hold_t = e.hold_t + dt
	local w = sin(e.hold_t * 25) * 0.06
	-- dangling low in the view so it doesn't block the aim
	local dn = 1.15 + e.h * 0.5
	e.x = v.ex + v.fx * HOLD_DIST - v.ux * dn + v.rx * w
	e.y = v.ey + v.fy * HOLD_DIST - v.uy * dn + v.ry * w
	e.z = v.ez + v.fz * HOLD_DIST - v.uz * dn
	e.yaw = P.yaw + pi
	-- wriggles free if you hang on too long
	if e.hold_t > 6 then
		enemy_release(e)
		G.msg = "IT GOT LOOSE"
		G.msg_t = 1
	end
end

function enemy_update(dt)
	local i = 0
	local e = nil
	local ent = nil
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false then
			if e.boom >= 0 then
				e.boom = e.boom - dt
				if e.boom < 0 then
					enemy_explode(e)
				end
			end
		end
		if e.dead == false then
			if e.state == "flung" then
				enemy_flung_update(e, dt)
			elseif e.state == "held" then
				enemy_held_update(e, dt)
			elseif e.state == "reel" then
				e.spin = 0
			elseif e.kind == "gn" then
				gn_update(e, dt)
			else
				if e.kind == "gh" then
					gh_update(e, dt)
				else
					bt_update(e, dt)
				end
				e.vz = e.vz - EGRAV * dt
				W.move(e, dt)
				if e.z < KILL_Z then
					enemy_kill(e, true)
				end
			end
		end
		if e.dead == false then
			ent = e.ent
			ent.x = e.x
			ent.y = e.y
			ent.z = e.z
			ent.rz = e.yaw
			ent.rx = e.spin
		end
	end
end

function enemies_left()
	local i = 0
	local n = 0
	local e = nil
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false then
			n = n + 1
		end
	end
	return n
end

-- Put every bug back where it started (restart).
function enemy_reset_all()
	local i = 0
	local e = nil
	local ent = nil
	for i = 1, EN.n do
		e = EN.list[i]
		e.dead = false
		e.x = e.hx
		e.y = e.hy
		e.z = e.hz
		e.vx = 0
		e.vy = 0
		e.vz = 0
		e.state = "idle"
		e.t = 1
		e.cd = 0
		e.boom = -1
		e.spin = 0
		ent = e.ent
		tint(ent, 1, 1, 1)
		ent.rx = 0
	end
end
