-------------------------------------------------------------------------------
--[[Bottleneck]]--
-------------------------------------------------------------------------------

local bn_enabled = (settings.global["bottleneck-enabled"].value and 1) or -1
local bn_high_contrast = settings.global["bottleneck-high-contrast"].value
local bn_signals_per_tick = settings.global["bottleneck-signals-per-tick"].value
local bn_show_green = settings.global["bottleneck-show-green-signal"].value

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

--Api request sent to make this faster
--https://forums.factorio.com/viewtopic.php?f=28&t=48100
local function has_fluid_output_available(entity)
    local fluidbox = entity.fluidbox
    if entity.recipe and fluidbox and #fluidbox > 0 then
        for _, product in pairs(entity.recipe.products) do
            if product.type == 'fluid' then
                for i = 1, #fluidbox do
                    local fluid = fluidbox[i]
                    if fluid and (fluid.type == product.name) and (fluid.amount > 0) then
                        return true
                    end
                end
            end
        end
    end
end

local LIGHT = {
    off = 1, green = 2, red = 3, yellow = 4, blue = 5, redx = 6, yellowmin = 7,
    offsmall = 8,  greensmall = 9, redsmall = 10, yellowsmall = 11,
    bluesmall = 12, redxsmall = 13, yellowminsmall = 14,
}

local STATES = {
    OFF = 1, RUNNING = 2, STOPPED = 3, FULL = 4,
}

--Faster to just change the color than it is to check it first.
local function change_signal(data, signal_color, status)
    if signal_color == "yellow" and bn_high_contrast then
        signal_color = "blue"
    elseif signal_color == "green" and not bn_show_green then
        signal_color = "off"
    end
    data.signal.graphics_variation = LIGHT[signal_color] or 1
    data.status = status or STATES.OFF
end

--[[ Remove the LIGHT]]
local function remove_signal(event)
    local entity = event.entity
    local index = entity.unit_number
    local overlays = global.overlays
    local data = overlays[index]
    if data then
        local signal = data.signal
        if signal and signal.valid then
            signal.destroy()
        end
        overlays[index] = nil
    end
end

--[[ Calculates bottom center of the entity to place bottleneck there ]]
local function get_signal_position_from(entity)
    local left_top = entity.prototype.selection_box.left_top
    local right_bottom = entity.prototype.selection_box.right_bottom
    --Calculating center of the selection box
    local center = (left_top.x + right_bottom.x) / 2
    local width = math.abs(left_top.x) + right_bottom.x
    -- Set Shift here if needed, The offset looks better as it doesn't cover up fluid input information
    -- Ignore shift for 1 tile entities
    local x = (width > 1.25 and center - 0.5) or center
    local y = right_bottom.y
    --Calculating bottom center of the selection box
    return {x = entity.position.x + x, y = entity.position.y + y}
end

local function new_signal(entity, variation)
    local signal = entity.surface.create_entity{name = "bottleneck-stoplight", position = get_signal_position_from(entity), force = entity.force}
    signal.graphics_variation = (bn_enabled < 1 and LIGHT["off"]) or variation or LIGHT["red"]
    signal.destructible = false
    return signal
end

local function entity_moved(event, data)
    data = data or global.overlays[event.moved_entity.unit_number]
    if data then
        if data.signal and data.signal.valid then
            data.drill_depleted = false
            local position = get_signal_position_from(event.moved_entity)
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
            change_signal(data, "red", STATES.STOPPED)
        elseif (entity.mining_progress == progress) then
            change_signal(data, "yellow", STATES.FULL)
        else
            change_signal(data, "green", STATES.RUNNING)
            data.progress = entity.mining_progress
        end
    end
end

function update.machine(data)
    local entity = data.entity
    if entity.energy == 0 then
        change_signal(data, "red", STATES.STOPPED)
    elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
        change_signal(data, "green", STATES.RUNNING)
    elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
        change_signal(data, "yellow", STATES.FULL)
    else
        change_signal(data, "red", STATES.STOPPED)
    end
end

function update.furnace(data)
    local entity = data.entity
    if entity.energy == 0 then
        change_signal(data, "red", STATES.STOPPED)
    elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
        change_signal(data, "green", STATES.RUNNING)
    elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
        change_signal(data, "yellow", STATES.FULL)
    else
        change_signal(data, "red", STATES.STOPPED)
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
        data.status = STATES.STOPPED

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
    --game.print("Bottleneck: Rebuilding data from scratch")

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

local function on_tick()
    local show_bottlenecks = global.show_bottlenecks
    if show_bottlenecks ~= 0 then
        local next = next --very slight perfomance improvment

        local signals_per_tick = bn_signals_per_tick

        local overlays = global.overlays
        local index = global.update_index
        local data

        --check for existing data at index
        if index and overlays[index] then
            data = overlays[index]
        else
            index, data = next(overlays, index)
        end

        local numiter = 0
        while index and (numiter < signals_per_tick) do
            local entity = data.entity
            if entity.valid then -- if entity is valid, update it, otherwise remove the signal and the associated data
                if data.signal.valid then
                    if show_bottlenecks > 0 then
                        update[data.update](data)
                    else
                        change_signal(data, "off")
                    end
                else -- Rebuild the icon something broke it!
                    data.signal = new_signal(entity)
                end
            else -- Machine is gone
                if data.signal.valid then
                    data.signal.destroy() -- Signal is there; remove it
                end
                overlays[index] = nil -- forget about the machine
            end
            numiter = numiter + 1
            index, data = next(overlays, index)
        end
        global.update_index = index
        -- if we have reached the end of the list (i.e., have removed all LIGHTs),
        -- pause updating until enabled by hotkey next
        if not index and show_bottlenecks <= 0 then
            global.show_bottlenecks = 0
            --We have cycled everything to off, disable the tick handler
            script.on_event(defines.events.on_tick, nil)
        end
    end
end

local function update_settings(event)
    if event.setting == "bottleneck-enabled" then
        global.show_bottlenecks = settings.global["bottleneck-enabled"].value and 1 or -1
        global.update_index = nil
        --Toggling the setting doesn't disable right way, make sure the handler gets
        --reenabled to toggle colors to their correct values.
        script.on_event(defines.events.on_tick, on_tick)
    end
    if event.setting == "bottleneck-signals_per_tick" then
        bn_signals_per_tick = settings.global["bottleneck-signals-per-tick"].value
    end
    if event.setting == "bottleneck-show-green-signal" then
        bn_show_green = settings.global["bottleneck-show-green-signal"].value
        global.update_index = nil
    end
    if event.setting == "bottleneck-high-contrast" then
        bn_high_contrast = settings.global["bottleneck-high-contrast"].value
        global.update_index = nil
    end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, update_settings)

-------------------------------------------------------------------------------
--[[Init Events]]
local function register_conditional_events()
    if remote.interfaces["picker"] and remote.interfaces["picker"]["dolly_moved_entity_id"] then
        script.on_event(remote.call("picker", "dolly_moved_entity_id"), entity_moved)
    end
    if global.show_bottlenecks ~= 0 then
        --Register the tick handler if we are showing bottlenecks
        script.on_event(defines.events.on_tick, on_tick)
    end
end

local function init()
    global.overlays = {}
    global.show_bottlenecks = (bn_enabled and 1) or 0
    --register the tick handler if we are showing bottlenecks
    if global.show_bottlenecks then
        script.on_event(defines.events.on_tick, on_tick)
    end
    rebuild_overlays()
    register_conditional_events()
end

local function on_load()
    register_conditional_events()
end

local function on_configuration_changed(event)
    --Any MOD has been changed/added/removed, including base game updates.
    if event.mod_changes then
        --This mod has changed
        local changes = event.mod_changes["Bottleneck"]
        if changes then -- THIS Mod has changed
            game.print("Bottleneck: Updated from ".. tostring(changes.old_version) .. " to " .. tostring(changes.new_version))
            global.show_bottlenecks = (bn_enabled and 1) or 0
            --Clean up old variables
            global.lights_per_tick = nil
            global.signals_per_tick = nil
            global.showbottlenecks = nil
            global.output_idle_signal = nil
            global.high_contrast = nil
        end
        global.overlays = {}
        rebuild_overlays()
    end
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(on_configuration_changed)
script.on_load(on_load)

local e=defines.events
local remove_events = {e.on_player_mined_entity, e.on_robot_pre_mined, e.on_entity_died}
local add_events = {e.on_built_entity, e.on_robot_built_entity}

script.on_event(remove_events, remove_signal)
script.on_event(add_events, built)

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
interface.get_states = function() return STATES end
interface.new_signal = new_signal
interface.change_signal = change_signal --function(data, color) change_signal(signal, color) end
--get a place position for a signal
interface.get_position_for_signal = get_signal_position_from
--get the signal data associated with an entity
interface.get_signal_data = function(unit_number) return global.overlays[unit_number] end

remote.add_interface("Bottleneck", interface)
