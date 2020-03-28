local http = minetest.request_http_api()

dofile(minetest.get_modpath("realmap") .. "/config.lua")

if sflat == nil then sflat = {} end
sflat.options = {
	biome = "",
	decoration = true
}

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_setting("mg_name", "singlenode", true)
end)

minetest.register_on_generated(function(minp, maxp, seed)
	function doTile(minx,maxx,minz,maxz)

		local lxarg = minx/mapsize/2 * 180
		local uxarg = maxx/mapsize/2 * 180
		local lzarg = minz/mapsize * 90
		local uzarg = maxz/mapsize * 90

		if math.abs(lxarg) > 180 then return end
		if math.abs(uxarg) > 180 then return end

		if math.abs(lzarg) > 85 then return end
		if math.abs(uzarg) > 85 then return end



		local murl = "http://dev.virtualearth.net/REST/v1/Elevation/Bounds?bounds=" .. lzarg .. "," .. lxarg .. "," .. uzarg .. "," .. uxarg .. "&rows=" .. math.abs(maxz-minz)+1 .. "&cols=" .. math.abs(maxx-minx)+1 .. "&key=" .. bingApiKey 
		--minetest.log(murl)
		http.fetch({url = murl,timeout = 10},function(response)

			function doit() 
				--minetest.log(response["data"])

				local jo = minetest.parse_json(response["data"])
				local ja = jo["resourceSets"][1]["resources"][1]["elevations"]

				local k = 0
				for z = minz,maxz do
					for x = minx,maxx do
						k = k + 1
						
						--if ja[k] >= minp.y and ja[k] <= maxp.y then
							local y = math.floor(ja[k]/heightscale)

							--minetest.log("x"..x.."z"..z.."y"..y)
							
							--minetest.log(y)
							if y > 0 then
								minetest.set_node({x=x,y=y,z=z},{name="default:dirt_with_grass"})
								for d = 1,stonelayers do
									minetest.set_node({x=x,y=y-d,z=z},{name="default:stone"})
								end

							else
								minetest.set_node({x=x,y=y,z=z},{name="default:water_source"})
								minetest.set_node({x=x,y=y-1,z=z},{name="default:sand"})
								for d = 2,stonelayers do
									minetest.set_node({x=x,y=y-d,z=z},{name="default:stone"})
								end
							end
						--end

					end
				end
			end

			function tryit()
				if not pcall(doit) then 
					minetest.after(math.random()*2,tryit)
					minetest.log("api is rate-limiting")
				 end
			end

			if minx > -mapsize * 2 and maxx < mapsize * 2 and minz > -mapsize and maxz < mapsize then
				tryit()
			end
			

		end)
	end

	local tile = 31
	local totalwidth = math.abs(maxp.x - minp.x)
	local xtiles = math.floor(totalwidth/tile)

	local mxi = 0
	local mzi = 0

	local tileSize = 30

	local xtiles = math.floor(math.abs(maxp.x-minp.x)/tileSize)
	local ztiles = math.floor(math.abs(maxp.z-minp.z)/tileSize)

	if math.sqrt(2) * mapsize > tileSize then

		for xi = 0,xtiles-1 do
			for zi = 0,ztiles-1 do
				doTile(
					minp.x + xi * tileSize,
					minp.x + (xi + 1) * tileSize,
					minp.z + zi * tileSize,
					minp.z + (zi + 1) * tileSize
				)
			end
		end

		for xi = 0,xtiles-1 do
			for zi = 0,ztiles-1 do
				doTile(
					minp.x + xi * tileSize,
					minp.x + (xi + 1) * tileSize,
					minp.z + ztiles * tileSize,
					maxp.z
				)
			end
		end

		for zi = 0,ztiles-1 do
			doTile(
				minp.x + xtiles * tileSize,
				maxp.x,
				minp.z + zi * tileSize,
				minp.z + (zi + 1) * tileSize
			)
		end

		doTile(
			minp.x + xtiles * tileSize,
			maxp.x,
			minp.z + ztiles * tileSize,
			maxp.z
		)

	else
		doTile(
			minp.x,
			maxp.x,
			minp.z,
			maxp.z
		)

	end




end)

minetest.register_chatcommand("tpll", {
	params = "<lat> <lon>",
	description = "Teleport to the corresponding real world location",
	func = function(name,param)
		local lat,lon = param:match("(.+) (.+)")
		minetest.log(param)

		local url = "http://dev.virtualearth.net/REST/v1/Elevation/List?points=" .. lat .. "," .. lon .. "&key=" .. bingApiKey
		
		http.fetch({url = url,timeout = 5},function(response)
			local y = math.floor(minetest.parse_json(response["data"])["resourceSets"][1]["resources"][1]["elevations"][1]/heightscale) + 2
			local x = lon/180*mapsize*2
			local z = lat/90*mapsize

			local player = minetest.get_player_by_name(name)
			player:set_pos({x = x, y = y, z = z})
		end)


		return true, "One moment please..."
	end,
})


