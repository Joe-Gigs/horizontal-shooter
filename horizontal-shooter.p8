pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--version: 0.1(alpha)
--made by gigs

t=0
--version 0.1.1 roadmap (first public release)

--at least two ships to choose from done
--at least 4(possibly more) levels for the player to explore
--improved ai, more enemy variety 
--new weapons in progress
--a useful purpose for the hide mechanic
--menu system in progress
--work on art style--
-------------------------------------------------------------------------------
--p8 functions
-------------------------------------------------------------------------------
function _init()
	w=128 -- width of the game map
	h=128
	game_state="select"
	freeze_items = false
	--level="mountains"

	ship=make_actor(0, 60)
	--ship.sp=96
	ship.w=2
	ship.h=2
	ship.speed=0.8
	ship.health=100
	ship.score=0
	ship.current_weapon=3
	ship.shielded=false
	ship.hidden=false
	ship.surfing=false
	ship.cw=true
	ship.box={x1=0,y1=0,x2=7,y2=7}

	--camera values
	cx,cy=0,0

	bullets = {}

	charge_shots={}
	enemy_bullets={}

	basic_enemies={}
	mid_enemies={}

	stars = {}

	stars.on=false

	items = {}
	waves={}

	--time of temporary invincibility
	hidden_counter = 0

	actor = {}
	enemies={}

	bgposx=0
	gamespeed=1
	menu={}
	menu.level=0

	cursor = {}
	cursor.sp = 44
	cursor.x = -2
	cursor.y = 40

	spawn_green_eye(100, 60, 36)
	--spawn_zombie_fish(100, 60, 42)

	menuitem(1,"return to menu", function() game_state = "select" end )
end

function _update()
	t=t+1
	update_player()
	alien_movement()
	star_movement()
	ship_hide_countdown()
	camera_level()
	update_world()
	update_items()
	movecursor()
	ship_props()
	menu_input()
	cls()

		-- if #enemies < 2 then
	 --  	make_enemies(5)
	 --  end

		-- if #stars < 19 thens
		-- 	make_stars(10)
		-- end
		
		if game_state == "select" then
			poke(0x5f2c, 3)
			draw_menu()
			freeze_items = true
		elseif game_state == "play" then
			map(screenx, screeny, -bgposx, cy, 32, 32)
			poke(0x5f2c, 0)
			freeze_items = false
		--ship shadow
		pal(1,0)
		shadow=16
		if ship.y >= 70 and ship.y <= 95 then
			ship.surfing=true
			spr(shadow, ship.x-1, ship.y+10)
		elseif ship.y >= 95 then
			ship_waves()	
		else
			ship.surfing=false
		end
	 
		pal()

		spr(ship.sp, ship.sx, ship.sy, ship.w, ship.w)

		for b in all(bullets) do
			spr(b.sp,b.x,b.y)
		end
		for eb in all(enemy_bullets) do
			spr(eb.sp, eb.x, eb.y)
		end
		for e in all(enemies) do
			spr(e.sp, e.x, e.y)
		end
		for s in all(stars) do
			spr(s.sp, s.x, s.y)
		end
		for mid in all(mid_enemies) do
			spr(mid.sp, mid.x, mid.y, 2, 2)
		end
		for i in all(items) do
			spr(i.sp, i.x, i.y)
		end
--scrolling
			bgposx = (bgposx+1)%64
		
		draw_debug()
		draw_player_stats()
		--make_mid_enemies(0)
		mid_ai(green_eye)
	 end
	end

	function update_player()
	local lx=ship.x
	local ly=ship.y
-------------------------------------exhaust animation
	-- if ship.hidden == true then
	-- 			if(t%6<3) then
	-- 				ship.sp=1
	-- 			else
	-- 				ship.sp=2
	-- 			end
	-- 		end
	


	if ship.type=="ship 1" then
		if ship.hidden == true then
			if(t%6<3) then
				ship.sp=1
			else
				ship.sp=2
			end
		else
			if(t%6<3) then
			ship.sp=96
		else
			ship.sp=98
			end
		end
	end

	if ship.type=="ship 2" then
		if ship.hidden == true then
			if(t%6<3) then
				ship.sp=1
			else
				ship.sp=2
			end
		else
			if(t%6<3) then
			ship.sp=64
		else
			ship.sp=66
			end
		end
	end

	
----------------------------------------
		if btn(0) then
			ship.x-=1.5
		end
		if btn(1) then
			ship.x+=1.5
			--shield.x += ship.speed
		end
		if btn(2) then
			ship.y-=1.5

			if ship.hidden==false then
				ship.y-=1.8
			end
		end
		if btn(3) then
			if ship.hidden == false then
				--ship.sp = 100
			end

			ship.y+=1.7

			if ship.hidden==false then
				ship.y+=1.8
			end
		end

		if btnp(4) then
			fire()
		end

		if btnp(5) then
			
			if ship.hidden==false then
				ship.sp=1
				ship.hidden=true
			else
				--hacky af but it will do
				if ship.type=="ship 1" then

					ship.sp=96 
				elseif ship.type=="ship 2" then
					ship.sp=64

				end
				ship.hidden=false
			end
		end

		if ship.hidden == true then
			ship.w = 1
			ship.h=1
		end

		if ship.hidden == false then
			ship.w = 2
			ship.h=2
		end

		if(cmap(ship)) ship.x=lx ship.y=ly

	end

	function update_items()
		if #items == 0 then
	   generate_items(0)
	   generate_items2(0)
		end

		for i in all(items) do
			if coll(i, ship) then
				item_props(i)
				del(items, i)
			end
		end
	end

	function update_world()
		for b in all(bullets) do
		
				b.x-=b.dx
		
			if b.x < 0 or b.x > 128 or
			b.y < 0 or b.y > 128 then
				del(bullets, b)
			end

			--destroy enemies
			for e in all(enemies) do
				if coll(b,e) then
					del(enemies, e)
					ship.score += 1
				end
			end

			for mid in all(mid_enemies) do
				if coll(b,mid) then
					mid.health-=b.dmg
				end
			end
		end --end of bullet loop

		for eb in all(enemy_bullets) do
			eb.x+=eb.dx
			if eb.x < 0 or eb.x > 128 or
			eb.y < 0 or eb.y > 128 then
				del(enemy_bullets, eb)
			end

			if coll(eb,ship) then
				if ship.shielded == false and ship.hidden == false then
					ship.health -=10
				end

				if ship.shielded == true then
					ship.health -=0.2
				end

				if ship.hidden == true then
					ship.health -= 0
				end
			end

			--enemies explode into lasers
			--not sure if i still like this idea
			--update: i dont
			--might still have some use..
			for e in all(enemies) do
				-- if coll(eb,e) then
				-- 	del(enemies, e)
				-- end
			end
		end
		for e in all(enemies) do
			if coll(ship, e) then
				if ship.shielded == false and ship.hidden == false then
					ship.health -=1
				end
			end

			if ship.shielded == true then
				ship.health -=0.2
			end

			if ship.hidden == true then
				ship.health -=0
			end
		end

		for e in all(enemies) do
			if e.x < 0 or e.x > 128 or
			e.y < 0 or e.y > 128 then
				del(enemies, e)
			end
		end

		for s in all(stars) do
			if s.x < 0 or s.x > 128 or
			s.y < 0 or s.y > 128 then
				del(stars, s)
			end
		end
		for i in all(items) do
			if freeze_items == false then
				i.x -= 1 
			end
			if i.x < 0 or i.x > 128 or
			i.y < 0 or i.y > 128 then
				del(items, i)
			end
		end
	end

	function _draw()
		print(ship.sp, 20, 120, 9)
		--print(freeze_items, 20, 30, 9)
		-- print(#enemies, 9, 80, 11)
		-- print(cursor.x, 9, 100, 7)
		-- print(cursor.y, 9, 120, 3)
	end
	-------------------------------------------------------------------------------
	--custom functions
	-------------------------------------------------------------------------------
	--utility functions
	function coin_flip()
		coin=flr(rnd(10))
		if coin<0.5 then
			return "heads"
		else
			return "tails"
		end
	end

 function interval()
		local numb=flr(rnd(100))
		--print(numb, 9, 80, 4)
		if numb % 5 == 1 then
			return true
		end
		if numb % 3 == 2 then
			return false
		end
	end
--
	function draw_debug()
		mem = "mem:"..(flr((stat(0)/256)*32)).."k"
		cpu = "cpu:"..(flr(stat(1)*100)).."%"

		print(cpu,9,25,7)
		print(mem,9,35,7)
	end

	function draw_player_stats()
		print(ship.health,9, 10, 3)
		print(ship.score, 9, 18, 8)
		print(hidden_counter, 9, 45, 8)
	end

	function make_actor(x, y)
		a={}
		a.x = x
		a.y = y
		a.dx = 0
		a.dy = 0
		a.frame = 0
		a.t = 0
		a.inertia = 0.6
		a.bounce  = 1
		a.frames=2

		a.w = 0.4
		a.h = 0.4

		add(actor,a)

		return a
	end

	function render_ship()

	end

	function fire()
		local fire_delay=0

		local b = {
			sp=ship.current_weapon,
			x=ship.x+5,
			y=ship.y+5,
			dx=-3,
			dmg=10,
			box = {x1=2,y1=0,x2=5,y2=4}

		}
		add(bullets,b)

		if ship.current_weapon == 6 then
			animation(6,9)
		end
	 
	end

	function alien_movement()
		foreach(enemies, update_enemies)
		--foreach(mid_enemies, update_mids)
	end

	--not in use, keeping for now

	-- function basic_enemy_fire()
	-- 	for e in all(enemies) do
	-- 		local b = {
	-- 			sp=5,
	-- 			x=e.x,
	-- 			y=e.y,
	-- 			dx=-3,
	-- 			box = {x1=2,y1=0,x2=5,y2=4}
	-- 		}
	-- 		add(enemy_bullets, b)
	-- 	end
	-- end

	function star_movement()
		foreach(stars, update_stars)
	end

	function spawn_basic_enemy()
		alien = make_actor(flr(rnd(64)) + 100, flr(rnd(128)) )
		alien.sp = 4
		alien.tick = rndb(45,60)
		alien.health = 2
		alien.damaged = false
		alien.flip = false
		alien.dead = false
		alien.box = {x1=0,y1=0,x2=7,y2=7}
		alien.alive = true

		add(enemies,alien)
	end


	function spawn_green_eye(x,y,sp)
		green_eye = make_actor(x, y)
		green_eye.sp = sp
		green_eye.tick = rndb(45,60)
		green_eye.health=100
		green_eye.box = {x1=0,y1=0,x2=7,y2=7}
		green_eye.alive = true

		add(mid_enemies, green_eye)
	end

	function spawn_zombie_fish(x,y,sp)
		fish = make_actor(x,y)
		fish.sp=sp
		fish.health=100	
		fish.box={x1=0,y1=0,x2=7,y2=7}

		add(mid_enemies,fish)
	end

	function make_enemies(num)
		for i=0,num do
			spawn_basic_enemy()
		end
	end

	function make_mid_enemies(num)
		for i=0,num do
			spawn_green_eye(100, 60, 36)
		end
	end

	function update_enemies(e)
		e.tick -=1
		e.x -= 1

		if e.tick<=0 then
			if coin_flip() == "heads" then
				enemy_fire(e)
			end
		end
	end

	---custom rng function
	function rndb(l,h)
		return flr(rnd(h-l)+l)
	end

	function create_star()
		star = {}
		star.sp = 50
		star.x = flr(rnd(128)) + 64
		star.y = flr(rnd(128))

		add(stars, star)
	end

	function make_stars(num)
		for i=0,num do
			create_star()
		end
	end

	function update_stars(s)
		s.x -= 2
	end

	function ship_hide_countdown()
		if ship.hidden == true then
			hidden_counter+=1
		end

		if hidden_counter >= 500 then
			ship.hidden = false
			hidden_counter = 0
		end
	end

	function camera_level()

		ship.sx=ship.x%128
		ship.sy=ship.y%128

		--free moving camera, unused

		-- screenx=flr(ship.x/128)*16
		-- screeny=flr(ship.y/128)*16

		--move to other level

			if ship.score >= 50 then
				-- screenx=0
				-- screeny=16
				pal(13,0)
			end

			-- if ship.score >= 100 then
			-- 	screenx=24

			-- 	screeny=0
			-- end

		end

	function make_item(sp,x,y)
		item={}
		item.sp=sp
		item.x=x
		item.y=y
		item.box = {x1=0,y1=0,x2=7,y2=7}

		add(items, item)

		return item
	end

	function generate_items(num)
		for i=0, num do
			make_item(13, flr(rnd(128)), flr(rnd(128)))
		end
	end

	function generate_items2(num)
		for i=0, num do
			make_item(14, flr(rnd(128)), flr(rnd(128)))
		end
	end

	function ship_waves()
		local wave = 18

		if(t%6<3) then
			wave=18
		else
			wave=19
		end
		make_item(wave,ship.x,ship.y+10)
	end

	function item_props(item)
		if item.sp == 13 then
			ship.score+=10
			ship.health += 10
		end
		if item.sp == 14 then
			ship.current_weapon = 6
			ship.score+=50
		end
	end

	function draw_menu()

		rectfill(0, 40, 127, 100, 13)

		menu.sp=201

		menu_right={}
		menu_right.x=30
		menu_right.y=40

		menu_left = {}
		menu_left.x = 0
		menu_left.y = 40

		action=false

		menuposx = cursor.x
		menuposy = cursor.y

		spr(menu.sp, menu_right.x, menu_right.y, 4, 4)
		spr(menu.sp, menu_left.x, menu_left.y, 4, 4)
		spr(cursor.sp,cursor.x,cursor.y)

		if menu.level == 0 then
			print("ship 1", 3, 42, 2)
			print("ship 2",3,48,2)
			print("ship 3", 3, 54, 4)
		end	
		if menu.level == 1 then
			print("are you sure?", 3, 42, 2)
			print("yes", 4, 53, 1)
			print("no", 35, 53, 1)
		end
	end
-------------------------------------------------------------------
	function enemy_fire(enemy)
		local b = {
		sp=5,
		x=enemy.x-4,
		y=enemy.y+4,
		dx=-3,
		box = {x1=2,y1=0,x2=5,y2=4}
		
	}
	add(enemy_bullets, b)
	end

	function mid_ai(e)
		--for m in all(mid_enemies) do
			e.y = ship.y
		local lex = e.x 
		local ley = e.y
			if coin_flip() == "heads"  and e.is_alive == true then
				enemy_fire(e)
			end
			if interval() == true then
				e.y -= 3.5
			end
			if interval() == false then
				e.y += 3.5
			end
			if(cmap(e)) e.x=lex e.y=ley
			
			if e.health == 0 then
				del(mid_enemies, e)
				e.is_alive = false
			end
	end
		--end

		-- function fish_ai()
		-- 	local 
		-- end

		function animation(low,high)
			for b in all(bullets) do
			 if b.sp==high then 
				b.sp=low 
			 else 
				b.sp+=1 
				end
			 end
		end

		function weapon_props()

		end

		function ship_props()
			if ship.sp == 96 then
				ship.type="ship 1"
			end
			if ship.sp == 64 then
				ship.type="ship 2"
			end
		end

		function world_props()

		end

		function movecursor()
			if btnp(1) then
				cls()
				cursor.x=cursor.x + 30
			end
			if btnp(3) then
				cls()
				cursor.y=cursor.y + 6
			end
			if btnp(2) then
				cls()
				cursor.y=cursor.y - 6
			end
			if btnp(0) then
				cls()
				cursor.x=cursor.x - 30
			end
		end

		function menu_input()
			if btnp(4) then
				if menu.level == 0 then
					if menuposx == -2 and menuposy == 40 then
						menu.level=1
						ship.sp=96
					end
					if menuposx == -2 and menuposy == 46 then
						menu.level=1
						ship.sp=64
					end
				end
					--confirm
				if menu.level == 1 then
					if menuposx == -2 and menuposy == 52 then
						game_state = "play"
						menu.level=0
						cursor.x = -2
						cursor.y = 40
					end
					--cancel 
					if menuposx == 28 and menuposy == 52 then
						menu.level = 0
					end
				end
			end
			if btnp(5) then
				menu.level=0
			end
		end

		-- function hidden_timer()
			
		-- end

			----------------------------------------------------
			--collision
			----------------------------------------------------
	function abs_box(s)
		local box = {}
		box.x1 = s.box.x1 + s.x
		box.y1 = s.box.y1 + s.y
		box.x2 = s.box.x2 + s.x
		box.y2 = s.box.y2 + s.y
		return box
	end

	function coll(a, b)
		local box_a = abs_box(a)
		local box_b = abs_box(b)

		if box_a.x1 > box_b.x2 or
		box_a.y1 > box_b.y2 or
		box_b.x1 > box_a.x2	 or
		box_b.y1 > box_a.y2 then
			return false
		end

		return true
	end

	function cmap(entity)
		local ct=false
		local cb=false

		-- if colliding with map tiles
		if(entity.cm) then
			local x1=entity.x/8
			local y1=entity.y/8
			local x2=(entity.x+7)/8
			local y2=(entity.y+7)/8
			local a=fget(mget(x1,y1),0)
			local b=fget(mget(x1,y2),0)
			local c=fget(mget(x2,y2),0)
			local d=fget(mget(x2,y1),0)
			ct=a or b or c or d
		 end
		 -- if colliding world bounds
		 if(entity.cw) then
			 cb=(entity.x<0 or entity.x+8>w or
						 entity.y<0 or entity.y+8>h)
		 end

		return ct or cb
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006600000066000000000000002222000000000000000000000000000000090000000900000000000000000000000000008080000000000000000000
00700700006666000066660000000000006022000000000000000000000090000000900000009000000000000000000000000000088888000000000000000000
00077000a066cc660a66cc66000000000000220000000000000900000009000000090000000909000000000000000000000000000888880000aaaa0000000000
000770000a66cc66a066cc6600bbbb000022220000aaaa00000000000000000000009000000090000000000000000000000000000088800000aaaa0000000000
00700700006666000066660000000000000000000000000000000000000000000000090000000900000000000000000000000000000800000000000000000000
00000000006600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000c000000c007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000700c0c0000c000000000000000000000000000000000000000000000000000000000000000000000000000000cccc000000000000000000
0111100000000000000c70000071c00000000000000000000000000000000000000000000000000000000000000000000000000000cccc000000000000000000
11111111000000000070cc0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000010c000c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000550000000000000000000000000000000000
00000000000000000000000000000000000033300000000000000033300000000000000000000000000000022200d50000000000000000000000000000000000
00000000000000000000000000000000003300233230000000033300323000000000000000000000000000dd2200d50000600000000000000000000000000000
01000000000000000000000000000000033000000003500000330000000350000000000000000000000000d0d0d5d50000760000000000000000000000000000
0111100000000000000000000000000002000dddd0033332023000ddd00333320000000000000000000000ddd0dddd2000775000000000000000000000000000
111111110000000000000000000000000000222ddd05330000000222ddd5330000000000000000000000dd0ddd5dd00000750000000000000000000000000000
0111110000000000000000000000000000022222dd05353000002222ddd535300000000000000000000ddddddd5d5d0000500000000000000000000000000000
01110000000000000000000000000000000e02222d2533330000e0222dd53333000000000000000000de0dd5d25dddd000000000000000000000000000000000
11111111dddddddd0000000000000000000002222d533302020000222dd33302000000000000000000d00d5dd5ddd02000000000000000000000000000000000
11111111dddddddd000000000000000000022222dd53333003302222ddd333300000000000000000000ddd5d55dddd0000000000000000000000000000000000
11111111dddddddd00000000000000000000222ddd05333300300222ddd53333000000000000000000000d55d05dddd000000000000000000000000000000000
11111111dddddddd000700000000000020000dddd0353300003000ddd00533000000000000000000000000ddd25dd02000000000000000000000000000000000
11111111dddddddd000000000000000033000000000532300003000000053230000000000000000000000000005d2d0000000000000000000000000000000000
11111111dddddddd00000000000000000033002333330030000033203333003000000000000000000000000000d0550000000000000000000000000000000000
11111111dddddddd0000000000000000000033500000005000000033000000500000000000000000000000000000d50000000000000000000000000000000000
11111111dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000d50000000000000000000000000000000000
0000000000000000000000000000000000000600000000000000000000000000dddddddddddddd110ddddddddddddddddddddddddddddd110ddddddddddddddd
0000000000000000000000000000000000000150000000000000000000000000ddddddddddddd1111116ddddddddddddddddddddddddd1111116dddddddddddd
00000000000000000000000000000000000ddd55000000000000000000000000dddddddddddd61111111dddddddddddddddddddddddd61111111dddddddddddd
000000000000000000000000000000000000d555555500000000000000000000ddddddd6dddd111111111dddddddddddddddddd6dddd111111111ddddddddddd
0005500000000000000550000000000000000555555555550000000000000000ddddddd1ddd111111111116dddddddddddddddd1ddd111111111116ddddddddd
005cc00000000000005cc0000000000000550555d66660000000000000000000ddddd1116111111111111111ddddddddddddd1116111111111111111dddddddd
0055500000000000005550000000000005555566665000000000000000000000dddd11111111111111111111111ddddddddd11111111111111111111111ddddd
00055000000000000005500000000000996c651ddc7500000000000000000000dd11111111111111111111111111dddddd11111111111111111111111111dddd
00555551ddc5000000555551ddc50000996c651ddc7500000000000000000000111100001111111000001111111116dd11111111177777751111111117777775
55555555555570005555555555557000055555666650000000000000000000001111100011111111000011111111111d11111111176666651111111117666665
0550555666565600055055566656560000550555d666600000000000000000001111000011111110000111111111111117777775176666651777777517666665
00556ddddd65555590956ddddd655555000005555555555500000000000000001111000011111110001111111111111117666665176666651766666517666665
000d566555500000090d5665555000000000d5555555000000000000000000001111000011111110001111111111111117666665155555551766666515555555
00000000000000000000000000000000000ddd550000000000000000000000001111000011111110001111111111111115555555166666651555555516666665
00000000000000000000000000000000000001500000000000000000000000001000000011111010011111111111111119994995156565651666666515656565
00000000000000000000000000000000000006000000000000000000000000001000000011110000111111111111111110404045166666651060606516666665
00000000000000000000000000000000000000000000000000000000000000000001111111110000111111101110000019444445156565651666666515656565
00000000000000000000000000000000006660000000000000000000000000000000011111000000111111100111000010404045166666651060606516666665
06666000000000000666600000000000006666000000000000000000000000000000000111000000111111000111100019444445156565651666666515656565
06c660000000000006c6600000000000005655600000000000000000000000000000000011000000111110000011100010404045166666651060606516666665
06686000000000000668600000000000000665560000000000000000000000000000000011000000111110000011110019444445156565651666666515656565
006665661dd00000006665661dd00000000566666000000000000000000000000000000011000000111100000000110019444445155555551666666515555555
006555661ddc0000006555661ddc000000666666666686600000000000000000000000000000000011110000000000006a4444456555555566dddddd6ddddddd
0006666666666860000666666666686096555651ddc6685600000000000000000000000000000000111000000000000011666ddd666ddd1111666ddd666ddd11
0066666556668866006666655666886696665661ddc668660000000000000000dddddddd1dd1111d1111111111111111dddddddd1dd1111d1111111111111111
0666555665688666966655566568866600666666666686500000000000000000dddddddd1d1111111111111111111111dddddddd1d1111111111111111111111
0665666656886660966566665688666000566666600000000000000000000000dddddddd111111111111111111111111dddddddd111111111111111111111111
00665566500000000066556650000000000665560000000000000000000000001ddddddd11111111dddddd11111111111ddddddd11111111dddddd1111111111
00000000000000000000000000000000000655600000000000000000000000001ddddddd11111111ddddddd1111111111ddddddd11111111ddddddd111111111
00000000000000000000000000000000005666000000000000000000000000001ddd11dd11111111ddddddd1111111111ddd11dd11111111ddddddd111111111
000000000000000000000000000000000066600000000000000000000000000011d111dd11111111dddddddd1111111111d111dd11111111dddddddd11111111
000000000000000000000000000000000000000000000000000000000000000011d1111d11111111dddddddd11111d1111d1111d11111111dddddddd11111d11
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808080800000000000000000000000008080808000000000000000000000000000000000
0000000000000000000010000000210000006d206d2000006d20670a3076693000000a610a6100000a61652020706f6f0000206520650000206565737265612000000010000000210000001000000021006d20670a307669006d20670a307669000a61652020706f000a61652020706f00206565737265610020656573726561
__map__
3131313131313131313131313131313131313131313131314646464696979899969798969798999697989996979899969798990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313131313131313131314646464646a7a8a9a6a7a8a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313131313131313131314646464646b7b8b9b6b7b8b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313131313131313131314646464646b6b786878889868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48494a4b48494a4b48494a4b48494a4b48494a4b48494a4b4646464646868796979899969798999697989996979899969798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58595a5b58595a5b58595a5b58595a5b58595a5b58595a5b46294646999697a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68696a6b68696a6b68696a6b68696a6b68696a6b68696a6b46294646a9a6a7b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78797a7b78797a7b78797a7b78797a7b78797a7b78797a7b46294646b9b6b7b8b9b6b7868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030304629464689868788898687969798999697989996979899969798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303046a7a8a999969798999697a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303046b7b8b9a9a6a7a8a9a6a7b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030304687888687888986878889868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030304615151515151515151515151515151515151515151515159798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
303030303030303030303030303030303030303030303030461515151515151515151515151515151515151515151515a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
303030303030303030303030303030303030303030303030461515151515151515151515151515151515151515151515b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030301515151515151515151515151515151515151515151515158788898686000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000009697989996979899969798999697989996979899969798990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151515151515151515151515151515151515151515151515000000a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151515151515151515151515151515151515151515151515000000b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000008687888986878889868788897616869090900000000086000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0c1c215c0c1c2c3c4c5c6c7c4c5c6c7c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c39798998616868615151515158600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d1d2d3d0d1d2d3d4d5d6d7d4d5d6d7d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3a7a8a98a8b888915151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1e2e31515151515e5e615e415e6e715e11515e01515e315e1e2e3e0e1e2e3e0e1e2e3b7b8b99a9b981515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1f2f3f0f1f2f3f4f5f6f7f4f5f6f7f0f1f2f3f0f1f2f3f0f1f2f3f0f1f2f3f0f1f2f3151515aa15151515ab1515158616861515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000086871696979899571515151515151515151515151586151515868659000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15151515151515151515151515151515151515151515151500000000000066a6a7a8a9161616161616888915158815151515151515161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15151515151515151515151515151515151515151515151500000000000076b6b7b8b916161616161698999a151599151516161616161616160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000000008687161616161616868716a8a9aaaba8a9aaab16161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000000000000000000000000000000b8b9babbb8b9babb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151515151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
