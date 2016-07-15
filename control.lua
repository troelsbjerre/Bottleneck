require "util"

function msg(message)
	for _,p in pairs(game.players) do
		p.print(message)
	end
end

script.on_event(defines.events.on_tick, function(event)
	tick(event)
end)

script.on_event(defines.events.on_built_entity, function(event)
	built(event)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	built(event)
end)

function init()
	overlays = {}
	freeze = {}
	for name, surface in pairs(game.surfaces) do
		local min_x, min_y, max_x, max_y
		for c in game.surfaces['nauvis'].get_chunks() do
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
		local bounds = {{min_x*32,min_y*32},{max_x*32+32,max_y*32+32}}
		-- Clear up any mess made in previous saves
		for _, ol in pairs(surface.find_entities_filtered{area=bounds, name="bottleneck-green"}) do
			ol.destroy()
		end
		for _, ol in pairs(surface.find_entities_filtered{area=bounds, name="bottleneck-yellow"}) do
			ol.destroy()
		end
		for _, ol in pairs(surface.find_entities_filtered{area=bounds, name="bottleneck-red"}) do
			ol.destroy()
		end
		for _, am in pairs(surface.find_entities_filtered{area=bounds, type="assembling-machine"}) do
			freeze[am] = -1
			overlays[am] = surface.create_entity{name = "bottleneck-red", position = am.position}
			update_machine(am)
		end
		for _, am in pairs(surface.find_entities_filtered{area=bounds, type="furnace"}) do
			freeze[am] = -1
			overlays[am] = surface.create_entity{name = "bottleneck-red", position = am.position}
			update_machine(am)
		end
	end
end

function update_machine(entity)
	local surface = entity.surface
	if entity.is_crafting() then
		if overlays[entity].name ~= "bottleneck-green" then
			overlays[entity].destroy()
			overlays[entity] = surface.create_entity{name = "bottleneck-green", position = entity.position}
		end
	elseif entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0 then
		if overlays[entity].name ~= "bottleneck-yellow" then
			overlays[entity].destroy()
			overlays[entity] = surface.create_entity{name = "bottleneck-yellow", position = entity.position}
		end
	else
		if overlays[entity].name ~= "bottleneck-red" then
			overlays[entity].destroy()
			overlays[entity] = surface.create_entity{name = "bottleneck-red", position = entity.position}
			freeze[entity] = time + 3 * 60
		end
	end
end

function tick(event)
	if not overlays then init() end
	time = event.tick
	for am, ol in pairs(overlays) do
		if not am.valid then
			ol.destroy()
			overlays[am] = nil
		else
			if freeze[am] < time then
				update_machine(am)
			end
		end
	end
end

function built(event)
	local entity = event.created_entity
	local surface = entity.surface
	if event.created_entity.type == "assembling-machine"
	or event.created_entity.type == "furnace" then
		freeze[entity] = -1
		overlays[entity] = surface.create_entity{name = "bottleneck-red", position = entity.position}
		update_machine(entity)
	end
end
