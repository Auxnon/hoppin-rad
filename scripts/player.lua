-- player — the robot frog. Tank controls (W/S drive, A/D turn, Q/E strafe)
-- with mouse aim layered on top, a Jumping Flash style double jump, and a
-- camera that tips down while you're airborne (gently: the mouse can always
-- look wherever it likes).

P = {}
EYE = 1.45
SPEED = 8.5
TURN = 2.6
GRAV = 26
JUMP1 = 13
JUMP2 = 18
STOMP_BOUNCE = 16
HP_MAX = 5
SENS = 0.0028
DIP_MAX = 0.42 -- most the airborne tilt will add (radians); JF went to ~1.2

function player_init()
	P.r = 0.45
	P.h = 1.7
	P.hp = HP_MAX
	P.cells = 0
	P.kills = 0
	player_spawn()
end

function player_spawn()
	P.x = 0
	P.y = -20
	P.z = 0
	P.vx = 0
	P.vy = 0
	P.vz = 0
	P.yaw = tau / 4
	P.pitch = 0
	P.dip = 0
	P.ground = true
	P.jumps = 0
	P.coyote = 0
	P.inv = 0
	P.stun = 0
	P.shake = 0
	P.kick_t = 0
	P.held = nil
	P.safe_x = P.x
	P.safe_y = P.y
	P.safe_z = P.z
	P.bob = 0
	P.land_t = 0
	P.hurt_t = 0
end

-- View basis from yaw and the final (dipped) pitch.
function player_view()
	local pitch = clamp(P.pitch + P.dip, -1.5, 1.35)
	local cp = cos(pitch)
	local sp = sin(pitch)
	local cy = cos(P.yaw)
	local sy = sin(P.yaw)
	local v = {}
	v.pitch = pitch
	v.fx = cy * cp
	v.fy = sy * cp
	v.fz = sp
	-- right (horizontal) and up
	v.rx = sy
	v.ry = -cy
	v.ux = -cy * sp
	v.uy = -sy * sp
	v.uz = cp
	v.ex = P.x
	v.ey = P.y
	v.ez = P.z + EYE
	return v
end

function player_jump()
	if G.dead == true then
		return
	end
	if P.ground == true or P.coyote > 0 then
		P.vz = JUMP1
		P.jumps = 1
		P.ground = false
		P.coyote = 0
		sfx_jump(1)
	elseif P.jumps < 2 then
		P.vz = JUMP2
		P.jumps = 2
		sfx_jump(2)
		fx_puff(P.x, P.y, P.z)
	end
end

function player_hurt(n, kx, ky, kz)
	if P.inv > 0 or G.dead == true or G.clear == true then
		return false
	end
	P.hp = P.hp - n
	P.inv = 1.3
	P.stun = 0.35
	P.shake = 0.35
	P.hurt_t = 0.4
	P.vx = kx
	P.vy = ky
	P.vz = kz
	P.ground = false
	sfx_hurt()
	if P.hp <= 0 then
		P.hp = 0
		player_die()
	end
	return true
end

function player_die()
	G.dead = true
	G.dead_t = 2.5
	if P.held ~= nil then
		enemy_release(P.held)
		P.held = nil
	end
	tongue_reset()
	sfx_die()
end

function player_respawn()
	G.dead = false
	player_spawn()
	P.hp = HP_MAX
end

-- Stomp anything we're falling onto, JF style: it pops and we bounce.
function player_stomp_check(dt)
	if P.vz >= 0 then
		return
	end
	local i = 0
	local e = nil
	local top = 0
	local d = 0
	local reach = -P.vz * dt + 0.35
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false and e.state ~= "held" and e.state ~= "flung" then
			top = e.z + e.h
			if P.z <= top + reach and P.z >= top - 0.6 then
				d = dist2d(P.x, P.y, e.x, e.y)
				if d < e.r + P.r + 0.15 then
					enemy_kill(e, true)
					P.vz = STOMP_BOUNCE
					P.jumps = 1
					P.ground = false
					sfx_stomp()
					return
				end
			end
		end
	end
end

-- Keep the frog from standing inside bugs; contact hurts for some kinds.
function player_bug_contact()
	local i = 0
	local e = nil
	local d = 0
	local dx = 0
	local dy = 0
	local mind = 0
	for i = 1, EN.n do
		e = EN.list[i]
		if e.dead == false and e.state ~= "held" and e.state ~= "flung" and e.state ~= "reel" then
			if P.z < e.z + e.h - 0.2 and P.z + P.h > e.z + 0.1 then
				dx = P.x - e.x
				dy = P.y - e.y
				d = sqrt(dx * dx + dy * dy)
				mind = e.r + P.r
				if d < mind and d > 0.001 then
					P.x = P.x + dx / d * (mind - d)
					P.y = P.y + dy / d * (mind - d)
					if e.touch_dmg == true then
						player_hurt(1, dx / d * 10, dy / d * 10, 6)
					end
				end
			end
		end
	end
end

function player_update(dt, inp)
	if P.inv > 0 then
		P.inv = P.inv - dt
	end
	if P.stun > 0 then
		P.stun = P.stun - dt
	end
	if P.shake > 0 then
		P.shake = P.shake - dt
	end
	if P.kick_t > 0 then
		P.kick_t = P.kick_t - dt
	end
	if P.hurt_t > 0 then
		P.hurt_t = P.hurt_t - dt
	end
	if P.land_t > 0 then
		P.land_t = P.land_t - dt
	end
	if G.dead == true or G.clear == true then
		inp.fwd = 0
		inp.turn = 0
		inp.strafe = 0
	end
	-- look: mouse/stick on top of tank turning
	P.yaw = P.yaw + inp.turn * TURN * dt - inp.lx * SENS
	P.pitch = clamp(P.pitch - inp.ly * SENS, -1.4, 1.3)
	if P.yaw > tau then
		P.yaw = P.yaw - tau
	elseif P.yaw < 0 then
		P.yaw = P.yaw + tau
	end
	-- drive
	local cy = cos(P.yaw)
	local sy = sin(P.yaw)
	local tx = (cy * inp.fwd + sy * inp.strafe) * SPEED
	local ty = (sy * inp.fwd - cy * inp.strafe) * SPEED
	local rate = 14
	if P.ground == false then
		rate = 4.5
	end
	if P.stun > 0 then
		rate = 0.5
	end
	P.vx = approach(P.vx, tx, rate, dt)
	P.vy = approach(P.vy, ty, rate, dt)
	if inp.jump == true then
		player_jump()
	end
	-- fall
	P.vz = P.vz - GRAV * dt
	if P.vz < -40 then
		P.vz = -40
	end
	local was_ground = P.ground
	local fall_v = P.vz
	player_stomp_check(dt)
	W.move(P, dt)
	player_bug_contact()
	if P.ground == true then
		P.jumps = 0
		P.coyote = 0.1
		if was_ground == false then
			P.land_t = 0.18
			if fall_v < -18 then
				sfx_land()
				fx_puff(P.x, P.y, P.z)
			end
		end
		P.safe_x = P.x
		P.safe_y = P.y
		P.safe_z = P.z
	elseif P.coyote > 0 then
		P.coyote = P.coyote - dt
	end
	if was_ground == true and P.ground == false and P.vz <= 0 then
		P.jumps = 1
	end
	-- head bob when walking on the ground
	local spd = sqrt(P.vx * P.vx + P.vy * P.vy)
	if P.ground == true and spd > 1 then
		P.bob = P.bob + dt * spd * 1.3
	end
	player_dip_update(dt)
	-- fell into the void: back to the last safe spot, minus a heart
	if P.z < KILL_Z then
		if P.held ~= nil then
			enemy_release(P.held)
			P.held = nil
		end
		tongue_reset()
		P.x = P.safe_x
		P.y = P.safe_y
		P.z = P.safe_z + 0.5
		P.vx = 0
		P.vy = 0
		P.vz = 0
		P.inv = 0
		player_hurt(1, 0, 0, 0)
	end
end

-- The Jumping Flash camera tilt: while airborne, look down towards where
-- you'll land, more the higher you are above the ground. Softer than JF.
function player_dip_update(dt)
	local target = 0
	if P.ground == false and G.dip_on == true then
		local gz = W.ground_below(P.x, P.y, P.z)
		local alt = P.z - gz
		if gz < -50 then
			alt = 12
		end
		local k = clamp((alt - 1.5) / 9, 0, 1)
		target = -DIP_MAX * k
		-- falling deepens it a little, rising eases off
		if P.vz < 0 then
			target = target * 1.15
		else
			target = target * 0.7
		end
	end
	local rate = 2.2
	if P.ground == true then
		rate = 4
	end
	P.dip = approach(P.dip, target, rate, dt)
end

function player_camera()
	local v = player_view()
	local ex = v.ex
	local ey = v.ey
	local ez = v.ez
	if P.ground == true then
		local b = sin(P.bob)
		ez = ez + b * 0.06
	end
	if P.land_t > 0 then
		ez = ez - P.land_t * 0.8
	end
	if P.shake > 0 then
		local s = P.shake * 0.5
		local ox = rnd(-s, s)
		local oz = rnd(-s, s)
		ex = ex + ox
		ez = ez + oz
	end
	G.cx = ex
	G.cy = ey
	G.cz = ez
	local pos = { ex, ey, ez }
	local rot = { P.yaw, v.pitch }
	local c = { pos = pos, rot = rot }
	cam(c)
end
