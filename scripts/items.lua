-- items — power cells (collect all four to light the exit), hearts dropped by
-- bugs, and the exit pad on top of the spire.

IT = {}
IT.list = {}
IT.n = 0
CELLS_NEED = 4
EXIT_X = -4
EXIT_Y = 8
EXIT_Z = 20

function item_add(kind, x, y, z, asset)
	local it = {}
	it.kind = kind
	it.x = x
	it.y = y
	it.z = z
	it.bz = z
	it.ox = x
	it.oy = y
	it.oz = z
	it.got = false
	it.active = true
	it.t = rnd(tau)
	local ent = make(asset, x, y, z, 1)
	if kind == "cell" then
		ent.scale = 1 / MESH_SCALE
	else
		ent.scale = 0.6
	end
	it.ent = ent
	local n = IT.n + 1
	IT.n = n
	IT.list[n] = it
	return it
end

function items_init()
	item_add("cell", -14, -12, 11.2, "cell")
	item_add("cell", -12, -1, 16.2, "cell")
	item_add("cell", 60, -6, 6.2, "cell")
	item_add("cell", 18, 2, 9.2, "cell")
	local pad = make("pad_off", EXIT_X, EXIT_Y, EXIT_Z + 0.01, 1)
	pad.scale = 1 / MESH_SCALE
	IT.pad = pad
	IT.open = false
end

-- Hearts reuse spent slots so the list never grows without bound.
function item_drop_heart(x, y, z)
	local i = 0
	local it = nil
	for i = 1, IT.n do
		it = IT.list[i]
		if it.kind == "heart" and it.got == true then
			it.got = false
			it.active = true
			it.x = x
			it.y = y
			it.z = z
			it.bz = z
			it.life = 12
			local ent = it.ent
			ent.x = x
			ent.y = y
			ent.z = z
			return
		end
	end
	local h = item_add("heart", x, y, z, "heart")
	h.life = 12
end

function item_collect(it)
	if it.got == true then
		return
	end
	it.got = true
	local ent = it.ent
	ent.z = PARK
	if it.kind == "cell" then
		P.cells = P.cells + 1
		sfx_cell()
		if P.cells >= CELLS_NEED then
			IT.open = true
			local pad = IT.pad
			pad.asset = "pad_on"
			G.msg = "EXIT OPEN! TOP OF THE SPIRE"
			G.msg_t = 3
		else
			G.msg = "POWER CELL"
			G.msg_t = 1.5
		end
	else
		P.hp = P.hp + 1
		if P.hp > HP_MAX then
			P.hp = HP_MAX
		end
		sfx_heart()
	end
end

function items_update(dt)
	local i = 0
	local it = nil
	local ent = nil
	local d = 0
	for i = 1, IT.n do
		it = IT.list[i]
		if it.got == false then
			it.t = it.t + dt
			ent = it.ent
			if it.kind == "heart" then
				-- hearts fall to the ground, then wait
				local gz = W.ground_below(it.x, it.y, it.bz)
				if it.bz > gz + 0.5 then
					it.bz = it.bz - 6 * dt
				end
				it.life = it.life - dt
				if it.life <= 0 then
					it.got = true
					ent.z = PARK
				end
			end
			if TG.target ~= it then
				local b = sin(it.t * 2.5)
				it.z = it.bz + b * 0.2
			end
			ent.x = it.x
			ent.y = it.y
			ent.z = it.z
			ent.rz = it.t * 1.5
			if it.got == false then
				d = dist3d(P.x, P.y, P.z + 0.8, it.x, it.y, it.z)
				if d < 1.4 then
					item_collect(it)
				end
			end
		end
	end
	-- the exit
	if IT.open == true and G.clear == false then
		local pad = IT.pad
		pad.rz = G.t * 2
		d = dist2d(P.x, P.y, EXIT_X, EXIT_Y)
		if d < 1.4 and P.ground == true and abs(P.z - EXIT_Z) < 0.3 then
			G.clear = true
			G.clear_t = G.t
			sfx_clear()
		end
	end
end

function items_reset()
	local i = 0
	local it = nil
	local ent = nil
	for i = 1, IT.n do
		it = IT.list[i]
		if it.kind == "cell" then
			it.got = false
			it.x = it.ox
			it.y = it.oy
			it.bz = it.oz
			it.z = it.oz
		else
			it.got = true
			ent = it.ent
			ent.z = PARK
		end
	end
	IT.open = false
	local pad = IT.pad
	pad.asset = "pad_off"
end
