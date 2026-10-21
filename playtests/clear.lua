-- Fetch a cell with the tongue, collect the rest, stand on the exit pad.
TT = { t = 0, step = 0 }
function TEST_HOOK(dt)
	TT.t = TT.t + dt
	G.help_t = 0
	P.inv = 5
	local inp = { fwd = 0, turn = 0, strafe = 0, lx = 0, ly = 0, jump = false, tongue = false, kick = false }
	INPUT_FAKE = inp
	local c = IT.list[4]
	if TT.step == 0 and TT.t > 1 then
		TT.step = 1
		-- stand on T1 looking at the cell on the platform at (18, 2, 9.2)
		P.x = 11
		P.y = 7
		P.z = 6
		local dx = c.x - P.x
		local dy = c.y - P.y
		local dz = c.z - (P.z + EYE)
		P.yaw = atan2(dy, dx)
		local d = sqrt(dx * dx + dy * dy)
		P.pitch = atan2(dz, d)
	elseif TT.step == 1 and TT.t > 1.5 then
		TT.step = 2
		inp.tongue = true
	elseif TT.step == 2 and TT.t > 3 then
		TT.step = 3
		print("cell via tongue", c.got, P.cells, TG.state)
		local i = 0
		for i = 1, 3 do
			local it = IT.list[i]
			item_collect(it)
		end
		print("cells", P.cells, "open", IT.open)
		P.x = EXIT_X
		P.y = EXIT_Y
		P.z = EXIT_Z + 0.5
		P.vx = 0
		P.vy = 0
	elseif TT.step == 3 and TT.t > 4.5 then
		TT.step = 4
		print("clear", G.clear, P.z)
	end
end
