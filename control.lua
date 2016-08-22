require "util"

local show_bottlenecks = true

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end

function init()
	--[[
	-- Check if old version loaded
	--]]
	if (global.overlays ~= nil) then
		if (global.version == nil) or (global.version ~= "0.2.3") then
			global.version = "0.2.3"
			for _, data in pairs(global.overlays) do
				if data.signal then
					data.signal.destroy()
				end
			end
			global.overlays = nil
		end
	end

	--[[
	Setup the global overlays table
	This table contains the machine entity, the signal entity and the freeze variable
	]]--

	if global.overlays == nil then
		global.overlays = {}
		msg("bottleneck: building data from scratch")

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

			--[[
			Find all mining-drills within the bounds, and pretend that they were just built
			]]--
			for _, am in pairs(surface.find_entities_filtered{area=bounds, type="mining-drill"}) do
				built({created_entity = am})
			end
		end
	end
end

function on_tick(event)
	local overlays = global.overlays
	local index = global.update_index or 0
	-- only perform 40 updates per tick
	-- todo: put the magic 40 into config
	for i = 1,math.min(40,#overlays) do
		index = index + 1
		if index > #overlays then
			index = 1
		end

		local data = overlays[index]

		local entity = data.entity
		local signal = data.signal

		-- if entity is valid, update it, otherwise remove the signal and the associated data
		if entity.valid then
			data.update(data)
		else
			if signal then 
				signal.destroy()
			end
			table.remove(overlays, index)
		end
	end
	global.update_index = index
end

function change_signal(data, signal_color)
	local entity = data.entity
	local signal = data.signal
	if show_bottlenecks then
		if (not signal) or signal.name ~= signal_color then
			if signal then
				signal.destroy()
			end
			data.signal = entity.surface.create_entity({ name = signal_color, position = get_bottleneck_position_for(entity) })
		end
	else
		if signal then
			signal.destroy()
			data.signal = nil
		end
	end
end

function update_drill(data)
	local entity = data.entity
	local progress = data.progress

	if (entity.mining_target == nil) or (entity.energy == 0) then
		change_signal(data, "red-bottleneck")
	elseif (entity.mining_progress == progress) then
		change_signal(data, "yellow-bottleneck")
	else
		change_signal(data, "green-bottleneck")
		data.progress = entity.mining_progress
	end
end

function update_machine(data)
	local entity = data.entity

	if entity.energy == 0 then
		change_signal(data, "red-bottleneck")
	elseif entity.is_crafting() 
		and (entity.crafting_progress < 1) 
		and (entity.bonus_progress < 1) then
		change_signal(data, "green-bottleneck")
	elseif (entity.crafting_progress >= 1) -- has a full output buffer
		or (entity.bonus_progress >= 1) -- has a full bonus buffer
		or (entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0) then
		change_signal(data, "yellow-bottleneck")
	else
		change_signal(data, "red-bottleneck")
	end
end

function update_furnace(data)
	local entity = data.entity

	if entity.energy == 0 then
		change_signal(data, "red-bottleneck")
	elseif entity.is_crafting() 
		and (entity.crafting_progress < 1) 
		and (entity.bonus_progress < 1) then
		change_signal(data, "green-bottleneck")
	elseif (entity.crafting_progress >= 1) -- has a full output buffer
		or (entity.bonus_progress >= 1) -- has a full bonus buffer
		or (entity.get_inventory(defines.inventory.furnace_result).get_item_count() > 0) then
		change_signal(data, "yellow-bottleneck")
	else
		change_signal(data, "red-bottleneck")
	end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
function built(event)
	local entity = event.created_entity
	local surface = entity.surface

	-- If the entity that's been built is an assembly machine or a furnace...
	if entity.type == "assembling-machine" then
		local signal = surface.create_entity({ name = "red-bottleneck", position = get_bottleneck_position_for(entity)})
		table.insert(global.overlays, {
			entity = entity,
			signal = signal,
			update = update_machine,
		})
	elseif entity.type == "furnace" then
		local signal = surface.create_entity({ name = "red-bottleneck", position = get_bottleneck_position_for(entity)})
		table.insert(global.overlays, {
			entity = entity,
			signal = signal,
			update = update_furnace,
		})
	elseif entity.type == "mining-drill" then
		local signal = surface.create_entity({ name = "red-bottleneck", position = get_bottleneck_position_for(entity)})
		table.insert(global.overlays, {
			entity = entity,
			signal = signal,
			progress = 0,
			update = update_drill,
		})
	end
end

--[[ Calculates bottom center of the entity to place bottleneck there ]]
function get_bottleneck_position_for(entity)
	local left_top = entity.prototype.selection_box.left_top
	local right_bottom = entity.prototype.selection_box.right_bottom
	--Calculating center of the selection box
	local shift_x = (right_bottom.x + left_top.x) / 2
	local shift_y = right_bottom.y
	--Calculating bottom center of the selection box
	local bottleneck_position = {x = entity.position.x + shift_x, y = entity.position.y + shift_y}
	return bottleneck_position --entity.position
end

function on_hotkey(event)
	show_bottlenecks = not show_bottlenecks
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
script.on_event("bottleneck-hotkey", on_hotkey)
