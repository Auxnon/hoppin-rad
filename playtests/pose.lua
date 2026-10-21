-- Freeze a few poses for screenshots: airborne dip (t 1-5), then tongue out
-- with the kick foot swung (t 5+).
TT = { t = 0 }
function TEST_HOOK(dt)
	TT.t = TT.t + dt
	G.help_t = 0
	P.inv = 5
	local inp = { fwd = 0, turn = 0, strafe = 0, lx = 0, ly = 0, jump = false, tongue = false, kick = false }
	INPUT_FAKE = inp
	if TT.t > 1 and TT.t < 9 then
		P.x = 2
		P.y = -24
		P.z = 9
		P.vz = -6
		P.ground = false
		P.yaw = tau / 4
		P.pitch = 0
		if TT.t > 8.9 then
			print("dip", P.dip)
		end
	elseif TT.t >= 9 then
		P.x = 0
		P.y = -24
		P.z = 0
		P.yaw = tau / 4 + 0.3
		P.pitch = 0.05
		TG.state = "out"
		TG.target = nil
		TG.maxlen = 20
		TG.len = 7
		TG.dx = cos(P.yaw)
		TG.dy = sin(P.yaw)
		TG.dz = 0.05
		P.kick_t = 0.21
	end
end
