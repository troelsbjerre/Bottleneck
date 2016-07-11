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

function find_assembling_machines()
	bounds = bounds or calc_map_bounds()
	local surface = game.surfaces['nauvis']
	overlays = {}
	for _, am in pairs(surface.find_entities_filtered{area=bounds, type="assembling-machine"}) do
		update_machine(am)
	end
	return overlays
end

function update_machine(entity)
	local surface = game.surfaces['nauvis']
	if overlays[entity] ~= nil then
		overlays[entity].destroy()
	end
	if entity.is_crafting() then
		overlays[entity] = surface.create_entity{name = "bottleneck-green", position = entity.position}
	elseif entity.get_inventory(defines.inventory.assembling_machine_output).get_item_count() > 0 then
		overlays[entity] = surface.create_entity{name = "bottleneck-yellow", position = entity.position}
	else
		overlays[entity] = surface.create_entity{name = "bottleneck-red", position = entity.position}
	end
end

function tick(event)
	overlays = overlays or find_assembling_machines()
	for am, ol in pairs(overlays) do
		if not am.valid then
			ol.destroy()
			overlays[am] = nil
		else
			update_machine(am)
		end
	end
end

function built(event)
	if event.created_entity.type == "assembling-machine" then
		update_machine(event.created_entity)
	end
end
