-- Lick a grasshopper, hold it, kick it into a beetle. Also shows the tongue.
TT = { t = 0, step = 0 }
function tk_inp()
	local i = { fwd = 0, turn = 0, strafe = 0, lx = 0, ly = 0, jump = false, tongue = false, kick = false }
	return i
end
function tk_face(e)
	local dx = e.x - P.x
	local dy = e.y - P.y
	P.yaw = atan2(dy, dx)
	local dz = e.z + e.h * 0.5 - (P.z + EYE)
	local d = sqrt(dx * dx + dy * dy)
	P.pitch = atan2(dz, d)
end
function TEST_HOOK(dt)
	TT.t = TT.t + dt
	G.help_t = 0
	P.inv = 5
	local inp = tk_inp()
	INPUT_FAKE = inp
	local gh = EN.list[1]
	local bt = EN.list[9]
	if TT.step == 0 and TT.t > 1 then
		TT.step = 1
		-- line up: frog, grasshopper at 8 units, beetle beyond
		gh.x = 0
		gh.y = -10
		gh.z = 0
		gh.state = "idle"
		gh.t = 5
		bt.x = 0
		bt.y = 2
		bt.state = "idle"
		P.x = 0
		P.y = -18
		tk_face(gh)
		print("setup", gh.state, P.yaw)
	elseif TT.step == 1 and TT.t > 1.5 then
		TT.step = 2
		gh.t = 5
		tk_face(gh)
		inp.tongue = true
	elseif TT.step == 2 and TT.t > 1.62 then
		TT.step = 3
		print("tongue", TG.state, TG.len, gh.state)
	elseif TT.step == 3 and TT.t > 2.6 then
		TT.step = 4
		print("held?", gh.state, P.held ~= nil)
		tk_face(bt)
	elseif TT.step == 4 and TT.t > 3.5 then
		TT.step = 5
		tk_face(bt)
		inp.kick = true
	elseif TT.step == 5 and TT.t > 3.55 then
		TT.step = 6
		print("kicked", gh.state, gh.vx, gh.vy, gh.vz)
	elseif TT.step == 6 and TT.t > 5 then
		TT.step = 7
		print("result gh", gh.dead, "bt", bt.dead, "kills", P.kills)
	end
end
