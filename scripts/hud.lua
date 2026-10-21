-- hud — crosshair, hearts, cells, altimeter, messages, and the frog's eye
-- rims peeking in at the top corners of the view.

function hud_text(s, x, y, col)
	gui:text(s, x + 1, y + 1, "1E1B22")
	gui:text(s, x, y, col)
end

function hud_center(s, y, col)
	local w = gui.w
	local x = (w - #s * 8) // 2
	hud_text(s, x, y, col)
end

function hud_draw()
	clr()
	local w = gui.w
	local h = gui.h
	local cx = w // 2
	local cy = h // 2
	-- frog eye rims in the top corners
	gui:rrect(-40, -46, 92, 70, 34, "2F8A48")
	gui:rrect(-34, -40, 80, 58, 28, "4FC46A")
	gui:rrect(w - 52, -46, 92, 70, 34, "2F8A48")
	gui:rrect(w - 46, -40, 80, 58, 28, "4FC46A")
	-- crosshair: turns pink when the tongue has something to catch
	local col = "FBF7EF"
	if G.aim_ok == true then
		col = "FF6F9C"
		gui:rect(cx - 7, cy - 7, 3, 1, col)
		gui:rect(cx + 5, cy - 7, 3, 1, col)
		gui:rect(cx - 7, cy + 7, 3, 1, col)
		gui:rect(cx + 5, cy + 7, 3, 1, col)
	end
	if P.held ~= nil then
		col = "FFD24A"
	end
	gui:rect(cx - 5, cy, 4, 1, col)
	gui:rect(cx + 2, cy, 4, 1, col)
	gui:rect(cx, cy - 5, 1, 4, col)
	gui:rect(cx, cy + 2, 1, 4, col)
	-- hearts
	local i = 0
	local x = 0
	for i = 1, HP_MAX do
		x = 8 + (i - 1) * 13
		if i <= P.hp then
			gui:rrect(x, h - 18, 11, 10, 4, "FF3B6B")
			gui:rect(x + 2, h - 16, 2, 2, "FFFFFF")
		else
			gui:rrect(x, h - 18, 11, 10, 4, "4A3F48")
		end
	end
	-- cells
	local cs = "CELL " .. tostring(P.cells)
	cs = cs .. "/4"
	local ccol = "FFD24A"
	if IT.open == true then
		ccol = "8FD16A"
	end
	hud_text(cs, w - 72, h - 18, ccol)
	local ks = "BUGS " .. tostring(P.kills)
	hud_text(ks, w - 72, h - 30, "FBF7EF")
	-- altimeter on the right edge
	local bx = w - 10
	local top = 40
	local bot = h - 50
	gui:rect(bx, top, 3, bot - top, "343A45")
	local gz = W.ground_below(P.x, P.y, P.z)
	local alt = P.z - gz
	if gz < -50 then
		alt = 0
	end
	local k = clamp(alt / 20, 0, 1)
	local my = flr(bot - k * (bot - top))
	gui:rect(bx - 3, my - 1, 9, 3, "FF8A2A")
	local hk = clamp(P.z / 22, 0, 1)
	local hy = flr(bot - hk * (bot - top))
	gui:rect(bx - 2, hy, 7, 1, "7FC6E8")
	-- held bug hint
	if P.held ~= nil then
		hud_center("RMB: KICK IT!", cy + 20, "FFD24A")
	end
	-- messages
	if G.msg_t > 0 then
		hud_center(G.msg, 30, "FFE45E")
	end
	if G.help_t > 0 then
		hud_center("WASD DRIVE  MOUSE AIM  SPACE JUMP X2", h - 58, "FBF7EF")
		hud_center("LMB TONGUE  RMB KICK  C CAM TILT", h - 46, "FBF7EF")
	end
	if P.hurt_t > 0 then
		gui:rect(0, 0, w, 3, "FF3B3B")
		gui:rect(0, h - 3, w, 3, "FF3B3B")
		gui:rect(0, 0, 3, h, "FF3B3B")
		gui:rect(w - 3, 0, 3, h, "FF3B3B")
	end
	if G.dead == true then
		hud_center("SHORT CIRCUITED!", cy - 30, "FF3B3B")
	end
	if G.clear == true then
		hud_center("STAGE CLEAR!", cy - 40, "FFE45E")
		local secs = flr(G.clear_t)
		local ts = "TIME " .. tostring(secs)
		ts = ts .. "S"
		hud_center(ts, cy - 26, "FBF7EF")
		local bs = "BUGS SCRAPPED " .. tostring(P.kills)
		hud_center(bs, cy - 14, "FBF7EF")
		hud_center("PRESS R TO PLAY AGAIN", cy + 30, "8FD16A")
	end
	if G.grabbed == false then
		hud_center("CLICK TO GRAB MOUSE", cy + 40, "FBF7EF")
	end
end
