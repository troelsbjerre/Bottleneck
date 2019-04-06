-------------------------------------------------------------------------------
--[[Bottleneck]]--
-------------------------------------------------------------------------------

local bn_signals_per_tick = settings.global["bottleneck-signals-per-tick"].value

local SPRITE = {
    off = {
        sprite = 'bottleneck_white',
        tint = {r=0, g=0, b=0},
        visible=false
    },
    green = {
        sprite = 'bottleneck_white',
        tint = {g = 1},
        visible=true
    },
    red = {
        sprite = 'bottleneck_white',
        tint = {r = 1},
        visible=true
    },
    yellow = {
        sprite = 'bottleneck_white',
        tint = {r = 1, g=1},
        visible=true
    },
    blue = {
        sprite = 'bottleneck_white',
        tint = {b = 1},
        visible=true
    },
    redx  = {
        sprite = 'bottleneck_cross',
        tint = {r = 1},
        visible=true
    },
    yellowmin = {
        sprite = 'bottleneck_minus',
        tint = {r = 1, g=1},
        visible=true
    },
    offsmall = {
        sprite = 'bottleneck_offsmall',
        visible=true
    },
    greensmall = {
        sprite = 'bottleneck_white_small',
        tint = {g = 1},
        visible=true
    },
    redsmall = {
        sprite = 'bottleneck_white_small',
        tint = {r = 1},
        visible=true
    },
    yellowsmall = {
        sprite = 'bottleneck_white_small',
        tint = {r = 1, g=1},
        visible=true
    },
    bluesmall = {
        sprite = 'bottleneck_white_small',
        visible=true
    },
    redxsmall  = {
        sprite = 'bottleneck_cross_small',
        tint = {r = 1},
        visible=true
    },
    yellowminsmall = {
        sprite = 'bottleneck_minus_small',
        tint = {r = 1, g=1},
        visible=true
    }
}

local SPRITE_STYLE = {}

local ENTITY_TYPES = {
    ['assembling-machine'] = true,
    ['lab'] = true,
    ['furnace'] = true,
    ['mining-drill'] = true
}

local function change_sprite(data, style)
    local sprite = data.sprite
    rendering.set_sprite(sprite, style.sprite)
    rendering.set_visible(sprite, style.visible)
    rendering.set_color(sprite, style.tint)
end

--[[ Calculates bottom center of the entity to place bottleneck there ]]
local function get_render_offset_from(entity)
    local left_top = entity.prototype.selection_box.left_top
    local right_bottom = entity.prototype.selection_box.right_bottom
    --Calculating center of the selection box
    local center = (left_top.x + right_bottom.x) / 2
    local width = math.abs(left_top.x) + right_bottom.x
    -- Set Shift here if needed, The offset looks better as it doesn't cover up fluid input information
    -- Ignore shift for 1 tile entities
    local x = (width > 1.25 and center - 0.5) or center
    local y = right_bottom.y - 0.35
    --Calculating bottom center of the selection box
    return {x, y}
end


local function new_sprite(entity)
    local sprite = SPRITE_STYLE[entity.status]
    sprite['target']=entity
    sprite['target_offset']=get_render_offset_from(entity)
    sprite['surface']=entity.surface
    sprite['render_layer']='entity-info-icon'
    sprite['force']=entity.force
    return rendering.draw_sprite (sprite)
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
local function built(event)
	local entity = event.created_entity or event.entity
    local data

    if (not ENTITY_TYPES[entity.type]) or entity.name == "factory-port-marker" then return end

    data = {}
    data.entity = entity
    data.last_status = entity.status
    data.sprite = new_sprite(entity)

    global.overlays[entity.force.name][entity.unit_number] = data
    -- if we are in the process of removing LIGHTs, we need to restart
    -- that, since inserting into the overlays table may mess up the
    -- iteration order.
    if global.show_bottlenecks == -1 then
        global.update_index = nil
    end
end

local function reset_overlays()
    global.overlays = {}
    for _, force in pairs(game.forces) do
        global.overlays[force.name] = {}
    end
end

local function rebuild_overlays()
    --[[Setup the global overlays table This table contains the machine entity, the signal entity and the freeze variable]]--
    reset_overlays()
    global.update_index = nil
    --game.print("Bottleneck: Rebuilding data from scratch")

    --[[Find all assembling machines on the map. Check each surface]]--
    for _, surface in pairs(game.surfaces) do
        --find-entities-filtered with no area argument scans for all entities in loaded chunks and should
        --be more effiecent then scanning through all chunks like in previous version

        --[[destroy any existing bottleneck-signals]]--
        rendering.clear('Bottleneck')

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


end

local function on_tick_old()
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
                if rendering.is_valid(data.sprite) then
                    if show_bottlenecks > 0 then
                        local entity = data.entity
                        if data.last_status ~= entity.status then
                            change_sprite(data, SPRITE_STYLE[entity.status])
                        end
                        data.last_status = entity.status
                    else
                        change_sprite(data, SPRITE['off'])
                        data.last_status = -1
                    end
                else -- Rebuild the icon something broke it!
                    data.sprite = new_sprite(entity)
                end
            else -- Machine is gone
                if data.sprite then
                    rendering.destroy(data.sprite)
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

local function update_settings()
	bn_signals_per_tick = settings.global["bottleneck-signals-per-tick"].value

    SPRITE_STYLE[defines.entity_status.working] = SPRITE[settings.global["bottleneck-show-working"].value]
	SPRITE_STYLE[defines.entity_status.no_power] = SPRITE[settings.global["bottleneck-show-no_power"].value]
	SPRITE_STYLE[defines.entity_status.no_fuel] = SPRITE[settings.global["bottleneck-show-no_fuel"].value]
	SPRITE_STYLE[defines.entity_status.no_recipe] = SPRITE[settings.global["bottleneck-show-no_recipe"].value]
	SPRITE_STYLE[defines.entity_status.no_input_fluid] = SPRITE[settings.global["bottleneck-show-no_input_fluid"].value]
	SPRITE_STYLE[defines.entity_status.no_research_in_progress] = SPRITE[settings.global["bottleneck-show-no_research_in_progress"].value]
	SPRITE_STYLE[defines.entity_status.no_minable_resources] = SPRITE[settings.global["bottleneck-show-no_minable_resources"].value]
	SPRITE_STYLE[defines.entity_status.low_input_fluid] = SPRITE[settings.global["bottleneck-show-low_input_fluid"].value]
	SPRITE_STYLE[defines.entity_status.low_power] = SPRITE[settings.global["bottleneck-show-low_power"].value]
	SPRITE_STYLE[defines.entity_status.disabled_by_control_behavior] = SPRITE[settings.global["bottleneck-show-disabled_by_control_behavior"].value]
	SPRITE_STYLE[defines.entity_status.disabled_by_script] = SPRITE[settings.global["bottleneck-show-disabled_by_script"].value]
	SPRITE_STYLE[defines.entity_status.fluid_ingredient_shortage] = SPRITE[settings.global["bottleneck-show-fluid_ingredient_shortage"].value]
	SPRITE_STYLE[defines.entity_status.fluid_production_overload] = SPRITE[settings.global["bottleneck-show-fluid_production_overload"].value]
	SPRITE_STYLE[defines.entity_status.item_ingredient_shortage] = SPRITE[settings.global["bottleneck-show-item_ingredient_shortage"].value]
	SPRITE_STYLE[defines.entity_status.item_production_overload] = SPRITE[settings.global["bottleneck-show-item_production_overload"].value]
	SPRITE_STYLE[defines.entity_status.marked_for_deconstruction] = SPRITE[settings.global["bottleneck-show-marked_for_deconstruction"].value]
	SPRITE_STYLE[defines.entity_status.missing_required_fluid] = SPRITE[settings.global["bottleneck-show-missing_required_fluid"].value]
	SPRITE_STYLE[defines.entity_status.missing_science_packs] = SPRITE[settings.global["bottleneck-show-missing_science_packs"].value]
	SPRITE_STYLE[defines.entity_status.waiting_for_source_items] = SPRITE[settings.global["bottleneck-show-waiting_for_source_items"].value]
	SPRITE_STYLE[defines.entity_status.waiting_for_space_in_destination] = SPRITE[settings.global["bottleneck-show-waiting_for_space_in_destination"].value]
    
    rebuild_overlays()
end
script.on_event(defines.events.on_runtime_mod_setting_changed, update_settings)

-------------------------------------------------------------------------------
--[[Init Events]]
local function register_conditional_events()
    if global.show_bottlenecks ~= 0 then
        --Register the tick handler if we are showing bottlenecks
        script.on_event(defines.events.on_tick, on_tick)
    end
end

local function init()
    init_forces()
    update_settings()
    
    --register the tick handler if we are showing bottlenecks
        script.on_event(defines.events.on_tick, on_tick)
    register_conditional_events()
end

local function init_forces()
    global.force_config = {}
    for _, force in pairs(game.forces) do
        global.force_config[force.name] = {}
        global.force_config[force.name]['players'] = {}
        for _, player in pairs(force.players) do
            table.insert(global.force_config[force.name]['players'], player.index)
    end
        global.force_config[force.name]['show_bottlenecks'] = #global.force_config[force.name]['players'] > 0
    end
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
            if not global.force_config then
                init_forces()
            end
            --Clean up old variables
            global.show_bottlenecks = nil
            global.lights_per_tick = nil
            global.signals_per_tick = nil
            global.showbottlenecks = nil
            global.output_idle_signal = nil
            global.high_contrast = nil
        end
        update_settings()
    end
end

    end
end

--[[ Hotkey ]]--
local function toggle_bottleneck(event)
	local player = game.players[event.player_index]
	if not player.admin then
		player.print('Bottleneck: You do not have privileges to toggle bottleneck')
		return
	end
	global.update_index = nil
	if global.show_bottlenecks == 1 then
        global.show_bottlenecks = -1
        player.set_shortcut_toggled("toggle-bottleneck", false)
	else
        global.show_bottlenecks = 1
        player.set_shortcut_toggled("toggle-bottleneck", true)
	end
	--Toggling the setting doesn't disable right way, make sure the handler gets
	--reenabled to toggle colors to their correct values.
    script.on_event(defines.events.on_tick, on_tick)
end

local function on_shortcut(event)
    if event.prototype_name == "toggle-bottleneck" then
        toggle_bottleneck(event)
    end
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(on_configuration_changed)
script.on_load(on_load)

local e=defines.events
local add_events = {e.on_built_entity, e.on_robot_built_entity, e.script_raised_revive, e.script_raised_built}

script.on_event(add_events, built)
script.on_event("bottleneck-hotkey", toggle_bottleneck)
script.on_event({e.on_entity_cloned}, on_entity_cloned)
script.on_event(e.on_lua_shortcut, on_shortcut)

--[[ Setup remote interface]]--
local interface = {}
--is_enabled - return show_bottlenecks
interface.enabled = function() return global.show_bottlenecks end
--print the global to a file
interface.print_global = function () game.write_file("Bottleneck/global.lua", serpent.block(global, {nocode=true, comment=false})) end
--rebuild all icons
interface.rebuild = rebuild_overlays
--allow other mods to interact with bottleneck
interface.get_sprites = function() return SPRITE end
interface.new_sprite = new_sprite
interface.change_sprite = function(data, style) change_sprite(data, SPRITE_STYLE[style]) end
--get the signal data associated with an entity
interface.get_sprite_data = function(force_name, unit_number) return global.overlays[force.name][unit_number] end

remote.add_interface("Bottleneck", interface)
