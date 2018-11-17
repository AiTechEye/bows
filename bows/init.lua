bows={
	nuke=true,
	cluser=true,
	pvp=minetest.settings:get_bool("enable_pvp") or nil,
	nitroglycerine=minetest.get_modpath("nitroglycerine")~=nil,
	creative=minetest.settings:get_bool("creative_mode"),
	mesecons=minetest.get_modpath("mesecons"),
	registed_arrows={},
	registed_bows={},
}

minetest.register_craft({
	type = "fuel",
	recipe = "group:bow",
	burntime = 3,
})

bows.register_arrow=function(name,def)
	if name==nil or name=="" then return false end

	def.damage = def.damage or 0
	def.name = "bows:".. name
	def.level = def.level or 1
	def.on_hit_object = def.on_hit_object or bows.nothing
	def.on_hit_node = def.on_hit_node or bows.on_hit_node
	def.on_hit_sound= def.on_hit_sound or "default_dig_dig_immediate"
	def.on_step = def.on_step or bows.nothing

	bows.registed_arrows[def.name]=def

	minetest.register_craftitem("bows:".. name, {
		description = def.description or name,
		inventory_image = def.texture or "bows_arrow_wooden.png",
		groups = {arrow=1}
	})
	if def.craft then
		def.craft_count= def.craft_count or 4
		minetest.register_craft({
			output = def.name .." " .. def.craft_count,
			recipe = def.craft
		})
	end
end

bows.register_bow=function(name,def)
	if name==nil or name=="" then return false end

	def.replace = "bows:" .. name .."_loaded"
	def.name = "bows:".. name
	def.uses = def.uses-1 or 49
	def.shots = def.shots or 1
	bows.registed_bows[def.replace]=def

	minetest.register_tool(def.name, {
		description = def.description or name,
		inventory_image = def.texture or "bows_bow.png",
		on_use =bows.load,
		groups = {bow=1,stick=1},
	})
	minetest.register_tool(def.replace, {
		description = def.description or name,
		inventory_image = def.texture_loaded or "bows_bow_loaded.png",
		on_use =bows.shoot,
		groups = {bow=1,stick=1,not_in_creative_inventory=1},
	})
	if def.craft then
		minetest.register_craft({output = def.name,recipe = def.craft})
	end
	def.craft=nil
end

bows.load=function(itemstack, user, pointed_thing)
	local inv=user:get_inventory()
	local index=user:get_wield_index()-1
	local arrow=inv:get_stack("main", index)
	if minetest.get_item_group(arrow:get_name(), "arrow")==0 then return itemstack end
	local item=itemstack:to_table()
	local meta=minetest.deserialize(item.metadata)
	local shots=bows.registed_bows[item.name .. "_loaded"].shots
	if bows.creative==false then
		local c=arrow:get_count()-shots
		if c<0 then
			shots=arrow:get_count()
			c=0
		end
		inv:set_stack("main",index,ItemStack(arrow:get_name() .. " " .. c))
	end
	meta={arrow=arrow:get_name(),shots=shots}
	item.metadata=minetest.serialize(meta)
	item.name=item.name .. "_loaded"
	itemstack:replace(item)
	return itemstack
end

bows.shoot=function(itemstack, user, pointed_thing)
	local item=itemstack:to_table()
	local meta=minetest.deserialize(item.metadata)
	if (not (meta and meta.arrow)) or (not bows.registed_arrows[meta.arrow]) then
		return itemstack
	end
	local name=itemstack:get_name()
	local replace=bows.registed_bows[name].name
	local ar=bows.registed_bows[name].uses
	local wear=bows.registed_bows[name].uses
	local level=19 + bows.registed_bows[name].level
	local shots=meta.shots or 1

	item.arrow=""
	item.metadata=minetest.serialize(meta)
	item.name=replace
	itemstack:replace(item)
	if bows.creative==false then
		itemstack:add_wear(65535/wear)
	end
	for i=0,shots-1,1 do
		minetest.after(0.05*i, function(level,user,meta)
			bows.tmp = {}
			bows.tmp.arrow = meta.arrow
			bows.tmp.user = user
			bows.tmp.name=meta.arrow
			bows.tmp.shots=shots

			local pos = user:get_pos()
			local dir = user:get_look_dir()

			local x=math.random(-1,1)*0.1
			local y=math.random(-1,1)*0.1
			local z=math.random(-1,1)*0.1

			local e=minetest.add_entity({x=pos.x+x,y=pos.y+1.5+y,z=pos.z+z}, "bows:arrow")
			e:set_velocity({x=dir.x*level, y=dir.y*level, z=dir.z*level})
			e:set_acceleration({x=dir.x*-3, y=-10, z=dir.z*-3})
			e:set_yaw(user:get_look_yaw()+math.pi)
			minetest.sound_play("bows_shoot", {pos=pos})
		end,level,user,meta)
	end

	return itemstack
end

dofile(minetest.get_modpath("bows") .. "/arrow.lua")
dofile(minetest.get_modpath("bows") .. "/items_functions.lua")
dofile(minetest.get_modpath("bows") .. "/items.lua")

