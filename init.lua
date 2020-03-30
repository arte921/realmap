local http = minetest.request_http_api()

dofile(minetest.get_modpath("realmap") .. "/pngLua/png.lua")
dofile(minetest.get_modpath("realmap") .. "/config.lua")

if sflat == nil then sflat = {} end
sflat.options = {
	biome = "",
	decoration = true
}

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_setting("mg_name", "singlenode", true)
end)

blockArray = {}
heightArray = {}

function applyBlock(x,z,y,block)
	minetest.set_node({x=x,y=y,z=z},{name=block})
	minetest.set_node({x=x,y=y-1,z=z},{name="default:sand"})
	for d = 2,stonelayers do
		minetest.set_node({x=x,y=y-d,z=z},{name="default:stone"})
	end
end

function saveHeight(x,y,z)
	if blockArray[x][z] ~= nil then
		applyBlock(x,z,y,blockArray[x][z])
	else
		heightArray[x][z] = y
	end
end

function saveBlock(x,z,block)
	if heightArray[x][z] ~= nil then
		applyBlock(x,z,heightArray[x][z],block)
	else
		blockArray[x][z] = block
	end
end

function doColorTile(minx,maxx,minz,maxz)

	local lxarg = minx/mapsize/2 * 180
	local uxarg = maxx/mapsize/2 * 180
	local lzarg = minz/mapsize * 90
	local uzarg = maxz/mapsize * 90

	if math.abs(lxarg) > 180 then return end
	if math.abs(uxarg) > 180 then return end

	if math.abs(lzarg) > 85 then return end
	if math.abs(uzarg) > 85 then return end

	local murl = "https://dev.virtualearth.net/REST/v1/Imagery/Map/AerialWithLabels?format=png&mapSize=" .. math.abs(maxz-minz)+1 .. "," .. math.abs(maxx-minx)+1 .. "&mapArea=" .. lzarg .. "," .. lxarg .. "," .. uzarg .. "," .. uxarg .. "&key=" .. bingApiKey 
	minetest.log(murl)
	function dofetch()
		http.fetch({url = murl,timeout = 10},function(response)

			function doit()				
				img = pngImage(response["data"])				
	
				for z = minz,maxz do
					for x = minx,maxx do
						
						local block = ""
							
						local px = img:getPixel(x-minx+1,z-minz+1)

						local b = px["B"]
						local g = px["G"]						
	
						if b > g then
							block = "default:water_source"
						else
							block = "default:dirt_with_grass"
						end

						saveBlock(x,z,block)

					end
				end
			end
	
			if minx > -mapsize * 2 and maxx < mapsize * 2 and minz > -mapsize and maxz < mapsize then
				doit()
			end
		end)
	end

	function tryfetch()
		if not pcall(dofetch) then 
			minetest.after(math.random()*2,tryfetch)
			minetest.log("api is probably rate-limiting")
		 end
	end

	tryfetch()
end

function doHeightTile(minx,maxx,minz,maxz)

	local lxarg = minx/mapsize/2 * 180
	local uxarg = maxx/mapsize/2 * 180
	local lzarg = minz/mapsize * 90
	local uzarg = maxz/mapsize * 90

	if math.abs(lxarg) > 180 then return end
	if math.abs(uxarg) > 180 then return end

	if math.abs(lzarg) > 85 then return end
	if math.abs(uzarg) > 85 then return end


	
	local murl = "http://dev.virtualearth.net/REST/v1/Elevation/Bounds?bounds=" .. lzarg .. "," .. lxarg .. "," .. uzarg .. "," .. uxarg .. "&rows=" .. math.abs(maxz-minz)+1 .. "&cols=" .. math.abs(maxx-minx)+1 .. "&key=" .. bingApiKey 
	
	function dofetch()
		http.fetch({url = murl,timeout = 10},function(response)

			function doit() 
				--minetest.log(response["data"])

				local jo = minetest.parse_json(response["data"])
				local ja = jo["resourceSets"][1]["resources"][1]["elevations"]

				local k = 0
				for z = minz,maxz do
					for x = minx,maxx do
						k = k + 1
						local y = math.floor(ja[k]/heightscale)
						saveHeight(x,y,z)					
					end
				end
			end

			if minx > -mapsize * 2 and maxx < mapsize * 2 and minz > -mapsize and maxz < mapsize then
				pcall(doit)
			end			

		end)
	end

	function tryfetch()
		if not pcall(dofetch) then 
			minetest.after(math.random()*2,tryfetch)
			minetest.log("api is probably rate-limiting")
		 end
	end

	tryfetch()
end

minetest.register_on_generated(function(minp, maxp, seed)
	for x = minp.x,maxp.x do
		blockArray[x] = {}
		heightArray[x] = {}
	end

	local tile = 31
	local totalwidth = math.abs(maxp.x - minp.x)
	local totalheight = math.abs(maxp.z - minp.z)
	local xtiles = math.floor(totalwidth/tile)

	local mxi = 0
	local mzi = 0

	local tileSize = 30

	local xtiles = math.floor(math.abs(maxp.x-minp.x)/tileSize)
	local ztiles = math.floor(math.abs(maxp.z-minp.z)/tileSize)

	if math.sqrt(2) * mapsize > tileSize then

		for xi = 0,xtiles-1 do
			for zi = 0,ztiles-1 do
				doHeightTile(
					minp.x + xi * tileSize,
					minp.x + (xi + 1) * tileSize,
					minp.z + zi * tileSize,
					minp.z + (zi + 1) * tileSize
				)
			end
			doHeightTile(
				minp.x + xi * tileSize,
				minp.x + (xi + 1) * tileSize,
				minp.z + ztiles * tileSize,
				maxp.z
			)
		end

		for zi = 0,ztiles-1 do
			doHeightTile(
				minp.x + xtiles * tileSize,
				maxp.x,
				minp.z + zi * tileSize,
				minp.z + (zi + 1) * tileSize
			)
		end

		doHeightTile(
			minp.x + xtiles * tileSize,
			maxp.x,
			minp.z + ztiles * tileSize,
			maxp.z
		)

	else
		doHeightTile(
			minp.x,
			maxp.x,
			minp.z,
			maxp.z
		)

	end

	local xpixels = 80 --2000
	local zpixels = 80 --1500

	local ximages = math.floor(math.abs(maxp.x-minp.x)/xpixels)
	local zimages = math.floor(math.abs(maxp.z-minp.z)/zpixels)

	if totalwidth >= xpixels or totalheight >= zpixels then

		for xi = 0,ximages-1 do
			for zi = 0,zimages-1 do
				doColorTile(
					minp.x + xi * xpixels,
					minp.x + (xi + 1) * xpixels,
					minp.z + zi * zpixels,
					minp.z + (zi + 1) * zpixels
				)
			end
			doColorTile(
				minp.x + xi * xpixels,
				minp.x + (xi + 1) * xpixels,
				minp.z + zimages * zpixels,
				maxp.z
			)
		end

		for zi = 0,zimages-1 do
			doColorTile(
				minp.x + ximages * xpixels,
				maxp.x,
				minp.z + zi * zpixels,
				minp.z + (zi + 1) * zpixels
			)
		end

		doColorTile(
			minp.x + ximages * xpixels,
			maxp.x,
			minp.z + zimages * zpixels,
			maxp.z
		)

	else
		doColorTile(
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


