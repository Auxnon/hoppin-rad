-- fx — sprite textures, the sky, and a fixed pool of billboard particles
-- (sparks, smoke, bolts). Entities are never killed; idle ones park below.

FX = {}
FX_N = 48
PARK = -500

function tex_disc(name, size, col, rim)
	local img = nimg(size, size)
	img:clr()
	img:rrect(0, 0, size, size, size // 2, rim)
	img:rrect(2, 2, size - 4, size - 4, size // 2 - 2, col)
	tex(name, img)
end

function tex_init()
	tex_disc("spark", 16, "FFE45E", "FF8A2A")
	tex_disc("smoke", 16, "C9C2DE", "8D8799")
	tex_disc("flash", 16, "FFFFFF", "FFE45E")
	-- a heart pickup sprite
	local h = nimg(16, 16)
	h:clr()
	h:rrect(1, 2, 7, 7, 3, "FF3B6B")
	h:rrect(8, 2, 7, 7, 3, "FF3B6B")
	h:rect(3, 6, 10, 4, "FF3B6B")
	h:rect(5, 10, 6, 2, "FF3B6B")
	h:rect(7, 12, 2, 2, "FF3B6B")
	h:rect(3, 3, 2, 2, "FFFFFF")
	tex("heart", h)
end

function sky_init()
	local w = sky.w
	local hgt = sky.h
	local i = 0
	local y = 0
	local bands = 12
	local cols = { "2E5FB8", "3569C2", "3D74CB", "4780D3", "538DDA", "609AE0", "6EA7E5", "7DB4EA", "8DC1EE", "9DCDF1", "AED8F3", "C0E2F5" }
	local bh = hgt / bands
	for i = 1, bands do
		y = flr((i - 1) * bh)
		local hh = flr(bh) + 2
		local c = cols[i]
		sky:rect(0, y, w, hh, c)
	end
	-- a few flat clouds near the horizon
	for i = 1, 9 do
		local cx = rnd(w)
		local cy = rnd(hgt * 0.45, hgt * 0.8)
		local cw = rnd(30, 90)
		local ch = rnd(6, 12)
		sky:rrect(cx, cy, cw, ch, 5, "E6F4FF")
	end
	fog { color = { 0.75, 0.88, 0.96 }, dist = 1500 } -- engine fog units are ~16x world units
	lum { dir = { -0.4, -0.25, -0.85 }, color = { 0.75, 0.72, 0.62 }, ambient = 0.2, sky = { 0.45, 0.55, 0.7 }, ground = { 0.3, 0.27, 0.2 } }
end

function fx_init()
	FX.e = {}
	FX.life = {}
	FX.max = {}
	FX.vx = {}
	FX.vy = {}
	FX.vz = {}
	FX.s = {}
	FX.g = {}
	local i = 0
	for i = 1, FX_N do
		local e = make("spark", 0, 0, PARK, 0.3)
		FX.e[i] = e
		FX.life[i] = 0
		FX.max[i] = 1
		FX.vx[i] = 0
		FX.vy[i] = 0
		FX.vz[i] = 0
		FX.s[i] = 0.3
		FX.g[i] = 0
	end
	FX.next = 1
end

function fx_spawn(name, x, y, z, vx, vy, vz, life, s, g)
	local i = FX.next
	FX.next = i % FX_N + 1
	local e = FX.e[i]
	e.asset = name
	e.x = x
	e.y = y
	e.z = z
	e.scale = s
	FX.life[i] = life
	FX.max[i] = life
	FX.vx[i] = vx
	FX.vy[i] = vy
	FX.vz[i] = vz
	FX.s[i] = s
	FX.g[i] = g
end

function fx_burst(x, y, z, n, speed)
	local i = 0
	for i = 1, n do
		local a = rnd(tau)
		local up = rnd(0.2, 1)
		local sp = rnd(0.4, 1) * speed
		local ca = cos(a)
		local sa = sin(a)
		local lf = rnd(0.3, 0.6)
		local sz = rnd(0.3, 0.55)
		fx_spawn("spark", x, y, z, ca * sp, sa * sp, up * speed, lf, sz, 14)
	end
	for i = 1, 4 do
		local ox = rnd(-0.5, 0.5)
		local oy = rnd(-0.5, 0.5)
		local vz = rnd(1, 2.5)
		local lf = rnd(0.6, 1.0)
		local sz = rnd(0.6, 1.0)
		fx_spawn("smoke", x + ox, y + oy, z, 0, 0, vz, lf, sz, -1)
	end
	fx_spawn("flash", x, y, z, 0, 0, 0, 0.15, 1.6, 0)
end

function fx_puff(x, y, z)
	local i = 0
	for i = 1, 3 do
		local vx = rnd(-1.5, 1.5)
		local vy = rnd(-1.5, 1.5)
		fx_spawn("smoke", x, y, z, vx, vy, 0.6, 0.4, 0.35, 0)
	end
end

function fx_update(dt)
	local i = 0
	local e = nil
	local l = 0
	local k = 0
	for i = 1, FX_N do
		l = FX.life[i]
		if l > 0 then
			l = l - dt
			FX.life[i] = l
			e = FX.e[i]
			if l <= 0 then
				e.z = PARK
			else
				FX.vz[i] = FX.vz[i] - FX.g[i] * dt
				e.x = e.x + FX.vx[i] * dt
				e.y = e.y + FX.vy[i] * dt
				e.z = e.z + FX.vz[i] * dt
				k = l / FX.max[i]
				e.scale = FX.s[i] * (0.4 + 0.6 * k)
			end
		end
	end
end
