-- Mod: factARy
-- description": "Search for, format, and then store circuit network data into a JSON file
-- Written by KK4TEE
-- http://persigehl.com/
-- Licence: MIT
-- Special thanks: GopherAtl, justarandomgeek, petrukhnov, and lovely_santa
-- Studying the way their mods (Nixi-tube and Smart Display) worked with 
-- Factorio was a huge help and my inspiration. "Nixie tubes are cool! 
-- Why not get data to a real one?"

-- Features to add:
-- Player readout:
-- -- Location!
-- -- Pop up with Name, health, combat
-- 
-- Map size adjustment
-- Lines connecting different layers to the base map location
-- JPG of map terrain as base?

-- track if turret firing
-- Track cannons
-- -- range and ammo
-- track laser turrets
-- track gun turrets
-- track flamer turrets
-- get range of each turret type

-- track enemy structures - slow refresh
-- track MOVING enemy units - high refresh

-- track rail segments? - slow refresh
-- bum out rail chain markers if any color other than green



------ To change settings, please refer to settings.lua -------
filepath = "factARy_log"
filenumber = "1"
filetype = ".json"
modVersion = "0.2.3"
interateStage = 0
path = ""
tEntities = {}
tCircuitNetworks = {}
tListCircuitNetworks = {}
needToDoFirstScan = true
tLocomotives = {}
tTrainSignals = {}
tArtilleryTurrets = {}
tTurrets = {}
tTurretsWithTargets = {}
tEnemies = {}
mapChunks = {}
TrackedForce = nil
loopsSinceScreenshot = 0
screenshotLoopInterval = 600

maxEntitiesPerTick = 75
lastEntityCompleted = 0

script.on_init(function()
    -- pass
end)

-- This script will write JSON data to a pair of alternating text files, with on additional file as a pointer to current read. One file can be read while the other is being written over the span of several ticks.

script.on_event({defines.events.on_tick},
    function (e)
    local json_enabled = settings.global["json_enabled"].value 
    if json_enabled then 
        local js = ""
        path = filepath .. filenumber .. filetype
        if needToDoFirstScan then 
            game.print("factARy version " .. modVersion .. " starting JSON output")
            scanEntities()
            needToDoFirstScan = false
            end
            
        -- Settings Update
        maxEntitiesPerTick = settings.global["maximum_entities_between_ticks"].value
        
        if interateStage == 0 then 
            -- Performing the write is somewhat slow, so don't do it every tick!
            -- Also, don't write to disk any more often than you absolutely have to.
            -- Modify the string, then only write to file once at the end of the tick.
            --game.remove_path(path)
            
            js = js .. "{\n"
            js = js .. "\t\"mod\": \"factARy, by KK4TEE\",\n"
            js = js .. "\t\"version\": \"" .. modVersion .. "\",\n"
            js = js .. "\t\"tick\": \"" .. e.tick .. "\", \n"
            js = js .. "\t\"players\": {\n"
            for index,player in pairs(game.players) do  
                if index > 1 then
                    js = js .. ","
                    js = js ..  "\n"
                end
                
                --loop through all online players on the server
                js = js .. jsonPlayer(player)
                TrackedForce = player.force
                
            end
            js = js .. "\n\t},\n"
            js = js .. checkCircuits(tCircuitNetworks, tListCircuitNetworks) .. ",\n"
            game.write_file(path, js, false)
            interateStage = interateStage + 1
        elseif interateStage == 1 then  ---------- Locomotives
            js = js .. JsonLocomotives(tLocomotives)
            game.write_file(path, js, true)
            interateStage = interateStage + 1
        elseif interateStage == 2 then  ---------- Train Signals
            if #tTrainSignals > lastEntityCompleted then
                js = js .. JsonTrainSignals(tTrainSignals)
                game.write_file(path, js, true)
                end
            if lastEntityCompleted == #tTrainSignals then 
                lastEntityCompleted = 0
                interateStage = interateStage + 1
                end
        elseif interateStage == 3 then ---------- Artillery Turrets
            if #tArtilleryTurrets == 0 then
                -- There are no entities, skip this section
                s = "\t\"artillery-turrets\": {\n"
                s = s .. "\n\t},\n"
                js = js .. s
            else
                if #tArtilleryTurrets > lastEntityCompleted then
                    js = js .. JsonArtilleryTurrets(tArtilleryTurrets)
                    end
                end
            game.write_file(path, js, true)
            if lastEntityCompleted == #tArtilleryTurrets then 
                lastEntityCompleted = 0
                interateStage = interateStage + 1
                end
        elseif interateStage == 4 then ---------- Enemies
            if #tEnemies == 0 then
                -- There are no entities, skip this section
                s = "\t\"enemies\": {\n"
                s = s .. "\n\t},\n"
                js = js .. s
            else
                if #tEnemies > lastEntityCompleted then
                    js = js .. JsonEnemies(tEnemies)
                    end
                end
            game.write_file(path, js, true)
            if lastEntityCompleted == #tEnemies then 
                lastEntityCompleted = 0
                interateStage = interateStage + 1
                end
        elseif interateStage == 5 then ---------- Detect turrets with targets
            if #tTurrets == 0 then
                -- There are no entities, skip this section
            else
                if #tTurrets > lastEntityCompleted then
                    DetectTurretsFiring(tTurrets)
                    end
                end
            if lastEntityCompleted == #tTurrets then 
                lastEntityCompleted = 0
                interateStage = interateStage + 1
                end
        elseif interateStage == 6 then ---------- Turrets with Targets
            if #tTurretsWithTargets == 0 then
                -- There are no entities, skip this section
                s = "\t\"turrets-with-targets\": {\n"
                s = s .. "\n\t},\n"
                js = js .. s
            else
                if #tTurretsWithTargets > lastEntityCompleted then
                    js = js .. JsonTurretsWithTargets(tTurretsWithTargets)
                    end
                end
            game.write_file(path, js, true)
            if lastEntityCompleted == #tTurretsWithTargets then 
                tTurretsWithTargets = {} -- Clear the list
                lastEntityCompleted = 0
                interateStage = interateStage + 1
                end
        elseif interateStage == 7 then ---------- Screenshot Map
            loopsSinceScreenshot = loopsSinceScreenshot + 1
            --game.take_screenshot{resolution={4096, 4096}, zoom=1, path="minimap-1.png", show_gui=false, show_entity_info=true, anti_alias=false}
            if loopsSinceScreenshot > screenshotLoopInterval then
                --game.take_screenshot{resolution={4096, 4096}, zoom=0.01, path="minimap.png", show_gui=false, show_entity_info=true, anti_alias=false}
                loopsSinceScreenshot = 0
                end
            interateStage = interateStage + 1
        elseif interateStage == 8 then  --------- Close the file
            js = js .. "\t\"file_write_complete\":\"true\"\n"
            js = js .. "}"
            game.write_file(path, js, true)
            
            
            if filenumber == "1" then
                filenumber = "2"
            else 
                filenumber = "1"
                end
            interateStage = 0
            end  
        if e.tick % settings.global["ticks_between_entity_scans"].value == 0 then
            scanEntities()
            end
        if e.tick % settings.global["ticks_between_chunk_scans"].value == 0 then
            mapChunks = listSurfaceChunks(game.surfaces[1])
            end
        end
    end
)

script.on_event(defines.events.on_player_died, function(event)
    local recently_deceased_entity = event.entity
    local time_of_death = event.tick
    game.print("Let it be known that a player" ..
               " died a tragic death on tick " .. time_of_death)
    scanEntities()
end)


function scanEntities()
    game.print("factARy scanning entities...")
    for index,player in pairs(game.players) do  
        TrackedForce = player.force
    end
    tLocomotives, tTrainSignals, tEntities, tTurrets, tArtilleryTurrets,tEnemies = DebugSearchForEntities(game.surfaces[1], TrackedForce)
    tCircuitNetworks, tListCircuitNetworks = tableCircuitNetworks(tEntities)
end


function listSurfaceChunks(surface)
	local listChunks = {}
	local i = 0
	for chunk in surface.get_chunks() do
		if chunk ~= nil then
			listChunks[i] = chunk
			i = i + 1
			--game.write_file("debug" .. path, chunk , true)
			end
		end
	return listChunks
end




function DebugSearchForEntities(surface, force)
	local tLocomotives = {}
	local tTrainSignals = {}
	local tNetworkHolders = {}
	local tArtilleryTurrets = {}
    local tTurrets = {}
	local tEnemies = {}
	local enemyInSector = false
	--game.write_file("debug" .. path, "Performing a scan for entities" , false)
	for chunk in surface.get_chunks() do
		local entities = surface.find_entities_filtered{area={{chunk.x*32, chunk.y*32}, {(chunk.x+1)*32, (chunk.y+1)*32}}}
		for _, entity in pairs(entities) do
			if entity.name == "locomotive" then
				table.insert(tLocomotives, entity)
				--game.write_file("debug" .. path, "Entity: " .. entity.name .. " Position: " .. entity.position["x"] .. ", " .. entity.position["y"] .. "\n" , true)
			elseif entity.name == "rail-chain-signal" then
				table.insert(tTrainSignals, entity)
			elseif entity.name == "rail-signal" then
				table.insert(tTrainSignals, entity)
			elseif entity.name == "small-lamp" then 
				table.insert(tNetworkHolders, entity)
            elseif entity.name == "gun-turret" then
                table.insert(tTurrets, entity)
            elseif entity.name == "laser-turret" then
                table.insert(tTurrets, entity) 
            elseif entity.name == "flamethrower-turret" then
                table.insert(tTurrets, entity) 
			elseif entity.name == "artillery-turret" then
				table.insert(tArtilleryTurrets, entity)
                table.insert(tTurrets, entity) 
			elseif entity.name == "artillery-wagon" then
				table.insert(tArtilleryTurrets, entity)
                table.insert(tTurrets, entity)
			
			end
			enemyInSector = false
		end
		--enemies = surface.find_enemy_units({chunk.x,chunk.y}, 32, force)
	
	end
	tLocomotives = table_unique(tLocomotives)
	tTrainSignals = table_unique(tTrainSignals)
	tNetworkHolders = table_unique(tNetworkHolders)
    tTurrets = table_unique(tTurrets)
	tArtilleryTurrets = table_unique(tArtilleryTurrets)
	tEnemies = table_unique(tEnemies)
	return tLocomotives, tTrainSignals, tNetworkHolders, tTurrets,  tArtilleryTurrets, tEnemies
end


function tableCircuitNetworks(tEntities)
	local tNetworks = {}
	local tListNetworks = {}
	
	for _, entity in pairs(tEntities) do
		 local net = entity.get_circuit_network(defines.wire_type.red)
		 if net ~= nil then
			tNetworks[net.network_id] =  net
			table.insert(tListNetworks, net.network_id)
			end
		 net = entity.get_circuit_network(defines.wire_type.green)
		 if net ~= nil then
			tNetworks[net.network_id] =  net
			table.insert(tListNetworks, net.network_id)
			end
	end
	
	tListNetworks = table_unique(tListNetworks)
	return tNetworks, tListNetworks
end


function checkCircuits(tCN, tLCN)
     local s = "\t\"networkData\": {\n"
	 --game.write_file(path .. "error", "\n checkCircuits: " , true)
	 local tempS = ""
	 local firstLineOfNetwork = true
     for i,networkName in ipairs(tLCN) do 

		local network = tCN[networkName]
		if network ~= nil then
			if network.valid then
				if (i > 0) and (tempS ~= "")then
					tempS = tempS .. ",\n"
					end
				tempS = tempS .. "\t\t\"" ..  networkName .. "\": {\n"
				-- no errors while running `foo'
				--game.write_file(path .. "error", "\n The network is valid...", true)
				signals = network.signals
				if signals ~= nil then 
					for ii, signal in ipairs(signals) do
						if (ii > 1) and (tempS ~= "")then
							tempS = tempS .. ",\n"
							end
						if signal ~= nil then
							tempS = tempS .. KeyValStr( signal.signal.name, signal.count, 4)
							
						else
							--game.write_file(path .. "error", "network value was nil...", true)
							end
						end
					end
				tempS = tempS .. "\n\t\t\t}"
				
			else
				-- raised an error: take appropriate actions
				game.write_file(path .. "error", "REMOVED NETWORK!", true)
				table.remove(tCN,i)
				
				end
			end
		
		end
	s = s .. tempS
	s = s .. "\n\t}"
	return s
end

-- from http://lua-users.org/wiki/TableUtils
-- Remove duplicates from a table array (doesn't currently work
-- on key-value tables)
function table_unique(tt)
  local newtable
  newtable = {}
  for ii,xx in ipairs(tt) do
    if(table_count(newtable, xx) == 0) then
      newtable[#newtable+1] = xx
    end
  end
  return newtable
end

-- from http://lua-users.org/wiki/TableUtils
-- Count the number of times a value occurs in a table 
function table_count(tt, item)
  local count
  count = 0
  for ii,xx in pairs(tt) do
    if item == xx then count = count + 1 end
  end
  return count
end

function KeyValStr( key, value, tabs)
	if tabs == nil then
		tabs = 1
		end
	local s = ""
	for i = 1,tabs,1 do
		s = s .. "\t"
		end
	s = s .. "\"" .. key .. "\": \"" .. tostring(value) .. "\""
	return s
end


function jsonPlayer(player)
	local tabs = 4
	local s = "\t\t\t \"" .. tostring(player.index) .. "\" : {\n"
	s = s .. KeyValStr("player", player.name, tabs) .. ",\n"
	s = s .. KeyValStr("connected", tostring(player.connected), tabs) .. ",\n"
	s = s .. KeyValStr("online_time", player.online_time, tabs) .. ",\n"
	s = s .. KeyValStr("afk_time", player.afk_time, tabs)
	if player.connected then
        if player.character ~= nil then
            s = s .. ",\n"
            s = s .. KeyValStr("alive", true, tabs) .. ",\n"
            s = s .. KeyValStr("unit_number", player.character.unit_number, tabs) .. ",\n"
            s = s .. KeyValStr("color_r", tostring(player.character.color["r"]), tabs) .. ",\n"
            s = s .. KeyValStr("color_g", tostring(player.character.color["g"]), tabs) .. ",\n"
            s = s .. KeyValStr("color_b", tostring(player.character.color["b"]), tabs) .. ",\n"
            s = s .. KeyValStr("color_a", tostring(player.character.color["a"]), tabs) .. ",\n"
            s = s .. KeyValStr("health", player.character.health, tabs) .. ",\n"
            s = s .. KeyValStr("in_combat", player.in_combat, tabs) .. ",\n"
            s = s .. KeyValStr("force", player.force.name, tabs) .. ",\n"
            s = s .. KeyValStr("surface.index", player.surface.index, tabs) .. ",\n"
            s = s .. KeyValStr("surface.name", player.surface.name, tabs) .. ",\n"
            s = s .. KeyValStr("x", player.position["x"], tabs) .. ",\n"
            s = s .. KeyValStr("y", player.position["y"], tabs) .. "\n"
        else
            s = s .. ",\n"
            s = s .. KeyValStr("alive", false, tabs) .. "\n"
        end
	else 
		s = s .. "\n"
	end
	s = s .. "\t\t\t}"
	return s
end
	

function JsonLocamotive(L)
	local tabs = 4
	local s = "\t\t\t \"" .. L.unit_number .. "\" : {\n"
	s = s .. KeyValStr("x", tostring(L.position["x"]), tabs) .. ",\n"
	s = s .. KeyValStr("y", tostring(L.position["y"]), tabs) .. ",\n"
	s = s .. KeyValStr("speed", tostring(L.train.speed), tabs) .. ",\n"
	if L.color ~= nil then
		s = s .. KeyValStr("color_r", tostring(L.color["r"]), tabs) .. ",\n"
		s = s .. KeyValStr("color_g", tostring(L.color["g"]), tabs) .. ",\n"
		s = s .. KeyValStr("color_b", tostring(L.color["b"]), tabs) .. ",\n"
		s = s .. KeyValStr("color_a", tostring(L.color["a"]), tabs) .. ",\n"
	else
		s = s .. KeyValStr("color_r", "-1", tabs) .. ",\n"
		s = s .. KeyValStr("color_g", "-1", tabs) .. ",\n"
		s = s .. KeyValStr("color_b", "-1", tabs) .. ",\n"
		s = s .. KeyValStr("color_a", "-1", tabs) .. ",\n"
		end
	
	s = s .. KeyValStr("train.id", tostring(L.train.id), tabs) .. ",\n"
	s = s .. KeyValStr("train_has_path", tostring(L.train.has_path), tabs) --.. ",\n"
	s = s .. "\n"
	s = s .. "\t\t\t}"
	return s

end


function JsonLocomotives(tLocomotives)
	local s = "\t\"locomotives\": {\n"
        for index,locomotive in pairs(tLocomotives) do  
			if locomotive.valid then
				if index > 1 then
					s = s .. ","
					s = s ..  "\n"
				end
				s = s .. JsonLocamotive(locomotive)
			else
				table.remove(tLocomotives,index)
			end
        end
		s = s .. "\n\t},\n"
	return s
end


function JsonTrainSignal(L)
	local tabs = 4
	local s = "\t\t\t \"" .. L.unit_number .. "\" : {\n"
	s = s .. KeyValStr("x", tostring(L.position["x"]), tabs) .. ",\n"
	s = s .. KeyValStr("y", tostring(L.position["y"]), tabs) .. ",\n" 
	if L.name == "rail-chain-signal" then
		s = s .. KeyValStr("state", tostring(L.chain_signal_state), tabs) .. "\n"
	elseif L.name == "rail-signal" then
		s = s .. KeyValStr("state", tostring(L.signal_state), tabs) .. "\n"
	end
	--s = s .. KeyValStr("speed", tostring(L.train.speed), tabs) .. ",\n"
	--s = s .. KeyValStr("id", tostring(L.train.id), tabs) .. ",\n"
	s = s .. "\n"
	s = s .. "\t\t\t}"
	return s

end


function JsonTrainSignals(T)
	local startingIndex = lastEntityCompleted
	local endingIndex = lastEntityCompleted + maxEntitiesPerTick
	local s = ""
	
	if startingIndex == 0 then
		s = "\t\"train_signals\": {\n"
	elseif startingIndex > 0 then
		startingIndex = startingIndex + 1
	end
    for index,entity in pairs(T) do  
			if index >= startingIndex and index < endingIndex then
				if entity.valid then
					if index > 1 then
						s = s .. ","
						s = s ..  "\n"
					end
					
					s = s .. JsonTrainSignal(entity)
				else
					table.remove(T,index)
				end
				lastEntityCompleted = index
				--game.write_file("debug" .. path, "Last entity complete: " .. lastEntityCompleted .. " out of " .. #T, true)
			end
		

        end
		if lastEntityCompleted == #T then
			s = s .. "\n\t},\n"
			end
	return s
end


function ArtilleryTurret(E)
	local tabs = 4
	local s = "\t\t\t \"" .. E.unit_number .. "\" : {\n"
	s = s .. KeyValStr("x", tostring(E.position["x"]), tabs) .. ",\n"
	s = s .. KeyValStr("y", tostring(E.position["y"]), tabs) .. ",\n" 
	s = s .. KeyValStr("ammo_count", "-1", tabs) .. ",\n" --TODO: FIGURE OUT HOW TO GET INVENTORY
	s = s .. KeyValStr("turret_range", tostring(E.prototype.turret_range), tabs) .. ",\n"
	s = s .. KeyValStr("damage_dealt", tostring(E.damage_dealt), tabs) .. ",\n"
	s = s .. KeyValStr("kills", tostring(E.kills), tabs) .. ",\n"
	
	
	if E.name == "rail-chain-signal" then
		s = s .. KeyValStr("state", tostring(E.chain_signal_state), tabs) .. "\n"
	elseif E.name == "rail-signal" then
		s = s .. KeyValStr("state", tostring(E.signal_state), tabs) .. "\n"
	end
	
	s = s .. KeyValStr("last_user", tostring(E.last_user.name), tabs) .. "\n"
	--s = s .. KeyValStr("speed", tostring(E.train.speed), tabs) .. ",\n"
	--s = s .. KeyValStr("id", tostring(E.train.id), tabs) .. ",\n"
	s = s .. "\n"
	s = s .. "\t\t\t}"
	return s

end


function JsonArtilleryTurrets(T)
	local startingIndex = lastEntityCompleted
	local endingIndex = lastEntityCompleted + maxEntitiesPerTick
	local s = ""
	
	if startingIndex == 0 then
		s = "\t\"artillery-turrets\": {\n"
	elseif startingIndex > 0 then
		startingIndex = startingIndex + 1
	end
    for index,entity in pairs(T) do  
			if index >= startingIndex and index < endingIndex then
				if entity.valid then
					if index > 1 then
						s = s .. ","
						s = s ..  "\n"
					end
					
					s = s .. ArtilleryTurret(entity)
				else
					table.remove(T,index)
				end
				lastEntityCompleted = index
				--game.write_file("debug" .. path, "Last entity complete: " .. lastEntityCompleted .. " out of " .. #T, true)
			end
		

        end
		if lastEntityCompleted == #T then
			s = s .. "\n\t},\n"
			end
	return s
end


---------------Enemies------------------
function JsonEnemy(E)
	local tabs = 4
	local s = "\t\t\t \"" .. E.unit_number .. "\" : {\n"
	s = s .. KeyValStr("x", tostring(E.position["x"]), tabs) .. ",\n"
	s = s .. KeyValStr("y", tostring(E.position["y"]), tabs) .. ",\n" 
	s = s .. KeyValStr("health", E.health, tabs) .. ",\n" --TODO: FIGURE OUT HOW TO GET INVENTORY
	s = s .. KeyValStr("kills", tostring(E.kills), tabs) .. ",\n"
	
	--s = s .. KeyValStr("speed", tostring(E.train.speed), tabs) .. ",\n"
	--s = s .. KeyValStr("id", tostring(E.train.id), tabs) .. ",\n"
	s = s .. "\n"
	s = s .. "\t\t\t}"
	return s

end


function JsonEnemies(T)
	local startingIndex = lastEntityCompleted
	local endingIndex = lastEntityCompleted + maxEntitiesPerTick
	local s = ""
	
	if startingIndex == 0 then
		s = "\t\"enemies\": {\n"
	elseif startingIndex > 0 then
		startingIndex = startingIndex + 1
	end
    for index,entity in pairs(T) do  
			if index >= startingIndex and index < endingIndex then
				if entity.valid then
					if index > 1 then
						s = s .. ","
						s = s ..  "\n"
					end
					
					s = s .. JsonEnemy(entity)
				else
					table.remove(T,index)
				end
				lastEntityCompleted = index
				--game.write_file("debug" .. path, "Last entity complete: " .. lastEntityCompleted .. " out of " .. #T, true)
			end
		

        end
		if lastEntityCompleted == #T then
			s = s .. "\n\t},\n"
			end
	return s
end


function DetectTurretsFiring(E)
    local startingIndex = lastEntityCompleted
	local endingIndex = lastEntityCompleted + maxEntitiesPerTick
    
	for index,entity in pairs(E) do  
			if index >= startingIndex and index < endingIndex then
				if entity.valid then
					if entity.shooting_target ~= nil then
                        -- game.print("factARy: Turret has a target!") -- makes a notice sound!
                        table.insert(tTurretsWithTargets, entity)
                    end
					
				else
					table.remove(E,index)
				end
				lastEntityCompleted = index
			end
        end
    --return s
end


function TurretWithTarget(E)
	local tabs = 4
	local s = "\t\t\t \"" .. E.unit_number .. "\" : {\n"
	s = s .. KeyValStr("x", tostring(E.position["x"]), tabs) .. ",\n"
	s = s .. KeyValStr("y", tostring(E.position["y"]), tabs) .. ",\n" 
	s = s .. KeyValStr("ammo_count", "-1", tabs) .. ",\n" --TODO: FIGURE OUT HOW TO GET INVENTORY
	s = s .. KeyValStr("turret_range", tostring(E.prototype.turret_range), tabs) .. ",\n"
    s = s .. KeyValStr("shooting_target", tostring(E.shooting_target), tabs) .. ",\n" 
	s = s .. KeyValStr("damage_dealt", tostring(E.damage_dealt), tabs) .. ",\n"
	s = s .. KeyValStr("kills", tostring(E.kills), tabs) .. ",\n"
	s = s .. KeyValStr("last_user", tostring(E.last_user.name), tabs) .. "\n"
	s = s .. "\n"
	s = s .. "\t\t\t}"
	return s

end


function JsonTurretsWithTargets(T)
	local startingIndex = lastEntityCompleted
	local endingIndex = lastEntityCompleted + maxEntitiesPerTick
	local s = ""
	
	if startingIndex == 0 then
		s = "\t\"turrets-with-targets\": {\n"
	elseif startingIndex > 0 then
		startingIndex = startingIndex + 1
	end
    for index,entity in pairs(T) do  
			if index >= startingIndex and index < endingIndex then
				if entity.valid then
					if index > 1 then
						s = s .. ","
						s = s ..  "\n"
					end
					
					s = s .. TurretWithTarget(entity)
				else
					table.remove(T,index)
				end
				lastEntityCompleted = index
				--game.write_file("debug" .. path, "Last entity complete: " .. lastEntityCompleted .. " out of " .. #T, true)
			end
		

        end
		if lastEntityCompleted == #T then
			s = s .. "\n\t},\n"
			end
	return s
end
-------------End Enemies------------------

