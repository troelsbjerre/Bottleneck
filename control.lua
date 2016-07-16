require "util"

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end


function init()
	--[[ Setup the global time variable, this will be updated every tick ]]--
	global.time = 0

	--[[
		Setup the global overlays table
		This table contains the machine entity, the signal entity and the freeze variable
	]]--

	if global.overlays == nil then
		global.overlays = {}

		--[[
			Find all assembling machines on the map.
			Check each surface
		]]--
		for name, surface in pairs(game.surfaces) do
			--[[
				Iterate through chunks, and compute min and max values of coordinates
			]]--
			local min_x, min_y, max_x, max_y
			for c in surface.get_chunks() do
				if not min_x then
					min_x = c.x
					max_x = c.x
					min_y = c.y
					max_y = c.y
				else
					if c.x < min_x then
						min_x = c.x
					elseif c.x > max_x then
						max_x = c.x
					end
					if c.y < min_y then
						min_y = c.y
					elseif c.y > max_y then
						max_y = c.y
					end
				end
			end

			--[[
				Bounds are given from min and max values. Must add 32 to max, since chunk coordinates times 32 are smallest (x,y) of that chunk
			]]--
			local bounds = {{min_x*32,min_y*32},{max_x*32+32,max_y*32+32}}

			--[[
				Find all assembling machines within the bounds, and pretend that they were just built
			]]--
			for _, am in pairs(surface.find_entities_filtered{area=bounds, type="assembling-machine"}) do
				built({created_entity = am})
			end

			--[[
				Find all furnaces within the bounds, and pretend that they were just built
			]]--
			for _, am in pairs(surface.find_entities_filtered{area=bounds, type="furnace"}) do
				built({created_entity = am})
			end
		end
	end
end

function on_tick(event)
	--Update the global time variable
	global.time = event.tick
	
	--For every data in global.overlays...
	for index, data in pairs(global.overlays) do
		-- Get the machine entity
		local entity = data.entity
		-- Get the signal entity on this machine
		local signal = data.signal
			
		-- If the machine is not a valid entity (perhaps destroyed?)...
		if not entity.valid then
			-- Remove the signal
			signal.destroy()

			-- Remove entry from overlays
			table.remove(global.overlays, index)

		-- If it is time to refresh the signal
		elseif event.tick >= data.freeze then
			-- Update the machine
			update_machine(data)
		end	
	end
end

--[[ A function to update a machine entity's signal ]]--
function update_machine(data)
	local entity = data.entity
	local signal = data.signal
	local surface = data.entity.surface

	--[[
		compute distance to nearest player
	local playerdist = nil
	for _, player in pairs(game.players) do
		local dx = entity.position.x - player.position.x
		if dx < 0 then dx = -dx end
		local dy = entity.position.y - player.position.y
		if dy < 0 then dy = -dy end
		local dist = dx
		if dy > dist then dist = dy end
		if playerdist == nil or dist < playerdist then playerdist = dist end
	end
	local delay = 60 --playerdist / 8 - 16
	--]]
	
	-- If the machine is crafting something...
	if entity.is_crafting() then
		-- And the signal is not set to green...
		if signal.name ~= "green-bottleneck" then
			-- Destroy the signal
			signal.destroy()
			-- Create a new signal
			data.signal = surface.create_entity({ name = "green-bottleneck", position = entity.position })
			-- TODO: Do a more clever update of freeze. Cannot blindly skip forward, since this might skip warnings
			--data.freeze = global.time + delay
		end
	-- If the machine isn't crafting but have resources in the output slot...
	elseif (entity.type == "assembling-machine" and entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0)
	or (entity.type == "furnace" and entity.get_inventory(defines.inventory.furnace_result).get_item_count() > 0) then
		-- And the signal is not set to yellow...
		if signal.name ~= "yellow-bottleneck" then
			-- Destroy the signal
			signal.destroy()
			-- Create a new signal
			data.signal = surface.create_entity({ name = "yellow-bottleneck", position = entity.position })
			-- TODO: Do a more clever update of freeze. Cannot blindly skip forward, since this might skip warnings
			--data.freeze = global.time + delay
		end
	-- If the machine isn't crafting and has no resources in the output slot (The machine is total idle)...
	else
		-- And the signal is not set to red...
		if signal.name ~= "red-bottleneck" then
			-- Destroy the signal
			signal.destroy()
			-- Create a new signal
			data.signal = surface.create_entity({ name = "red-bottleneck", position = entity.position })
			data.freeze = global.time + 3 * 60
		end
	end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
function built(event)
	local entity = event.created_entity
	local surface = entity.surface
	
	-- If the entity that's been built is an assembly machine or a furnace...
	if entity.type == "assembling-machine"
	or entity.type == "furnace" then
	
		-- Create a new signal ontop of the machine (defaults to red)
		local signal = surface.create_entity({ name = "red-bottleneck", position = entity.position })
		
		-- Insert the data into the global overlays table.
		table.insert(global.overlays, {
			entity = entity,
			signal = signal,
			-- TODO: Do a clever update of freeze.
			freeze = global.time + 3 * 60
		})
	end
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
