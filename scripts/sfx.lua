-- sfx — little synth blips. Channel map: 0 frog, 1 tongue/kick, 2 bugs,
-- 3 booms, 4 pickups/jingles. Without engine audio these are no-ops.

function sfx_init()
	instr(1, "square", { atk = 0.002, dec = 0.08, sus = 0.0, rel = 0.04 })
	instr(2, "tri", { atk = 0.004, dec = 0.15, sus = 0.0, rel = 0.08 })
	instr(3, "noise", { atk = 0.0, dec = 0.25, sus = 0.0, rel = 0.1 })
	instr(4, "pulse", { wid = 0.25, atk = 0.004, dec = 0.1, sus = 0.0, rel = 0.05 })
	instr(5, "saw", { atk = 0.002, dec = 0.12, sus = 0.0, rel = 0.05 })
	fade(0, 0.01, 0.45)
	fade(1, 0.01, 0.4)
	fade(2, 0.01, 0.35)
	fade(3, 0.01, 0.5)
	fade(4, 0.01, 0.45)
end

function sfx_jump(n)
	if n == 1 then
		note(330, 0.06, 0, 4)
		note(495, 0.08, 0, 4)
	else
		note(440, 0.05, 0, 4)
		note(660, 0.05, 0, 4)
		note(990, 0.1, 0, 4)
	end
end

function sfx_land()
	note(90, 0.08, 0, 3)
end

function sfx_hurt()
	note(220, 0.1, 0, 5)
	note(140, 0.18, 0, 5)
end

function sfx_die()
	note(330, 0.15, 0, 5)
	note(220, 0.2, 0, 5)
	note(110, 0.4, 0, 5)
end

function sfx_tongue()
	note(700, 0.05, 1, 2)
	note(1100, 0.05, 1, 2)
end

function sfx_catch()
	note(520, 0.06, 1, 1)
end

function sfx_kick(hit)
	note(160, 0.06, 1, 3)
	if hit == true then
		note(260, 0.08, 1, 1)
	end
end

function sfx_stomp()
	note(392, 0.06, 0, 1)
	note(784, 0.1, 0, 1)
end

function sfx_boom()
	note(70, 0.35, 3, 3)
	note(55, 0.3, 3, 5)
end

function sfx_warn()
	note(880, 0.05, 2, 1)
end

function sfx_whoosh()
	note(300, 0.08, 2, 3)
end

function sfx_hop()
	note(200, 0.06, 2, 2)
	note(300, 0.08, 2, 2)
end

function sfx_buzz()
	note(150, 0.25, 2, 5)
end

function sfx_cell()
	note(523, 0.08, 4, 4)
	note(659, 0.08, 4, 4)
	note(784, 0.08, 4, 4)
	note(1047, 0.2, 4, 4)
end

function sfx_heart()
	note(660, 0.08, 4, 2)
	note(880, 0.12, 4, 2)
end

function sfx_clear()
	note(523, 0.15, 4, 4)
	note(659, 0.15, 4, 4)
	note(784, 0.15, 4, 4)
	note(1047, 0.5, 4, 4)
end
