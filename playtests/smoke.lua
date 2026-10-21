-- Smoke test: stand, drive forward, jump twice, look around, fire tongue.
TT = { t = 0, step = 0 }
function tt_inp()
	local i = {}
	i.fwd = 0
	i.turn = 0
	i.strafe = 0
	i.lx = 0
	i.ly = 0
	i.jump = false
	i.tongue = false
	i.kick = false
	return i
end
function TEST_HOOK(dt)
	TT.t = TT.t + dt
	G.help_t = 0
	local inp = tt_inp()
	INPUT_FAKE = inp
	if TT.step == 0 and TT.t > 1 then
		TT.step = 1
		print("start", P.x, P.y, P.z, P.ground, EN.n, IT.n)
	elseif TT.step == 1 then
		inp.fwd = 1
		if TT.t > 2.5 then
			TT.step = 2
			print("drove", P.x, P.y, P.z, P.ground)
			inp.jump = true
		end
	elseif TT.step == 2 and TT.t > 2.9 then
		TT.step = 3
		inp.jump = true
		print("jump2 at", P.z, P.vz, P.jumps)
	elseif TT.step == 3 and TT.t > 3.6 then
		TT.step = 4
		print("air", P.z, P.dip, P.ground)
	elseif TT.step == 4 and P.ground == true then
		TT.step = 5
		print("landed", P.x, P.y, P.z, P.hp)
	elseif TT.step == 5 then
		inp.turn = 1
		if TT.t > 7 then
			TT.step = 6
			inp.tongue = true
			print("tongue", TG.state)
		end
	elseif TT.step == 6 and TT.t > 9 then
		TT.step = 7
		print("end", P.x, P.y, P.z, P.hp, P.kills, TG.state, enemies_left())
		local i = 0
		for i = 1, EN.n do
			local e = EN.list[i]
			print("bug", e.kind, e.state, flr(e.x), flr(e.y), flr(e.z), e.dead)
		end
	end
end
