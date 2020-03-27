if sflat == nil then sflat = {} end
sflat.options = {
	biome = "",
	decoration = true
}

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_setting("mg_name", "singlenode", true)
end)

local LAYERS = nil
-- Wait until all nodes are loaded
minetest.after(1, function()
	if LAYERS == nil then
		LAYERS = sflat.parsetext(sflat.BLOCKS)
	end
end)

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y >= LAYERS[#LAYERS][3] then
		return
	end
	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()

	
	-- Generate layers
	local li = 1
	for y = minp.y, maxp.y do
		if li > #LAYERS then
			break
		end
		if y >= LAYERS[li][3] then
			li = li + 1
		end
		if (y >= sflat.Y_ORIGIN and y < LAYERS[#LAYERS][3]) then
			local block = LAYERS[li][2]
			for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				local vi = area:index(x, y, z)
				data[vi] = block
			end
			end
		else
			-- air
		end
	end
	
	vm:set_data(data)
	vm:set_lighting({day = 0, night = 0})
	vm:update_liquids()
	vm:calc_lighting()
	vm:write_to_map(data)
end)


