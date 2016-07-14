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

function calc_map_bounds()
	-- determine map size
	local min_x, min_y, max_x, max_y = 0, 0, 0, 0
	for c in game.surfaces['nauvis'].get_chunks() do
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
	-- create bounding box covering entire generated map
	return {{min_x*32,min_y*32},{max_x*32,max_y*32}}
end

function init()
	bounds = bounds or calc_map_bounds()
	local surface = game.surfaces['nauvis']
	overlays = {}
	freeze = {}
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
end

function update_machine(entity)
	local surface = game.surfaces['nauvis']
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
	if event.created_entity.type == "assembling-machine" then
		freeze[event.create_entity] = -1
		overlays[event.create_entity] = surface.create_entity{name = "bottleneck-red", position = entity.position}
		update_machine(event.created_entity)
	end
end
