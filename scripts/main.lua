-- Hoppin' Rad — a Jumping Flash style first-person platformer.
--
-- You're a robot frog. Drive with tank controls, aim with the mouse, double
-- jump high into the sky, stomp robot bugs, snag them with your tongue and
-- kick them into each other. Find the four power cells to light the exit
-- pad on top of the spire.
--
-- Built on petrichor64. Its Lua (silt) has a few compiler quirks, so code
-- here hoists call results into locals before passing them on and builds
-- table constructors that hold locals as `local` statements first.

G = {}

function main()
	attr { title = "Hoppin' Rad" }
	pal_init()
	tex_init()
	sky_init()
	models_init()
	W.init()
	fx_init()
	tongue_init()
	player_init()
	enemy_spawn_all()
	items_init()
	sfx_init()
	G.last = now()
	G.t = 0
	G.dead = false
	G.dead_t = 0
	G.clear = false
	G.clear_t = 0
	G.msg = ""
	G.msg_t = 0
	G.help_t = 10
	G.dip_on = true
	G.aim_ok = false
	G.grabbed = true
	G.m1 = false
	G.m2 = false
	G.pad_jump = false
	G.pad_tongue = false
	G.pad_kick = false
	mgrab(true)
end

function draw(w, h)
end

function game_reset()
	tongue_reset()
	player_init()
	enemy_reset_all()
	items_reset()
	G.t = 0
	G.dead = false
	G.clear = false
	G.msg = ""
	G.msg_t = 0
end

-- Fold keyboard, mouse and gamepad into one input record. Tests can supply
-- INPUT_FAKE instead.
function read_input(dt)
	local inp = {}
	inp.fwd = 0
	inp.turn = 0
	inp.strafe = 0
	inp.lx = 0
	inp.ly = 0
	inp.jump = false
	inp.tongue = false
	inp.kick = false
	if key("w") or key("up") then
		inp.fwd = inp.fwd + 1
	end
	if key("s") or key("down") then
		inp.fwd = inp.fwd - 1
	end
	if key("a") or key("left") then
		inp.turn = inp.turn + 1
	end
	if key("d") or key("right") then
		inp.turn = inp.turn - 1
	end
	if key("q") then
		inp.strafe = inp.strafe - 1
	end
	if key("e") then
		inp.strafe = inp.strafe + 1
	end
	if key("space", true) then
		inp.jump = true
	end
	if key("j", true) then
		inp.tongue = true
	end
	if key("k", true) then
		inp.kick = true
	end
	-- mouse
	local m = mus()
	inp.lx = m.dx
	inp.ly = m.dy
	if m.m1 and G.m1 == false then
		inp.tongue = true
	end
	if m.m2 and G.m2 == false then
		inp.kick = true
	end
	G.m1 = m.m1
	G.m2 = m.m2
	-- gamepad: left stick drives/turns, right stick looks
	local ay = abtn("laxisy")
	local ax = abtn("laxisx")
	local rx = abtn("raxisx")
	local ry = abtn("raxisy")
	if abs(ay) > 0.2 then
		inp.fwd = clamp(inp.fwd + ay, -1, 1)
	end
	if abs(ax) > 0.2 then
		inp.turn = clamp(inp.turn - ax, -1, 1)
	end
	if abs(rx) > 0.15 then
		inp.lx = inp.lx + rx * dt * 900
	end
	if abs(ry) > 0.15 then
		inp.ly = inp.ly - ry * dt * 600
	end
	local bj = btn("south")
	if bj and G.pad_jump == false then
		inp.jump = true
	end
	G.pad_jump = bj
	local bt = btn("rbumper") or btn("rtrigger")
	if bt and G.pad_tongue == false then
		inp.tongue = true
	end
	G.pad_tongue = bt
	local bk = btn("west") or btn("lbumper")
	if bk and G.pad_kick == false then
		inp.kick = true
	end
	G.pad_kick = bk
	if INPUT_FAKE ~= nil then
		inp = INPUT_FAKE
	end
	return inp
end

function loop()
	local t = now()
	local dt = t - G.last
	G.last = t
	if dt > 0.05 then
		dt = 0.05
	end
	if dt < 0 then
		dt = 0
	end
	if G.clear == false then
		G.t = G.t + dt
	end
	if G.msg_t > 0 then
		G.msg_t = G.msg_t - dt
	end
	if G.help_t > 0 then
		G.help_t = G.help_t - dt
	end
	if key("c", true) then
		G.dip_on = not G.dip_on
		if G.dip_on then
			G.msg = "CAMERA TILT ON"
		else
			G.msg = "CAMERA TILT OFF"
		end
		G.msg_t = 1.2
	end
	if key("r", true) then
		game_reset()
	end
	local inp = read_input(dt)
	if inp.tongue == true then
		tongue_fire()
	end
	if inp.kick == true then
		player_kick()
	end
	player_update(dt, inp)
	enemy_update(dt)
	items_update(dt)
	player_camera()
	tongue_update(dt)
	fx_update(dt)
	if G.dead == true then
		G.dead_t = G.dead_t - dt
		if G.dead_t <= 0 then
			player_respawn()
		end
	end
	local v = player_view()
	local pick = tongue_pick(v)
	G.aim_ok = pick.t ~= nil and TG.state == "idle" and P.held == nil
	hud_draw()
	if TEST_HOOK ~= nil then
		TEST_HOOK(dt)
	end
end
