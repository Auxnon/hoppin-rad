-- models — every robot, pickup and prop, built in code from palette boxes.
-- Bugs face +x with their feet at the origin, so ent.rz = yaw turns them.

-- Grasshopper poses. The big hind legs carry the pose: knee and foot
-- positions for the left leg (y mirrored for the right), plus how far the
-- whole body is lowered (crouching) or tipped back (rearing to kick).
function gh_pose(name, kx, kz, fx, fz, drop)
	local m = Mesh.new()
	m.oz = -drop
	local s = 0
	local y = 0
	-- body: thorax, abdomen, head
	Mesh.box(m, -0.45, -0.26, 0.6, 0.3, 0.26, 1.0, C.olive)
	Mesh.beam(m, -0.35, 0, 0.8, -1.25, 0, 0.62, 0.48, C.lime)
	Mesh.beam(m, -1.0, 0, 0.72, -1.1, 0, 0.7, 0.52, C.olive_dk)
	Mesh.box6(m, 0.3, -0.24, 0.72, 0.78, 0.24, 1.18, C.lime, C.lime, C.gun_dk, C.lime, C.lime, C.olive)
	-- visor eyes and mandibles
	Mesh.box(m, 0.62, -0.28, 0.95, 0.8, -0.1, 1.12, C.red)
	Mesh.box(m, 0.62, 0.1, 0.95, 0.8, 0.28, 1.12, C.red)
	Mesh.box(m, 0.7, -0.12, 0.66, 0.86, 0.12, 0.76, C.gun)
	for s = -1, 1, 2 do
		y = s * 0.12
		-- antennae
		Mesh.beam(m, 0.6, y, 1.16, 1.0, s * 0.4, 1.75, 0.06, C.gun)
		Mesh.box(m, 0.95, s * 0.4 - 0.06, 1.7, 1.07, s * 0.4 + 0.06, 1.82, C.orange)
		-- front and middle legs
		Mesh.beam(m, 0.15, s * 0.24, 0.65, 0.35, s * 0.5, 0.4, 0.09, C.gun)
		Mesh.beam(m, 0.35, s * 0.5, 0.4, 0.5, s * 0.5, drop, 0.08, C.steel)
		Mesh.beam(m, -0.25, s * 0.24, 0.65, -0.25, s * 0.55, 0.4, 0.09, C.gun)
		Mesh.beam(m, -0.25, s * 0.55, 0.4, -0.35, s * 0.55, drop, 0.08, C.steel)
		-- the big hind leg: thigh up to the knee, shin down to the foot
		Mesh.beam(m, -0.35, s * 0.3, 0.8, kx, s * 0.42, kz, 0.2, C.olive_dk)
		Mesh.beam(m, kx, s * 0.42, kz, fx, s * 0.44, fz, 0.1, C.steel)
		Mesh.box(m, kx - 0.09, s * 0.42 - 0.09, kz - 0.09, kx + 0.09, s * 0.42 + 0.09, kz + 0.09, C.orange)
		Mesh.box(m, fx - 0.14, s * 0.44 - 0.08, fz - 0.03, fx + 0.14, s * 0.44 + 0.08, fz + 0.06, C.gun_dk)
	end
	Mesh.finish(m, name)
end

function gh_models()
	gh_pose("gh_idle", -0.85, 1.35, -1.1, 0.0, 0)
	gh_pose("gh_crouch", -0.75, 1.5, -0.85, 0.0, 0.28)
	gh_pose("gh_air", -1.15, 0.85, -1.95, 0.35, 0)
	-- kick: the hind legs swing forward under the body
	gh_pose("gh_kick0", -0.1, 1.3, -0.55, 0.35, 0.1)
	gh_pose("gh_kick1", 0.5, 1.0, 1.55, 0.85, 0)
end

function beetle_models()
	local name = ""
	local k = 0
	local s = 0
	local lx = 0
	local ph = 0
	for k = 0, 1 do
		name = "bt_" .. tostring(k)
		local m = Mesh.new()
		-- shell (two halves with a seam), head, horn
		Mesh.blob(m, -0.05, 0, 0.18, 0.95, 0.72, 0.2, 8, C.beetle)
		Mesh.box(m, -0.75, -0.04, 0.9, 0.55, 0.04, 0.97, C.beetle_dk)
		Mesh.box6(m, 0.55, -0.3, 0.25, 0.95, 0.3, 0.7, C.gun_dk, C.gun_dk, C.gun, C.gun_dk, C.gun_dk, C.gun_dk)
		Mesh.box(m, 0.9, -0.26, 0.48, 0.98, -0.1, 0.62, C.red)
		Mesh.box(m, 0.9, 0.1, 0.48, 0.98, 0.26, 0.62, C.red)
		Mesh.beam(m, 0.85, 0, 0.55, 1.35, 0, 1.05, 0.14, C.steel)
		Mesh.box(m, 1.28, -0.08, 0.98, 1.42, 0.08, 1.12, C.orange)
		for s = -1, 1, 2 do
			for lx = -1, 1 do
				ph = (lx + k) % 2 * 0.18
				Mesh.beam(m, lx * 0.4, s * 0.55, 0.35, lx * 0.45 + ph, s * 0.95, 0.2, 0.09, C.gun)
				Mesh.beam(m, lx * 0.45 + ph, s * 0.95, 0.2, lx * 0.5 + ph, s * 1.0, 0, 0.08, C.steel)
			end
		end
		Mesh.finish(m, name)
	end
end

function gnat_models()
	local name = ""
	local k = 0
	local s = 0
	local wz = 0
	for k = 0, 1 do
		name = "gn_" .. tostring(k)
		wz = 0.35
		if k == 1 then
			wz = -0.1
		end
		local m = Mesh.new()
		Mesh.blob(m, 0, 0, -0.3, 0.3, 0.38, 0.12, 6, C.gnat)
		Mesh.beam(m, -0.2, 0, 0.0, -0.9, 0, -0.2, 0.32, C.gun)
		Mesh.box(m, 0.25, -0.22, 0.0, 0.45, -0.06, 0.18, C.red)
		Mesh.box(m, 0.25, 0.06, 0.0, 0.45, 0.22, 0.18, C.red)
		Mesh.beam(m, 0.35, 0, -0.1, 1.05, 0, -0.35, 0.06, C.orange)
		for s = -1, 1, 2 do
			-- wings: thin slabs that flap between two poses
			Mesh.beam(m, -0.05, s * 0.25, 0.2, -0.25, s * 1.1, 0.2 + wz, 0.05, C.wing)
			Mesh.beam(m, -0.25, s * 0.25, 0.2, -0.55, s * 0.95, 0.15 + wz, 0.04, C.wing)
		end
		Mesh.finish(m, name)
	end
end

function item_models()
	-- power cell: a fat battery with steel caps
	local m = Mesh.new()
	Mesh.cyl(m, 0, 0, -0.45, 0.45, 0.32, 0.32, 8, C.gold, C.gold, C.gold)
	Mesh.cyl(m, 0, 0, 0.45, 0.6, 0.2, 0.2, 8, C.steel, C.steel, C.steel)
	Mesh.cyl(m, 0, 0, -0.6, -0.45, 0.33, 0.33, 8, C.gun, C.gun, C.gun)
	Mesh.box(m, 0.25, -0.1, -0.2, 0.35, 0.1, 0.25, C.gold_dk)
	Mesh.finish(m, "cell")
	-- exit pad, unlit and lit
	local k = 0
	local c = C.pad_off
	local name = "pad_off"
	for k = 0, 1 do
		if k == 1 then
			c = C.pad
			name = "pad_on"
		end
		local p = Mesh.new()
		Mesh.cyl(p, 0, 0, 0, 0.2, 1.3, 1.2, 10, C.gun, c, C.gun)
		Mesh.cyl(p, 0, 0, 0.2, 0.3, 0.6, 0.5, 10, C.white, C.stripe, C.white)
		Mesh.finish(p, name)
	end
	-- tongue tip
	local t = Mesh.new()
	Mesh.blob(t, 0, 0, -0.16, 0.16, 0.18, 0.06, 6, C.tongue)
	Mesh.finish(t, "tip")
	-- the frog's kicking foot (viewmodel): shin plus three webbed toes, +x out
	local f = Mesh.new()
	Mesh.beam(f, -0.9, 0, 0, 0, 0, 0, 0.26, C.frog_dk)
	Mesh.box(f, -0.05, -0.28, -0.08, 0.25, 0.28, 0.08, C.frog)
	Mesh.beam(f, 0.2, 0, 0, 0.75, 0, 0, 0.12, C.frog)
	Mesh.beam(f, 0.2, -0.15, 0, 0.65, -0.45, 0, 0.12, C.frog)
	Mesh.beam(f, 0.2, 0.15, 0, 0.65, 0.45, 0, 0.12, C.frog)
	Mesh.box(f, 0.7, -0.08, -0.08, 0.85, 0.08, 0.08, C.belly)
	Mesh.box(f, 0.6, -0.55, -0.08, 0.75, -0.4, 0.08, C.belly)
	Mesh.box(f, 0.6, 0.4, -0.08, 0.75, 0.55, 0.08, C.belly)
	Mesh.finish(f, "foot")
end

function models_init()
	gh_models()
	beetle_models()
	gnat_models()
	item_models()
end
