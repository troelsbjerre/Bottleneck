require "util"

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end


function on_init()
	--[[
		Setup the global overlays table
		This table contains the machine entity, the signal entity and the freeze variable
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
		This table contains the machine entity, the signal entity and the freeze variable
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
			-- Get the machine entity
			local entity = data.entity
			-- Get the signal entity on this machine
			local signal = data.signal
			
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
				
				-- If the machine is not a valid entity (perhaps destroyed?)...
				if not entity.valid then
					-- If the signal is a valid entity...
					if signal.valid then
						-- Remove the signal
						signal.destroy()
					end
					
					-- Remove the data from the global.overlays index
					global.overlays[index] = nil
				end
			
				-- If the freeze variable of the data is less than the global time variable...
				if global.overlays[index] ~= nil and data.freeze < global.time then
					-- Get the surface
					local surface = data.entity.surface or data.signal.surface
					-- Update the machine
					update_machine(index, entity, signal, surface)
				end
				
			end
		end
	end
	
end

--[[ A function to update a machine entity's signal ]]--
function update_machine(index, entity, signal)
	local surface = entity.surface or signal.surface
	
	-- If the machine is crafting something...
	if entity.is_crafting() then
		-- And the signal is not set to green...
		if signal.name ~= "bottleneck-green" then
			-- Destroy the signal
			signal.destroy()
			-- Create a new signal
			signal = surface.create_entity({ name = "bottleneck-green", position = entity.position })
			-- Update the global data value to green
			global.overlays[index].signal = signal
			global.overlays[index].freeze = global.time + 1 * 60 -- No need to check every tick.. Once every second should be enough
		end
	-- If the machine isn't crafting but have resources in the output slot...
	elseif (entity.type == "assembly-machine" and entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0)
	or (entity.type == "furnace" and entity.get_inventory(defines.inventory.furnace_result).get_item_count() > 0) then
		-- And the signal is not set to yellow...
		if signal.name ~= "bottleneck-yellow" then
			-- Destroy the signal
			signal.destroy()
			-- Create a new signal
			signal = surface.create_entity({ name = "bottleneck-yellow", position = entity.position })
			-- Update the global data value to yellow
			global.overlays[index].signal = signal
			global.overlays[index].freeze = global.time + 1 * 60 -- No need to check every tick.. Once every second should be enough
		end
	-- If the machine isn't crafting and has no resources in the output slot (The machine is total idle)...
	elseif signal.name ~= "bottleneck-red" then
		-- Destroy the signal
		signal.destroy()
		-- Create a new signal
		signal = surface.create_entity({ name = "bottleneck-red", position = entity.position })
		-- Update the global data value to red
		global.overlays[index].signal = signal
		global.overlays[index].freeze = global.time + 3 * 60
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
			entity = entity,
			signal = signal,
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