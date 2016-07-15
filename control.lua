require "util"

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end


function on_init()
	--[[
		Setup the global overlays table
		This table contains information about machine/signal positions, surfaces and freeze time
	]]--
	if global.overlays == nil then
		global.overlays = {}
	end
	
	--[[ Setup the global time variable, this will be updated every tick ]]--
	global.time = 0
end

function on_configuration_changed()
	--[[
		Setup the global overlays table
		This table contains information about machine/signal positions, surfaces and freeze time
	]]--
	if global.overlays == nil then
		global.overlays = {}
	end
	
	--[[ Setup the global time variable, this will be updated every tick ]]--
	global.time = 0
end

function on_tick(event)
	--Update the global time variable
	global.time = event.tick
	
	--For every data in global.overlays...
	for index, data in pairs(global.overlays) do
	
		--If the data is not nil (failsafe)...
		if data ~= nil then
			-- Get the surface
			local surface = game.surfaces[data.surface]
		
			-- Find the machine entity (currently only assembly machines and furnaces)
			local entity = surface.find_entity(data.name, data.position)
			-- Get the signal entity on this machine
			local signal = find_signal_at(surface, data.signal_position)
			
			-- If the machine or signal entity is nil (not found)...
			if entity == nil or signal == nil then
				-- If the signal is not gone (this means that the machine is gone)...
				if signal ~= nil then
					-- Remove the signal
					signal.destroy()
				end
				-- Remove the data from the global.overlays index
				global.overlays[index] = nil
				
			-- If the machine and signal entity was found...
			elseif entity ~= nil and signal ~= nil then
			
				-- If the freeze variable of the data is less than the global time variable...
				if data.freeze < global.time then
					-- Update the machine
					update_machine(index, entity, signal, surface)
				end
				
			end
		end
	end
	
end

--[[ A helper function to find a signal entity on a position ]]--
function find_signal_at(surface, position)

	--For some unknown reason, trying to just do surface.find_entity("bottleneck-red", position) doesn't work..
	local entities = surface.find_entities_filtered({area = { {position.x - 0.1, position.y - 0.1}, {position.x + 0.1, position.y + 0.1} }, type = "decorative"})
	
	for _, entity in ipairs(entities) do
		if entity.name == "bottleneck-red" or entity.name == "bottleneck-yellow" or entity.name == "bottleneck-green" then
			return entity
		end
	end
	
	return nil
end

--[[ A function to update a machine entity's signal ]]--
function update_machine(index, entity, signal, surface)
	
	-- If the machine is crafting something...
	if entity.is_crafting() then
		-- And the signal is not set to green...
		if signal.name ~= "bottleneck-green" then
			-- Destroy the signal
			signal.destroy()
			-- Update the global data value to green
			global.overlays[index].signal_name = "bottleneck-green"
			global.overlays[index].freeze = global.time + 1 * 60 -- No need to check every tick.. Once every second should be enough
			-- Create a new signal
			signal = surface.create_entity({ name = "bottleneck-green", position = entity.position })
		end
	-- If the machine isn't crafting but have resources in the output slot...
	elseif (entity.type == "assembly-machine" and entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0)
	or (entity.type == "furnace" and entity.get_inventory(defines.inventory.furnace_result).get_item_count() > 0) then
		-- And the signal is not set to yellow...
		if signal.name ~= "bottleneck-yellow" then
			-- Destroy the signal
			signal.destroy()
			-- Update the global data value to yellow
			global.overlays[index].signal_name = "bottleneck-yellow"
			global.overlays[index].freeze = global.time + 1 * 60 -- No need to check every tick.. Once every second should be enough
			-- Create a new signal
			signal = surface.create_entity({ name = "bottleneck-yellow", position = entity.position })
		end
	-- If the machine isn't crafting and has no resources in the output slot (The machine is total idle)...
	elseif signal.name ~= "bottleneck-red" then
		-- Destroy the signal
		signal.destroy()
		-- Update the global data value to red
		global.overlays[index].signal_name = "bottleneck-red"
		global.overlays[index].freeze = global.time + 3 * 60
		-- Create a new signal
		signal = surface.create_entity({ name = "bottleneck-red", position = entity.position })
	end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
function built(event)
	local entity = event.created_entity
	local surface = entity.surface
	
	-- If the entity that's been built is an assembly machine or a furnace...
	if entity.type == "assembly-machine"
	or entity.type == "furnace" then
	
		-- Create a new signal ontop of the machine (defaults to red)
		local signal = surface.create_entity({ name = "bottleneck-red", position = entity.position })
		
		-- Insert the data into the global overlays table.
		table.insert(global.overlays, {
			name = entity.name, -- The name of the machine entity. This makes it easier to find it later.
			signal_name = 'bottleneck-red', -- The name of the signal entity.
			position = entity.position, -- The position of the machine entity.
			signal_position = signal.position, -- The position of the signal entity (should be the same as the machine entity).
			surface = surface.name, -- The name of the surface the machine entity was built on.
			freeze = global.time + 60 -- Set the freeze variable to update 1 second from now.
		})
	end
end

--[[ Setup event handlers ]]--
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)