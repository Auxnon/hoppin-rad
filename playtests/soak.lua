-- Soak: mash random inputs for a minute, hop between bugs, restart once.
-- Any Lua error shows up in the log.
TT = { t = 0, next = 0, tp = 0, reset = false, inp = nil }
function sk_inp()
	local i = { fwd = 0, turn = 0, strafe = 0, lx = 0, ly = 0, jump = false, tongue = false, kick = false }
	return i
end
function TEST_HOOK(dt)
	TT.t = TT.t + dt
	G.help_t = 0
	if TT.inp == nil then
		TT.inp = sk_inp()
	end
	local inp = TT.inp
	inp.jump = false
	inp.tongue = false
	inp.kick = false
	if TT.t > TT.next then
		TT.next = TT.t + rnd(0.2, 0.8)
		inp.fwd = flr(rnd(-1, 2))
		inp.turn = flr(rnd(-1, 2))
		inp.strafe = flr(rnd(-1, 2))
		inp.lx = rnd(-6, 6)
		inp.ly = rnd(-3, 3)
		local r = rnd()
		if r < 0.3 then
			inp.jump = true
		elseif r < 0.55 then
			inp.tongue = true
		elseif r < 0.75 then
			inp.kick = true
		end
	end
	if P.pitch > 0.6 or P.pitch < -0.6 then
		P.pitch = 0
	end
	INPUT_FAKE = inp
	-- every 5s drop the frog next to a live bug and face it
	if TT.t > TT.tp then
		TT.tp = TT.t + 5
		local i = flr(rnd(1, EN.n + 1))
		local e = EN.list[i]
		if e ~= nil and e.dead == false then
			print("tp to", e.kind, flr(e.x), flr(e.y), flr(e.z), e.state)
			P.x = e.x - 6
			P.y = e.y
			P.z = e.z + 0.5
			P.vz = 0
			P.yaw = 0
			P.pitch = 0
		end
		print("t", flr(TT.t), "pos", flr(P.x), flr(P.y), flr(P.z), P.ground, "hp", P.hp, "kills", P.kills, "left", enemies_left(), "tg", TG.state, "dead", G.dead)
	end
	if TT.t > 35 and TT.reset == false then
		TT.reset = true
		game_reset()
		print("reset", enemies_left(), P.cells, P.hp)
	end
end
