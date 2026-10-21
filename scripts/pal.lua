-- pal — the shared colour palette.
--
-- One 64x64 "pal" texture holds up to 64 flat swatches (8x8 px each). A face
-- picks its colour by pointing its uv at a swatch's centre; C.<name> is that
-- uv, ready to hand to Mesh.box & friends.

C = {}
PAL_NAMES = {}
PAL_HEX = {}

function pal_add(name, hex)
	local n = #PAL_NAMES + 1
	PAL_NAMES[n] = name
	PAL_HEX[n] = hex
end

function pal_list()
	-- world
	pal_add("chk_a", "8FD16A")
	pal_add("chk_b", "6CB451")
	pal_add("dirt", "8A6A4A")
	pal_add("dirt_dk", "5E4634")
	pal_add("tw_a", "F2E2B6")
	pal_add("tw_b", "D9C08A")
	pal_add("tw_top", "F5A35C")
	pal_add("tw_top2", "7FC6E8")
	pal_add("plat", "C9C2DE")
	pal_add("plat_top", "F4A7B9")
	pal_add("stripe", "3D4C7A")
	pal_add("pad", "FFE45E")
	pal_add("pad_off", "6F6977")
	-- robots
	pal_add("steel", "D5DAE0")
	pal_add("gun", "5A6270")
	pal_add("gun_dk", "343A45")
	pal_add("black", "1E1B22")
	pal_add("red", "FF3B3B")
	pal_add("orange", "FF8A2A")
	pal_add("lime", "B6E34A")
	pal_add("olive", "6E8F2A")
	pal_add("olive_dk", "4A6420")
	pal_add("beetle", "3C7FD9")
	pal_add("beetle_dk", "234B87")
	pal_add("gnat", "B98AE8")
	pal_add("wing", "E6F4FF")
	pal_add("gold", "FFD24A")
	pal_add("gold_dk", "C8961E")
	-- frog
	pal_add("frog", "4FC46A")
	pal_add("frog_dk", "2F8A48")
	pal_add("belly", "E7F5C8")
	pal_add("tongue", "FF6F9C")
	pal_add("tongue_dk", "D9416F")
	pal_add("white", "FBF7EF")
end

-- Builds the "pal" texture and fills C. Called once from main().
function pal_init()
	pal_list()
	local img = nimg(64, 64)
	img:fill("F0F")
	local i = 0
	local row = 0
	local col = 0
	local px = 0
	local py = 0
	local name = ""
	local hex = ""
	for row = 0, 7 do
		for col = 0, 7 do
			i = row * 8 + col + 1
			name = PAL_NAMES[i]
			if name ~= nil then
				hex = PAL_HEX[i]
				px = col * 8
				py = row * 8
				img:rect(px, py, 8, 8, hex)
				local uv = { (px + 4) / 64, (py + 4) / 64 }
				C[name] = uv
			end
		end
	end
	tex("pal", img)
end
