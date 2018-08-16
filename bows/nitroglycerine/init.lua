nitroglycerine={}
nitroglycerine.explode=function(pos,node)
	if not (pos and pos.x and pos.y and pos.z) then return end
	if not node then node={} end

	node.radius= node.radius or 3
	node.set= node.set or ""
	node.place= node.place or {"nitroglycerine:fire","air","air","air","air"}
	node.place_chance=node.place_chance or 5
	node.user_name=node.user_name or ""
	node.drops=node.drops or 1
	node.velocity=node.velocity or 1
	node.hurt=node.hurt or 1
	node.blow_nodes=node.blow_nodes or 1

if node.blow_nodes==1 then

	local nodes={}
	if node.set~="" then node.set=minetest.get_content_id(node.set) end

	local nodes_n=0
	for i, v in pairs(node.place) do
		nodes_n=i
		nodes[i]=minetest.get_content_id(v)
	end

	if node.place_chance<=1 then node.place_chance=2 end
	if nodes_n<=1 then nodes_n=2 end

	local air=minetest.get_content_id("air")
	pos=vector.round(pos)
	local pos1 = vector.subtract(pos, node.radius)
	local pos2 = vector.add(pos, node.radius)
	local vox = minetest.get_voxel_manip()
	local min, max = vox:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
	local data = vox:get_data()
	for z = -node.radius, node.radius do
	for y = -node.radius, node.radius do
	for x = -node.radius, node.radius do
		local rad = vector.length(vector.new(x,y,z))
		local v = area:index(pos.x+x,pos.y+y,pos.z+z)
		local p={x=pos.x+x,y=pos.y+y,z=pos.z+z}

		if data[v]~=air and node.radius/rad>=1 and minetest.is_protected(p, node.user_name)==false then

			local no=minetest.registered_nodes[minetest.get_node(p).name]

			if no and no.on_blast then
				no.on_blast(p,node.radius)
			end

			if node.set~="" then
				data[v]=node.set
			end

			if math.random(1,node.place_chance)==1 then
				data[v]=nodes[math.random(1,nodes_n)]
			end

			if node.drops==1 and data[v]==air and math.random(1,4)==1 then
				local n=minetest.get_node(p)

				if no and no.walkable and math.random(1,2)==1 then
					nitroglycerine.spawn_dust(p)
				else
					for _, item in pairs(minetest.get_node_drops(n.name, "")) do
						if p and item then minetest.add_item(p, item) end
					end
				end
			end
		end
	end
	end
	end
	vox:set_data(data)
	vox:write_to_map()
	vox:update_map()
	vox:update_liquids()
end

if node.hurt==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		if not (ob:get_luaentity() and (ob:get_luaentity().itemstring or ob:get_luaentity().nitroglycerine_dust)) then
			local pos2=ob:getpos()
			local d=math.max(1,vector.distance(pos,pos2))
			local dmg=(8/d)*node.radius
			ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=dmg}})
		elseif ob:get_luaentity() then
			ob:get_luaentity().age=890
		end
	end
end
if node.velocity==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		local pos2=ob:getpos()
		local d=math.max(1,vector.distance(pos,pos2))
		local dmg=(8/d)*node.radius
		if ob:get_luaentity() and not ob:get_luaentity().attachplayer and not (ob:get_luaentity().nitroglycerine_dust and ob:get_luaentity().nitroglycerine_dust==2) then
			ob:setvelocity({x=(pos2.x-pos.x)*dmg, y=(pos2.y-pos.y)*dmg, z=(pos2.z-pos.z)*dmg})


			if ob:get_luaentity() and ob:get_luaentity().nitroglycerine_dust then ob:get_luaentity().nitroglycerine_dust=2 end

		elseif ob:is_player() then
			nitroglycerine.new_player=ob
			minetest.add_entity({x=pos2.x,y=pos2.y+1,z=pos2.z}, "nitroglycerine:playerp"):setvelocity({x=(pos2.x-pos.x)*dmg, y=(pos2.y-pos.y)*dmg, z=(pos2.z-pos.z)*dmg})
			nitroglycerine.new_player=nil
		end
	end
end

	minetest.sound_play("nitroglycerine_explode", {pos=pos, gain = 0.5, max_hear_distance = node.radius*8})
	if node.radius>9 then
		minetest.sound_play("nitroglycerine_nuke", {pos=pos, gain = 0.5, max_hear_distance = node.radius*30})
	end
	minetest.add_particlespawner({
		amount = 20,
		time =0.2,
		minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
		maxpos = {x=pos.x+1, y=pos.y, z=pos.z+1},
		minvel = {x=-5, y=0, z=-5},
		maxvel = {x=5, y=5, z=5},
		minacc = {x=0, y=2, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 1,
		maxexptime = 2,
		minsize = 5,
		maxsize = 10,
		texture = "default_item_smoke.png",
		collisiondetection = true,
	})
end

nitroglycerine.punchdmg=function(ob,hp)
	if not ob or type(ob)~="userdata" then return end
	hp=hp or 1
	ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=hp}})
end


nitroglycerine.freeze=function(ob)
	local p=ob:get_properties()
	local pos=ob:getpos()
	if ob:is_player() then
		pos=vector.round(pos)
		local node=minetest.get_node(pos)
		if node==nil or node.name==nil or minetest.registered_nodes[node.name].buildable_to==false then return end
		minetest.set_node(pos, {name = "nitroglycerine:icebox"})
		minetest.after(0.5, function(pos, ob) 
			pos.y=pos.y-0.5
			ob:moveto(pos,false)
		end, pos, ob)
		return
	end
	if not ob:get_luaentity() then return end
	if p.visual=="mesh" and p.mesh~="" and p.mesh~=nil and ob:get_luaentity().name~="nitroglycerine:ice" then
		nitroglycerine.newice=true
		local m=minetest.add_entity(pos, "nitroglycerine:ice")
		m:setyaw(ob:getyaw())
		m:set_properties({
			visual_size=p.visual_size,
			visual="mesh",
			mesh=p.mesh,
			textures={"default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png"},
			collisionbox=p.collisionbox
		})
	elseif ob:get_luaentity().name~="nitroglycerine:ice" then
		minetest.add_item(pos,"default:ice")
	end
	local hp=ob:get_hp()+1

	ob:get_luaentity().destroy=1

	ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=hp}})
	if ob:get_luaentity().aliveai then
		for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			if ob:get_luaentity() and ob:get_luaentity().type and ob:get_luaentity().type=="" then
			ob:remove()
			end
		end
	end
end


nitroglycerine.spawn_dust=function(pos)
		if not pos then return end

		local drop=minetest.get_node_drops(minetest.get_node(pos).name)[1]
		local n=minetest.registered_nodes[minetest.get_node(pos).name]
		if not (n and n.walkable) or drop=="" or type(drop)~="string" then return end
		local t=n.tiles
		if not t[1] then return end
		local tx={}
		local tt={}
		tt.t1=t[1]
		tt.t2=t[1]
		tt.t3=t[1]

		if t[2] then tt.t2=t[2] tt.t3=t[2] end
		if t[3] and t[3].name then tt.t3=t[3].name
		elseif t[3] then tt.t3=t[3]
		end
		if type(tt.t3)=="table" then return end
		tx[1]=tt.t1
		tx[2]=tt.t2
		tx[3]=tt.t3
		tx[4]=tt.t3
		tx[5]=tt.t3
		tx[6]=tt.t3

	nitroglycerine.new_dust={t=tx,drop=drop}
	minetest.add_entity(pos, "nitroglycerine:dust")

	nitroglycerine.new_dust=nil
end

minetest.register_entity("nitroglycerine:ice",{
	hp_max = 1,
	physical = true,
	weight = 5,
	collisionbox = {-0.3,-0.3,-0.3, 0.3,0.3,0.3},
	visual = "sprite",
	visual_size = {x=0.7, y=0.7},
	textures = {}, 
	colors = {}, 
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = true,
	automatic_rotate = false,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
			local pos=self.object:getpos()
			minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 10,})
			nitroglycerine.crush(pos)
	end,
	on_activate=function(self, staticdata)
		if nitroglycerine.newice then
			nitroglycerine.newice=nil
		else
			self.object:remove()
		end
		self.object:setacceleration({x = 0, y = -10, z = 0})
		self.object:setvelocity({x = 0, y = -10, z = 0})
	end,
	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer<1 then return true end
		self.timer=0
		self.timer2=self.timer2+dtime
		if self.timer2>0.8 then
			minetest.sound_play("default_break_glass", {pos=self.object:getpos(), gain = 1.0, max_hear_distance = 10,})
			self.object:remove()
			nitroglycerine.crush(self.object:getpos())
			return true
		end
	end,
	timer = 0,
	timer2 = 0,

})

minetest.register_entity("nitroglycerine:dust",{
	hp_max = 1000,
	physical =true,
	weight = 0,
	collisionbox = {-0.5,-0.5,-0.5,0.5,0.5,0.5},
	visual = "cube",
	visual_size = {x=1,y=1},
	textures ={"nitroglycerine_air.png"},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = true,
	on_punch2=function(self)
		minetest.add_item(self.object:getpos(),self.drop)
		self.object:remove()
		return self
	end,
	on_activate=function(self, staticdata)
		if not nitroglycerine.new_dust then self.object:remove() return self end
		self.drop=nitroglycerine.new_dust.drop
		self.object:set_properties({textures = nitroglycerine.new_dust.t})
		self.object:setacceleration({x=0,y=-10,z=0})
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		if self.time<self.timer then return self end
		self.time=0
		self.timer2=self.timer2-1
		local pos=self.object:getpos()
		local u=minetest.registered_nodes[minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name]
		if u and u.walkable then
			local n=minetest.registered_nodes[minetest.get_node(pos).name]
			if n and n.buildable_to and minetest.registered_nodes[self.drop] then
				minetest.set_node(pos,{name=self.drop})
				self.object:remove()
			else
				self.on_punch2(self)
			end
			return self
		elseif self.timer2<0 then
			self.on_punch2(self)
		end
		return self
	end,
	time=0,
	timer=2,
	timer2=10,
	nitroglycerine_dust=1,
})

minetest.register_entity("nitroglycerine:playerp",{
	hp_max = 1000,
	physical =true,
	collisionbox = {-0.5,-0.5,-0.5,0.5,1.5,0.5},
	visual = "sprite",
	textures ={"nitroglycerine_air.png"},
	is_visible = true,
	makes_footstep_sound = false,
	pointable=false,
	on_punch=function(self)
		local v=self.object:getvelocity().y
		if v<0.2 and v>-0.2 then
			self.kill(self)
		end
	end,
	kill=function(self,liquid)
		if self.ob and self.ob:get_attach() then
			self.ob:set_detach()
			if not (liquid and liquid>0) then

				local from=math.floor((self.y+0.5)/2)
				local hit=math.floor((self.object:getpos().y+0.5)/2)
				local d=from-hit
				if d>=0 then
					nitroglycerine.punchdmg(self.ob,d)
				end
			end
		end
		self.object:remove()
		return self
	end,
	on_activate=function(self, staticdata)
		if not nitroglycerine.new_player or minetest.check_player_privs(nitroglycerine.new_player:get_player_name(), {fly=true}) then self.object:remove() return self end
		self.ob=nitroglycerine.new_player
		self.ob:set_attach(self.object, "",{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		self.object:setacceleration({x=0,y=-10,z=0})
		self.y=self.object:getpos().y
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		if self.time<self.timer then return self end
		self.time=0
		self.timer2=self.timer2-1
		local pos=self.object:getpos()

		if pos.y>self.y then self.y=pos.y end

		local u=minetest.registered_nodes[minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name]
		if (u and u.walkable or u.liquid_viscosity>0) or self.timer2<0 or (not self.ob or not self.ob:get_attach()) then
			self.kill(self,u.liquid_viscosity)
		end
		return self
	end,
	time=0,
	timer=0.5,
	timer2=100,
	attachplayer=1,
})

minetest.register_node("nitroglycerine:icebox", {
	description = "Ice box",
	wield_scale = {x=2, y=2, z=2},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 1.5, -0.4375},
			{-0.5, -0.5, 0.4375, 0.5, 1.5, 0.5},
			{0.4375, -0.5, -0.4375, 0.5, 1.5, 0.4375},
			{-0.5, -0.5, -0.4375, -0.4375, 1.5, 0.4375},
			{-0.5, 1.5, -0.5, 0.5, 1.4375, 0.5},
		}
	},
	drop="default:ice",
	tiles = {"default_ice.png"},
	groups = {cracky = 1, level = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_glass_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
	alpha = 30,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 2,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(20)
	end,
	on_timer = function (pos, elapsed)
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			return true
		end
		minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 10,})
		minetest.set_node(pos, {name = "air"})
		nitroglycerine.crush(pos)
		return false
	end,
	type="",
})

nitroglycerine.crush=function(pos)
minetest.add_particlespawner({
	amount = 15,
	time =0.1,
	minpos = pos,
	maxpos = pos,
	minvel = {x=-2, y=-2, z=-2},
	maxvel = {x=2, y=2, z=2},
	minacc = {x=0, y=-8, z=0},
	maxacc = {x=0, y=-10, z=0},
	minexptime = 2,
	maxexptime = 1,
	minsize = 0.1,
	maxsize = 3,
	texture = "default_ice.png",
	collisiondetection = true,
})
end

minetest.register_node("nitroglycerine:fire", {
	description = "fire",
	inventory_image = "fire_basic_flame.png",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	paramtype = "light",
	light_source = 10,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {dig_immediate = 2,not_in_creative_inventory=1},
	drop="",
})

minetest.register_node("nitroglycerine:fire2", {
	description = "fire",
	inventory_image = "fire_basic_flame.png",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	paramtype = "light",
	light_source = 5,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {dig_immediate = 2,not_in_creative_inventory=1},
	drop="",
})

minetest.register_abm({
	nodenames = {"nitroglycerine:fire","nitroglycerine:fire2"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n=minetest.get_node(pos).name
		if n=="nitroglycerine:fire" and math.random(1,20)==1 then
			minetest.set_node(pos, {name = "air"})
		elseif n=="nitroglycerine:fire2" and math.random(1,5)==1 then
			minetest.set_node(pos, {name = "air"})
		end
	end,
})