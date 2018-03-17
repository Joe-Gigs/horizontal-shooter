pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--version: 0.1(alpha)
--made by gigs

t=0
--Version 0.1.1 Roadmap (First public release)

--At least two ships to choose from
--At least 4(possibly more) levels for the player to explore
--improved ai, more enemy variety 
--New weapons
--A useful purpose for the hide mechanic
--Menu system
-------------------------------------------------------------------------------
--p8 functions
-------------------------------------------------------------------------------
function _init()
	w=128 -- width of the game map
	h=128
	game_state="select"
	level="mountains"

	ship=make_actor(0, 60)
	ship.sp=96
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
	cursor.x = 0
	cursor.y = 40

	--anim_playing=false

	button=btn(4)

	--spawn_midlevel_enemy(100, 60, 36)
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
	cls()
	ship_props()

	-- if #enemies < 2 then
	--   	make_enemies(5)
	--   end

		-- if #stars < 19 thens
		-- 	make_stars(10)
		-- end
		
		if game_state == "select" then
			poke(0x5f2c, 3)
			draw_menu()
		else
			map(screenx, screeny, -bgposx, cy, 32, 32)

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
		--make_mids(0)
		mid_ai()
	 end
	end

	function update_player()
	local lx=ship.x
	local ly=ship.y

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
				ship.sp = 100
			end

			ship.y+=1.7

			if ship.hidden==false then
				ship.y+=1.8
			end

			-- if ship.surfing==true then
			-- 	shadow=32
			-- end
		end


		if btnp(4) then
			fire()
		end

		if btnp(5) then

			if ship.hidden==false then
				ship.sp=1
				ship.hidden=true
			else
				ship.sp=103
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
			for e in all(enemies) do
				if coll(eb,e) then
					del(enemies, e)
				end
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
			i.x -= 1
			if i.x < 0 or i.x > 128 or
			i.y < 0 or i.y > 128 then
				del(items, i)
			end
		end
	end

	function _draw()
		print(ship.type, 9, 65, 9)
		-- print(flr(ship.y), 9, 100, 7)
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
		print(numb, 9, 80, 4)
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

	--new function for characters
	function make_actor(x, y)
		a={}
		a.x = x
		a.y = y
		a.dx = 0
		a.dy = 0
		--a.spr = 16
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

		if ship.current_weapon == 171 then
			animation(160,171)
			-- anim_playing=true
		end
	 
	end

	function alien_movement()
		foreach(enemies, update_enemies)
		--foreach(mid_enemies, update_mids)
	end

	function basic_enemy_fire()
		for e in all(enemies) do
			local b = {
				sp=5,
				x=e.x,
				y=e.y,
				dx=-3,
				box = {x1=2,y1=0,x2=5,y2=4}
			}
			add(enemy_bullets, b)
		end
	end

	function star_movement()
		foreach(stars, update_stars)
	end

	function spawn_basic_enemy()
		alien = make_actor(flr(rnd(40)) + 64, flr(rnd(100)) )
		alien.sp = 4
		alien.tick = rndb(45,60)
		alien.health = 2
		alien.damaged = false
		alien.flip = false
		alien.dead = false
		alien.box = {x1=0,y1=0,x2=7,y2=7}

		add(enemies,alien)
	end


	function spawn_midlevel_enemy(x,y,sp)
		mid = make_actor(x, y)
		mid.sp = sp
		mid.tick = rndb(45,60)
		mid.health=100
		mid.box = {x1=0,y1=0,x2=7,y2=7}

		add(mid_enemies, mid)
	end

	function make_enemies(num)
		for i=0,num do
			spawn_basic_enemy()
		end
	end

	function update_enemies(e)
		
		e.tick -=1
		e.x -= 0.8

		if e.tick<=0 then
			if rnd() > 0.2 then
				basic_enemy_fire()
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
		-- 	screeny=flr(ship.y/128)*16


		--move to other level

			if ship.score >= 50 then
				screenx=0
				screeny=16
			end

			if ship.score >= 100 then
				screenx=24

				screeny=0
			end

		end

			--generic item making func
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
					ship.current_weapon = 171
					ship.score+=50
				end
			end

			function draw_menu()
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
					print("ship 1", 5, 42, 2)
					print("ship 2",40,42,2)
					print("ship 3", 40, 55, 2)
				end	
			end

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

			function mid_ai()
				for m in all(mid_enemies) do
					m.y = ship.y
				local lex = m.x 
				local ley = m.y
					if coin_flip() == "heads" then
						enemy_fire(m)
					end
					if interval() == true then
						m.y -= 3.5
					end
					if interval() == false then
						m.y += 3.5
					end
					if(cmap(m)) m.x=lex m.y=ley
					
					if mid.health == 0 then
						del(mid_enemies, m)
					end
				end
			end
			

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
		end

		function movecursor()
			if btnp(1) then
				cls()
				cursor.x=cursor.x + 35
			end
			if btnp(3) then
				cls()
				cursor.y=cursor.y + 13
			end
			if btnp(2) then
				cls()
				cursor.y=cursor.y - 13
			end
			if btnp(0) then
				cls()
				cursor.x=cursor.x - 35
			end
		end

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
00000000000000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000000000000
00000000006600000066000000000000002222000000000000000000000000000888800000088082080800000000000000000000008080000000000000000000
0070070000666600006666000000000000602200000000000000000000000888ee00288882820820008280000000000000000000088888000000000000000000
00077000a066cc660a66cc6600000000000022000000000000000000000888ee00000000088200000000000000000000000000000888880000aaaa0000000000
000770000a66cc66a066cc6600bbbb000022220000aaaa00000000002888ee00000dddd0028880088800000000000000000000000088800000aaaa0000000000
007007000066660000666600000000000000000000000000000000000000000000222ddd82288888208080000000000000000000000800000000000000000000
0000000000660000006600000000000000000000000000000000000000000000022222ddd8288200000820000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000e02222dd2888080800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002222dd2888828000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000022222ddd8282000800800000000000000000000000000000000000000000000
000000000000000000c000000c0070000000000000000000000000000000000000222ddd82280888008280000000000000000000000000000000000000000000
01000000000000000700c0c0000c00000000000000000000000000002888ee00000dddd00288820888200000000000000000000000cccc000000000000000000
0111100000000000000c70000071c000000000000000000000000000000888ee000000002880000000000000000000000000000000cccc000000000000000000
11111111000000000070cc000001000000000000000000000000000000000888ee00288882820000820000000000000000000000000000000000000000000000
0000000000000000000010c000c0c000000000000000000000000000000000002888800000088208082800000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000880008000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000550000000000000000000000000000000000
00000000000000000000000000000000000033300000000000000033300000000000000000000000000000022200d50000000000000000000000000000000000
00000000000000000000000000000000003300233230000000033300323000000000000000000000000000dd2200d50000600000000000000000000000000000
01000000000000000000000000000000033000000003500000330000000350000000000000000000000000d0d0d5d50000760000000000000000000000000000
0111100000000000000000000000000002000dddd0033332023000ddd00333320000000000000000000000ddd0dddd2000775000000000000000000000000000
111111110000000000000000000000000000222ddd05330000000222ddd5330000000000000000000000dd0ddd5dd00000750000000000000000000000000000
0111110000000000000000000000000000022222dd05353000002222ddd535300000000000000000000ddddddd5d5d0000500000000000000000000000000000
01110000000000000000000000000000000e02222d2533330000e0222dd53333000000000000000000de0dd5d25dddd000000000000000000000000000000000
00000000000000000000000000000000000002222d533302020000222dd33302000000000000000000d00d5dd5ddd02000000000000000000000000000000000
0000000000000000000000000000000000022222dd53333003302222ddd333300000000000000000000ddd5d55dddd0000000000000000000000000000000000
000000000000000000000000000000000000222ddd05333300300222ddd53333000000000000000000000d55d05dddd000000000000000000000000000000000
0000000000000000000700000000000020000dddd0353300003000ddd00533000000000000000000000000ddd25dd02000000000000000000000000000000000
0000000000000000000000000000000033000000000532300003000000053230000000000000000000000000005d2d0000000000000000000000000000000000
000000000000000000000000000000000033002333330030000033203333003000000000000000000000000000d0550000000000000000000000000000000000
00000000000000000000000000000000000033500000005000000033000000500000000000000000000000000000d50000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d50000000000000000000000000000000000
00000000000000000000000099999999000000009999999990000005000000000000000000000000111111111777777511111111177777750000000000000000
00000000000000000000000099999999000000009999999990666665000000000000000000000000111111111766666511111111176666650000000000000000
00000000000000000000000099999999000000009777777590666665000000000000000000000000177777751766666517777775176666650000000000000000
00000000000000000000000099999999000000009766666590666665000000000000000000000000176666651766666517666665176666650000000000000000
00000000000000000000000099999999000000009766666595555555000000000000000000000000176666651555555517666665155555550000000000000000
00000000000000000000000099999999000000009555555590000005000000000000000000000000155555551666666515555555166666650000000000000000
00000000000000000000000099999999000000009666666597070705000000000000000000000000199949951565656516666665156565650000000000000000
00000000000000000000000099999999000000009060606590000005000000000000000000000000104040451666666510606065166666650000000000000000
000000000000000000000000cccccccc000000009666666597070705000000000000000000000000194444451565656516666665156565650000000000000000
000000000000000000000000cccccccc000000009060606590000005000000000000000000000000104040451666666510606065166666650000000000000000
000000000000000000000000cccccccc000000009666666597070705000000000000000000000000194444451565656516666665156565650000000000000000
000000000000000000000000cccccccc000000009060606590000005000000000000000000000000104040451666666510606065166666650000000000000000
000000000000000000000000cccccccc000000009666666597070705000000000000000000000000194444451565656516666665156565650000000000000000
000000000000000000000000cccccccc000000009666666595555555000000000000000000000000194444451555555516666665155555550000000000000000
000000000000000000000000cccccccc0000000066dddddd6ddddddd00000000000000000000000066dddddd6ddddddd66dddddd6ddddddd0000000000000000
000000000000000000000000cccccccc0000000099666ddd666ddd9900000000000000000000000011666ddd666ddd1111666ddd666ddd110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000600000000000000000000000000
00000000000000000000000000000000006660000000000000000000000000000000000000000000000001500000000000000150000000000000000000000000
06666000000000000666600000000000006666000000000000000000000000000000000000000000000ddd5500000000000ddd55000000000000000000000000
06c660000000000006c66000000000000056556000000000000000000000000000000000000000000000d555555500000000d555555500000000000000000000
06686666000000000668666600000000000665560000000000000000000000000000000000000000000005555555555500000555555555550000000000000000
006665661dd00000006665661dd0000000056666600000000000000000000000000000000000000000550555d666600000550555d66660000000000000000000
006555661ddc0000006555661ddc0000006666666666866000000000000000000000000000000000055555666650000005555566665000000000000000000000
0006666666666860000666666666686096555651ddc6685600000000000000000000000000000000006c651ddc750000996c651ddc7500000000000000000000
0066666556668866006666655666886696665661ddc6686600000000000000000000000000000000006c651ddc750000996c651ddc7500000000000000000000
06665556656886669666555665688666006666666666865000000000000000000000000000000000055555666650000005555566665000000000000000000000
0665666656886660966566665688666000566666600000000000000000000000000000000000000000550555d666600000550555d66660000000000000000000
00665566500000000066556650000000000665560000000000000000000000000000000000000000000005555555555500000555555555550000000000000000
000000000000000000000000000000000006556000000000000000000000000000000000000000000000d555555500000000d555555500000000000000000000
00000000000000000000000000000000005666000000000000000000000000000000000000000000000ddd5500000000000ddd55000000000000000000000000
00000000000000000000000000000000006660000000000000000000000000000000000000000000000001500000000000000150000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000600000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000000000555555555555555555555000000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000000055555555555555555555555000000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555000000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555000000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555000000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
111111110000000000000000dddddddd000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000900000009000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000090000000900000009000000090000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00090000000900000009000000090000000909000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000900000009000000090000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000900000009000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555066000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555000000000000000000000000000
dddddddddddddd110ddddddddddddddddddddddddddddd110ddddddddddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddd1111116ddddddddddddddddddddddddd1111116dddddddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddd61111111dddddddddddddddddddddddd61111111dddddddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddd6dddd111111111dddddddddddddddddd6dddd111111111ddddddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddd1ddd111111111116dddddddddddddddd1ddd111111111116ddddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddd1116111111111111111ddddddddddddd1116111111111111111dddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd11111111111111111111111ddddddddd11111111111111111111111ddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd11111111111111111111111111dddddd11111111111111111111111111dddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111100001111111000001111111116dd1111111117777775111111111777777500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1111100011111111000011111111111d1111111117666665111111111766666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111100001111111000011111111111111777777517666665177777751766666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111100001111111000111111111111111766666517666665176666651766666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111100001111111000111111111111111766666515555555176666651555555500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111100001111111000111111111111111555555516666665155555551666666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
100000001111101001111111111111111999499515656565166666651565656500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
100000001111000011111111111111111040404516666665106060651666666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000111111111000011111110111000001944444515656565166666651565656500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000001111100000011111110011100001040404516666665106060651666666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000000011100000011111100011110001944444515656565166666651565656500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000000001100000011111000001110001040404516666665106060651666666500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000000001100000011111000001111001944444515656565166666651565656500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000000001100000011110000000011001944444515555555166666651555555500000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
000000000000000011110000000000006a4444456555555566dddddd6ddddddd00000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000111000000000000011666ddd666ddd1111666ddd666ddd1100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddd1dd1111d1111111111111111dddddddd1dd1111d111111111111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddd1d1111111111111111111111dddddddd1d111111111111111111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddd111111111111111111111111dddddddd11111111111111111111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1ddddddd11111111dddddd11111111111ddddddd11111111dddddd111111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1ddddddd11111111ddddddd1111111111ddddddd11111111ddddddd11111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1ddd11dd11111111ddddddd1111111111ddd11dd11111111ddddddd11111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11d111dd11111111dddddddd1111111111d111dd11111111dddddddd1111111100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11d1111d11111111dddddddd11111d1111d1111d11111111dddddddd11111d1100000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080000000808080800000000000000080800000008080808000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080808000000000000000000000000080808080000000000000000000000000000000000000000000000000
__map__
8383838383838383838383838383838383838383838383839697989996979899969798969798999697989996979899969798990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
838383838383838383838383838383838383838383838383a6a7a8a9a6a7a8a9a6a7a8a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
838383838383838383838383838383838383838383838383b6b7b8b9b6b7b8b9b6b7b8b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83838383838383838383838383838383838383838383838386878889b9b6b786878889868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c39697989989868796979899969798999697989996979899969798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3a6a7a8a9999697a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1e2e3e0e1e2e3e0e1e2e3e0e1e2e3e0e1e2e3e0e1e2e3b6b7b8b9a9a6a7b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808080808080808080808080808080808080808080808086878889b9b6b7b8b9b6b7868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080809697989989868788898687969798999697989996979899969798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808080808080808080808080808080808080808080808080a6a7a8a999969798999697a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808080808080808080808080808080808080808080808080b6b7b8b9a9a6a7a8a9a6a7b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080808687888687888986878889868788898687888986878889868788898687888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080809697989697989996979899969798999697989996979899969798999697989900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808080808080808080808080808080808080808080808080a6a7a8a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808080808080808080808080808080808080808080808080b6b7b8b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
808080808080808080808080808080808080808080808080b6b7b88687888986878889868788898687888986878889868788898686000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8383838383838383838383838383838383838383838383830000009697989996979899969798999697989996979899969798990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
838383838383838383838383838383838383838383838383000000a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a9a6a7a8a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
838383838383838383838383838383838383838383838383000000b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b9b6b7b8b90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca83cc83838383838383838383838383838383838383830000008687888986878889868788897616869090900000000086000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0c1c2c3c0c1c2c3c4c5c6c7c4c5c6c7c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c3c0c1c2c39798998616868690009016008600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d1d2d3d0d1d2d3d4d5d6d7d4d5d6d7d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3d0d1d2d3a7a8a98a8b88898a8b1659860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1e2e3e080e2e3e4e5e6e7e4e5e6e7e0e1e2e3e0e1e2e3e0e1e2e3e0e1e2e3e0e1e2e3b7b8b99a9b98999a9b9090860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1f2f3f0f1f2f3f4f5f6f7f4f5f6f7f0f1f2f3f0f1f2f3f0f1f2f3f0f1f2f3f0f1f2f316a8a9aaaba8a9aaab1616168616860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808080808080808080808080808080808080808080808000000000868716969798995758b8b9babbb8b9ba868686598686588686868659000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808080808080808080808080808080808080808080808000000000000066a6a7a8a916161616161688898a8b88898a8b16161616161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80808080808080808080808080808080808080808080808000000000000076b6b7b8b916161616161698999a9b98999a9b16161616161616160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080800000000000008687161616161616868716a8a9aaaba8a9aaab16161616161616000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080800000000000000000000000000000000000b8b9babbb8b9babb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
