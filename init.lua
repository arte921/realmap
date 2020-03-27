dofile(minetest.get_modpath("superflat") .. "/keys.lua")

if sflat == nil then sflat = {} end
sflat.options = {
	biome = "",
	decoration = true
}



minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_setting("mg_name", "singlenode", true)
end)

minetest.register_on_generated(function(minp, maxp, seed)
	--if minp.y >= 5 then
	--	return
	--end
	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local y = x
			local vi = area:index(x, y, z)
			data[vi] = minetest.get_content_id("default:dirt_with_grass")
			minetest.log("x=" .. x)
		end
	end
	
	vm:set_data(data)
	vm:set_lighting({day = 0, night = 0})
	vm:update_liquids() 
	vm:calc_lighting()
	vm:write_to_map(data)
end)


