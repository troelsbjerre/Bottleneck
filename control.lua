require "util"

local show_bottlenecks = 1

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end

function init()
	if (global.output_idle_signal == nil) then
		global.output_idle_signal = "yellow-bottleneck"
	end
	--[[
	-- Check if old version loaded.
	--]]
	if (global.overlays ~= nil) then
		if (global.version == nil) or (global.version ~= "0.5.0") then
			global.version = "0.5.0"
			global.update_index = nil
			for _, data in pairs(global.overlays) do
				local signal = data.signal
				if signal and signal.valid then
					signal.destroy()
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
		msg("Bottleneck: building data from scratch")

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

			if min_x then
				--[[
				Bounds are given from min and max values. Must add 32 to max, since chunk coordinates times 32 are smallest (x,y) of that chunk
				]]--
				local bounds = {{min_x*32,min_y*32},{max_x*32+32,max_y*32+32}}

				--[[
				destroy any existing bottleneck-signals
				]]--
				for _, signal in pairs(surface.find_entities_filtered{area=bounds, name="green-bottleneck"}) do
					signal.destroy()
				end
				for _, signal in pairs(surface.find_entities_filtered{area=bounds, name="yellow-bottleneck"}) do
					signal.destroy()
				end
				for _, signal in pairs(surface.find_entities_filtered{area=bounds, name="red-bottleneck"}) do
					signal.destroy()
				end
				for _, signal in pairs(surface.find_entities_filtered{area=bounds, name="blue-bottleneck"}) do
					signal.destroy()
				end

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
end

function on_tick(event)
	if show_bottlenecks == 1 then
		local overlays = global.overlays
		local index = next(overlays, global.update_index)
		local numiter = 0
		-- only perform 40 updates per tick
		-- todo: put the magic 40 into config
		while index and (numiter < 40) do
			-- save the next element, in case we need to remove the current index
			local nextindex = next(overlays, index)

			local data = overlays[index]
			local entity = data.entity
			local signal = data.signal

			-- if entity is valid, update it, otherwise remove the signal and the associated data
			if entity.valid then
				data.update(data)
			else
				if signal and signal.valid then
					signal.destroy()
				end
				overlays[index] = nil
			end
			numiter = numiter + 1
			index = nextindex
		end
		global.update_index = index
	elseif show_bottlenecks == -1 then
		local overlays = global.overlays
		local index = next(overlays, global.update_index)
		local numiter = 0
		-- only perform 40 updates per tick
		-- todo: put the magic 40 into config
		while index and (numiter < 40) do
			local data = overlays[index]
			local signal = data.signal

			-- if signal exists, destroy it
			if signal and signal.valid then
				signal.destroy()
			end
			numiter = numiter + 1
			index = next(overlays, index)
		end
		global.update_index = index
		-- if we have reached the end of the list (i.e., have removed all lights), pause updating until enabled by hotkey next
		if not index then
			show_bottlenecks = 0
		end
	end
end

function change_signal(data, signal_color)
	local entity = data.entity
	local signal = data.signal
	if (not signal) or (not signal.valid) or signal.name ~= signal_color then
		if signal and signal.valid then
			signal.destroy()
		end
		data.signal = entity.surface.create_entity({ name = signal_color, position = data.position })
	end
end

function update_drill(data)
	if data.drill_depleted then return end
	local entity = data.entity
	local progress = data.progress

	if (entity.energy == 0) or (entity.mining_target == nil and check_drill_depleted(data)) then
		change_signal(data, "red-bottleneck")
	elseif (entity.mining_progress == progress) then
		change_signal(data, global.output_idle_signal)
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
		or (not entity.get_output_inventory().is_empty())
		or (has_fluid_output_available(entity)) then
		change_signal(data, global.output_idle_signal)
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
		or (not entity.get_output_inventory().is_empty())
		or (has_fluid_output_available(entity)) then
		change_signal(data, global.output_idle_signal)
	else
		change_signal(data, "red-bottleneck")
	end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
function built(event)
	local entity = event.created_entity
	local surface = entity.surface
	local data = nil

	-- If the entity that's been built is an assembly machine or a furnace...
	if entity.type == "assembling-machine" then
		data = { update = update_machine }
	elseif entity.type == "furnace" then
		data = { update = update_furnace }
	elseif entity.type == "mining-drill" then
		data = { update = update_drill }
	end
	if data then
		data.entity = entity
		data.position = get_bottleneck_position_for(entity)
		if show_bottlenecks == 1 then
			data.update(data)
		end
		global.overlays[entity.unit_number] = data
		-- if we are in the process of removing lights, we need to restart
		-- that, since inserting into the overlays table may mess up the
		-- iteration order.
		if show_bottlenecks == -1 then
			global.update_index = nil
		end
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

--[[ code modified from AutoDeconstruct mod by mindmix https://mods.factorio.com/mods/mindmix ]]
function check_drill_depleted(data)
	local drill = data.entity
	local position = drill.position
	local range = drill.prototype.mining_drill_radius
	local top_left = {x = position.x - range, y = position.y - range}
	local bottom_right = {x = position.x + range, y = position.y + range}
	local resources = drill.surface.find_entities_filtered{area={top_left, bottom_right}, type='resource'}
	for _, resource in pairs(resources) do
		if resource.prototype.resource_category == 'basic-solid' and  resource.amount > 0 then 
			return false
		end
	end
	data.drill_depleted = true
	return true
end

function has_fluid_output_available(entity)
	local fluidbox = entity.fluidbox
	if (not fluidbox) or (#fluidbox == 0) then return false end
	local recipe = entity.recipe
	if not recipe then return false end
	for _, product in pairs(recipe.products) do
		if product.type == 'fluid' then
			local name = product.name
			for i = 1, #fluidbox do
				local fluid = fluidbox[i]
				if fluid and (fluid.type == name) and (fluid.amount > 0) then 
					return true
				end
			end
		end
	end
	return false
end

function on_hotkey(event)
	local player = game.players[event.player_index]
	if not player.admin then
		player.print('Bottleneck: you do not have privileges to toggle bottleneck')
		return
	end
	global.update_index = nil
	if show_bottlenecks == 1 then
		show_bottlenecks = -1
	else
		show_bottlenecks = 1
	end
end

function toggle_highcontrast(event)
	local player = game.players[event.player_index]
	if global.output_idle_signal ~= "yellow-bottleneck" then
		global.output_idle_signal = "yellow-bottleneck"
		msg('Bottleneck: high contrast mode disabled')
	else
		global.output_idle_signal = "blue-bottleneck"
		msg('Bottleneck: high contrast mode enabled')
	end
end

function remove_light(event)
	local entity = event.entity
	local index = entity.unit_number
	local overlays = global.overlays
	local data = overlays[index]
	if not data then return end
	local signal = data.signal
	if signal and signal.valid then
		signal.destroy()
	end
	overlays[index] = nil
	--table.remove(overlays, index)
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(init)
script.on_event(defines.events.on_preplayer_mined_item, remove_light)
script.on_event(defines.events.on_robot_pre_mined, remove_light)
script.on_event(defines.events.on_entity_died, remove_light)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
script.on_event("bottleneck-hotkey", on_hotkey)
script.on_event("bottleneck-highcontrast", toggle_highcontrast)
