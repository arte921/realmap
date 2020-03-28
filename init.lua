local http = minetest.request_http_api()

dofile(minetest.get_modpath("realmap") .. "/keys.lua")

local mapsize = 40000

if sflat == nil then sflat = {} end
sflat.options = {
	biome = "",
	decoration = true
}

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_setting("mg_name", "singlenode", true)
end)

minetest.register_on_generated(function(minp, maxp, seed)

	if minp.x < -mapsize * 2 or maxp.x > mapsize * 2 or minp.z < -mapsize or maxp.z > mapsize then
		return
	end

	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	
	argument = ""

	function doTile(minx,maxx,minz,maxz)
		
		local lzarg = minz/mapsize * 90
		local uzarg = maxz/mapsize * 90
		local lxarg = minx/mapsize * 180
		local uxarg = maxx/mapsize * 180
		if math.abs(lzarg) >= 85 then lzarg = 0 end
		if math.abs(uzarg) >= 85 then uzarg = 0 end


		local murl = "http://dev.virtualearth.net/REST/v1/Elevation/Bounds?bounds=" .. lxarg .. "," .. lzarg .. "," .. uxarg .. "," .. uzarg .. "&rows=" .. math.abs(maxz-minz)+1 .. "&cols=" .. math.abs(maxx-minx)+1 .. "&key=" .. bingApiKey 
		--minetest.log(murl)

		http.fetch({url = murl,timeout = 10},function(response)
			if response["completed"] == true then 
				minetest.log(response["data"])

				local jo = minetest.parse_json(response["data"])
				local ja = jo["resourceSets"][1]["resources"][1]["elevations"]

				local k = 0
				for z = maxz,minz,-1 do
					for x = minx,maxx do
						k = k + 1
						if ja[k] >= minp.y and ja[k] <= maxp.y then
							local y = ja[k]
							local vi = area:index(x, y, z)
							--data[vi] = minetest.get_content_id("default:dirt_with_grass")
							--minetest.log("k="..k.." z="..z.." x="..x)
						end

					end
				end

				vm:set_data(data)
				vm:set_lighting({day = 0, night = 0})
				vm:update_liquids() 
				vm:calc_lighting()
				vm:write_to_map(data)
			end
		end)
	end

	local tile = 31
	local totalwidth = math.abs(maxp.x - minp.x)
	local xtiles = math.floor(totalwidth/tile)

	minetest.log("totalwidth " .. totalwidth .. "xtiles " .. xtiles)

	doTile(
		minp.x,
		minp.x + tile,
		minp.z,
		minp.z + tile
	)







	--minp.x < -mapsize * 2 or maxp.x > mapsize * 2 or minp.z < -mapsize or maxp.z
	
	
		
	






	

end)


