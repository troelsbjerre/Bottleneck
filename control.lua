-------------------------------------------------------------------------------
--[[Bottleneck]]--
-------------------------------------------------------------------------------
--[[ code modified from AutoDeconstruct mod by mindmix https://mods.factorio.com/mods/mindmix ]]
local function check_drill_depleted(data)
    local drill = data.entity
    local position = drill.position
    local range = drill.prototype.mining_drill_radius
    local top_left = {x = position.x - range, y = position.y - range}
    local bottom_right = {x = position.x + range, y = position.y + range}
    local resources = drill.surface.find_entities_filtered{area={top_left, bottom_right}, type='resource'}
    for _, resource in pairs(resources) do
        if resource.prototype.resource_category == 'basic-solid' and resource.amount > 0 then
            return false
        end
    end
    data.drill_depleted = true
    return true
end

local function has_fluid_output_available(entity)
    local fluidbox = entity.fluidbox
    if fluidbox and #fluidbox > 0 and entity.recipe then
        local recipe = entity.recipe
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
    end
    return false
end

local LIGHT = {
    off = 0,
    green = 1,
    red = 2,
    yellow = 3,
    blue = 4,
    redx = 5,
    yellowmin = 6,
    offsmall = 7,
    greensmall = 8,
    redsmall = 9,
    yellowsmall = 10,
    bluesmall = 11,
    redxsmall = 12,
    yellowminsmall = 13,
}

--Faster to just change the color than it is to check it first.
local function change_signal(signal, signal_color)
    if settings.global["bottleneck-high-contrast"].value then
		if signal_color == "yellow" then
			signal_color = "blue"
		end
    end
    signal.graphics_variation = LIGHT[signal_color] or 0
end

--[[ Remove the LIGHT]]
local function remove_signal(event)
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
end

--[[ Calculates bottom center of the entity to place bottleneck there ]]
local function get_signal_position_from(entity)
    local left_top = entity.prototype.selection_box.left_top
    local right_bottom = entity.prototype.selection_box.right_bottom
    --Calculating center of the selection box
    local x = (right_bottom.x + left_top.x) / 2
    local y = right_bottom.y
    --Calculating bottom center of the selection box
    return {x = entity.position.x + x, y = entity.position.y + y}
end


local function new_signal(entity, variation)
    local signal = entity.surface.create_entity{name = "bottleneck-stoplight", position = get_signal_position_from(entity), force = entity.force}
    signal.graphics_variation = (not settings.global["bottleneck-enabled"].value and LIGHT["off"]) or variation or LIGHT["red"]
    signal.destructible = false
    return signal
end

local function entity_moved(event, data)
    data = data or global.overlays[event.moved_entity.unit_number]
    if data then
        if data.signal and data.signal.valid then
            --Not sure why this position hack is needed but it works.
            local position = get_signal_position_from(event.moved_entity)
            position.x = position.x + .5
            data.signal.teleport(position)
        end
    end
end

local update = {}
function update.drill(data)
    if not data.drill_depleted then
        local entity = data.entity
        local progress = data.progress
        if (entity.energy == 0) or (entity.mining_target == nil and check_drill_depleted(data)) then
            change_signal(data.signal, "red")
        elseif (entity.mining_progress == progress) then
            change_signal(data.signal, "yellow")
        else
            change_signal(data.signal, "green")
            data.progress = entity.mining_progress
        end
    end
end

function update.machine(data)
    local entity = data.entity
    if entity.energy == 0 then
        change_signal(data.signal, "red")
    elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
        change_signal(data.signal, "green")
    elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
        change_signal(data.signal, "yellow")
    else
        change_signal(data.signal, "red")
    end
end

function update.furnace(data)
    local entity = data.entity
    if entity.energy == 0 then
        change_signal(data.signal, "red")
    elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
        change_signal(data.signal, "green")
    elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
        change_signal(data.signal, "yellow")
    else
        change_signal(data.signal, "red")
    end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
local function built(event)
    local entity = event.created_entity
    local data
    -- If the entity that's been built is an assembly machine or a furnace...
    if entity.type == "assembling-machine" then
        data = { update = "machine" }
    elseif entity.type == "furnace" then
        data = { update = "furnace" }
    elseif entity.type == "mining-drill" and entity.name ~= "factory-port-marker" then
        data = { update = "drill" }
    end

    if data then
        data.entity = entity
        data.signal = new_signal(entity)

        --update[data.update](data)
        global.overlays[entity.unit_number] = data
        -- if we are in the process of removing LIGHTs, we need to restart
        -- that, since inserting into the overlays table may mess up the
        -- iteration order.
        if global.show_bottlenecks == -1 then
            global.update_index = nil
        end
    end
end

local function rebuild_overlays()
    --[[Setup the global overlays table This table contains the machine entity, the signal entity and the freeze variable]]--
    global.overlays = {}
    global.update_index = nil
    game.print("Bottleneck: Rebuilding data from scratch")

    --[[Find all assembling machines on the map. Check each surface]]--
    for _, surface in pairs(game.surfaces) do
        --find-entities-filtered with no area argument scans for all entities in loaded chunks and should
        --be more effiecent then scanning through all chunks like in previous version

        --[[destroy any existing bottleneck-signals]]--
        for _, stoplight in pairs(surface.find_entities_filtered{name="bottleneck-stoplight"}) do
            stoplight.destroy()
        end

        --[[Find all assembling machines within the bounds, and pretend that they were just built]]--
        for _, am in pairs(surface.find_entities_filtered{type="assembling-machine"}) do
            built({created_entity = am})
        end

        --[[Find all furnaces within the bounds, and pretend that they were just built]]--
        for _, am in pairs(surface.find_entities_filtered{type="furnace"}) do
            built({created_entity = am})
        end

        --[[Find all mining-drills within the bounds, and pretend that they were just built]]--
        for _, am in pairs(surface.find_entities_filtered{type="mining-drill"}) do
            built({created_entity = am})
        end
    end
end

local next = next --very slight perfomance improvment
local function on_tick()
    if global.show_bottlenecks == 1 then
        local signals_per_tick = settings.global["bottleneck-signals-per-tick"].value
        local overlays = global.overlays
        local index, data = global.update_index
        --check for existing data at index
        if index and overlays[index] then
            data = overlays[index]
        else
            index, data = next(overlays, index)
        end
        local numiter = 0
        while index and (numiter < signals_per_tick) do
            local entity = data.entity
            --local signal = data.signal

            -- if entity is valid, update it, otherwise remove the signal and the associated data
            if entity.valid and data.signal.valid then
                update[data.update](data)
            elseif entity.valid and not data.signal.valid then
                -- Rebuild the icon something broke it!
                data.signal = new_signal(entity)
            elseif not entity.valid and data.signal.valid then
                data.signal.destroy()
                overlays[index] = nil
            end
            numiter = numiter + 1
            index, data = next(overlays, index)
        end
        global.update_index = index
    elseif global.show_bottlenecks < 0 then
        local show, signals_per_tick = global.show_bottlenecks, settings.global["bottleneck-signals-per-tick"].value
        local overlays = global.overlays
        local index, data = global.update_index
        --Check for existing index and associated data
        if index and overlays[index] then
            data = overlays[index]
        else
            index, data = next(overlays, index)
        end
        local numiter = 0
        while index and (numiter < signals_per_tick) do
            local signal = data.signal
            if signal and signal.valid then
                if show == -1 then
                    change_signal(signal, "off")
                elseif show == -2 then
                    local current_variation = signal.graphics_variation
                    signal.destroy()
                    data.signal = new_signal(data.entity, current_variation)
                end
            else
                overlays[index] = nil
            end
            numiter = numiter + 1
            index, data = next(overlays, index)
        end
        global.update_index = index
        -- if we have reached the end of the list (i.e., have removed all LIGHTs),
        -- pause updating until enabled by hotkey next
        if not index then
            global.show_bottlenecks = (show == -2 and 1) or (show == -1 and 0)
        end
    end
end

local function update_settings(event)
    if event.setting == "bottleneck-enabled" then
        global.show_bottlenecks = settings.global["bottleneck-enabled"].value and 1 or -1
		global.update_index = nil
    end
    if event.setting == "bottleneck-high-contrast" then
        --highcontrast switch here

        global.update_index = nil
        global.show_bottlenecks = global.show_bottlenecks > 0 and -2 or global.show_bottlenecks
    end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, update_settings)

-------------------------------------------------------------------------------
--[[Init Events]]
local function register_conditional_events()
    if remote.interfaces["picker"] and remote.interfaces["picker"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("picker", "dolly_moved_entity_id"), entity_moved)
    end
end

local function init()
    --seperate out init and config changed
    global = {}
    global.show_bottlenecks = (settings.global["bottleneck-enabled"].value and 1) or -1
    rebuild_overlays()
    register_conditional_events()
end

local function on_load()
    register_conditional_events()
end

local function on_configuration_changed(event)
    --Any MOD has been changed/added/removed, including base game updates.
    if event.mod_changes then
        game.print("Bottleneck: Game or mod version changes detected")
        --This mod has changed
        local changes = event.mod_changes["Bottleneck"]
        if changes ~= nil then -- THIS Mod has changed
            game.print("Bottleneck: Updated from ".. tostring(changes.old_version) .. " to " .. tostring(changes.new_version))
            global.show_bottlenecks = (settings.global["bottleneck-enabled"].value and 1) or -1
            global.signals_per_tick = nil
            global.lights_per_tick = nil
            global.showbottlenecks = nil
            global.output_idle_signal = nil
            global.high_contrast = nil
        end
    end
    rebuild_overlays()
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(on_configuration_changed)
script.on_load(on_load)

local e=defines.events
local remove_events = {e.on_preplayer_mined_item, e.on_robot_pre_mined, e.on_entity_died}
local add_events = {e.on_built_entity, e.on_robot_built_entity}

script.on_event(remove_events, remove_signal)
script.on_event(add_events, built)
script.on_event(defines.events.on_tick, on_tick)

--[[ Setup remote interface]]--
local interface = {}
--is_enabled - return show_bottlenecks
interface.enabled = function() return settings.global["bottleneck-enabled"].value end
--print the global to a file
interface.print_global = function () game.write_file("Bottleneck/global.lua", serpent.block(global, {nocode=true, comment=false})) end
--rebuild all icons
interface.rebuild = rebuild_overlays
--allow other mods to interact with bottleneck
interface.entity_moved = entity_moved
interface.get_lights = function() return LIGHT end
interface.new_signal = new_signal
interface.change_signal = change_signal --function(data, color) change_signal(signal, color) end
--get a place position for a signal
interface.get_position_for_signal = get_signal_position_from
--get the signal data associated with an entity
interface.get_signal_data = function(unit_number) return global.overlays[unit_number] end

remote.add_interface("Bottleneck", interface)
