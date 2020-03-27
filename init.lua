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
			function doit()
				if response["completed"] == true then 
					minetest.log(response["data"])

					local jo = minetest.parse_json(response["data"])
					local ja = jo["resourceSets"][1]["resources"]["elevations"]
					local k = 0
					for x = minx, maxx do
						for z = minz, maxz do
							k = k + 1
							--local y = ja[k]
							local y = 5
							local vi = area:index(x, y, z)
							data[vi] = minetest.get_content_id("default:dirt_with_grass")
						end
					end

					vm:set_data(data)
					vm:set_lighting({day = 0, night = 0})
					vm:update_liquids() 
					vm:calc_lighting()
					vm:write_to_map(data)
				end
			end
			--local failed = pcall(doit)
			doit()


		end)


	end

	local pxsize = math.abs(maxp.x-minp.x)
	local pzsize = math.abs(maxp.z-minp.z)

	local xtile = math.floor(pxsize/30)
	local ztile = math.floor(pzsize/30)

	for xi = 0,math.ceil(pxsize/xtile) do
		for zi = 0,math.ceil(pzsize/ztile) do
			pcall(doTile,
				xtile * xi,
				xtile * (xi+1),
				ztile * zi,
				ztile * (zi+1))
		end
	end




	--minp.x < -mapsize * 2 or maxp.x > mapsize * 2 or minp.z < -mapsize or maxp.z
	
	
		
	






	

end)


