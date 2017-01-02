--Generate event ID's for custom events
local bottleneck_toggle = script.generate_event_name()
local light = {
  off = defines.direction.north,
  red = defines.direction.east,
  yellow = defines.direction.south,
  green = defines.direction.west,
  blue = defines.direction.northwest,
}

--Message Everyone
local function msg(message)
  game.print(message)
end

--[[ Remove the light]]
local function remove_light(event)
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

--[[ Calculates bottom center of the entity to place bottleneck there ]]
local function get_bottleneck_position_for(entity)
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

local function change_signal(data, signal_color)
  --local entity = data.entity
  local signal = data.signal
  if (signal and signal.valid) and signal.direction ~= signal_color then
    signal.direction=signal_color
  end
end

local update = {}
function update.drill(data)
  if data.drill_depleted then return end
  local entity = data.entity
  local progress = data.progress
  if (entity.energy == 0) or (entity.mining_target == nil and check_drill_depleted(data)) then
    change_signal(data, light.red)
  elseif (entity.mining_progress == progress) then
    change_signal(data, light.yellow)
  else
    change_signal(data, light.green)
    data.progress = entity.mining_progress
  end
end

function update.machine(data)
  local entity = data.entity
  if entity.energy == 0 then
    change_signal(data, light.red)
  elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
    change_signal(data, light.green)
  elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
    change_signal(data, light.yellow)
  else
    change_signal(data, light.red)
  end
end

function update.furnace(data)
  local entity = data.entity
  if entity.energy == 0 then
    change_signal(data, light.red)
  elseif entity.is_crafting() and (entity.crafting_progress < 1) and (entity.bonus_progress < 1) then
    change_signal(data, light.green)
  elseif (entity.crafting_progress >= 1) or (entity.bonus_progress >= 1) or (not entity.get_output_inventory().is_empty()) or (has_fluid_output_available(entity)) then
    change_signal(data, light.yellow)
  else
    change_signal(data, light.red)
  end
end

function update.logistic(data)
local entity = data.entity
local network = entity.logistic_network
if network then
  if entity.request_slot_count > 0 then
    local satisfied = false
    -- for _, ent in pairs(network.full_or_satisfied_requesters) do
    --   if entity==ent then
    --     satisfied = true
    --     break
    --   end
    -- end
    if satisfied then
      change_signal(data, light.green)
    else
      change_signal(data, light.yellow)
    end
  else
    change_signal(data, light.green)
  end
else
  change_signal(data, light.red)
end
end

--[[ A function that is called whenever an entity is built (both by player and by robots) ]]--
local function built(event)
  local entity = event.created_entity
  --local surface = entity.surface
  local data

  -- If the entity that's been built is an assembly machine or a furnace...
  if entity.type == "assembling-machine" then
    data = { update = "machine" }
  elseif entity.type == "furnace" then
    data = { update = "furnace" }
  elseif entity.type == "mining-drill" then
    data = { update = "drill" }
  elseif game.entity_prototypes[entity.name].logistic_mode then
    data = { update = "logistic"}
  end
  if data then
    data.entity = entity
    data.position = get_bottleneck_position_for(entity)
    data.signal = entity.surface.create_entity{name="bottleneck-icons",position=data.position,direction=light.off,force=entity.force}
    if global.show_bottlenecks == 1 then
       update[data.update](data)
    end
    global.overlays[entity.unit_number] = data
    -- if we are in the process of removing lights, we need to restart
    -- that, since inserting into the overlays table may mess up the
    -- iteration order.
    if global.show_bottlenecks == -1 then
      global.update_index = nil
    end
  end
end

local function build_network_data()
local networks = global.networks
for _, network in pairs(networks) do
  if network.valid then

  end
end
end

local function rebuild_overlays()
  --[[Setup the global overlays table This table contains the machine entity, the signal entity and the freeze variable]]--
  global.overlays = {}
  global.update_index = nil
  msg("Bottleneck: rebuilding data from scratch")

  --[[Find all assembling machines on the map. Check each surface]]--
  for _, surface in pairs(game.surfaces) do
    --find-entities-filtered with no area argument scans for all entities in loaded chunks and should
    --be more effiecent then scanning through all chunks like in previous version

    --[[destroy any existing bottleneck-signals]]--
    for _, stoplight in pairs(surface.find_entities_filtered{type="storage-tank", name="bottleneck-signals"}) do
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
local function on_tick(event)
  if global.show_bottlenecks == 1 then
    local overlays = global.overlays
    local index = global.update_index
    if index and overlays[index] then
      index, data = index, overlays[index]
    else
      index, data = next(overlays, index)
    end
    --if event.tick % 60 == 0 then build_network_data(data.network) end
    local numiter = 0
    -- only perform 40 updates per tick
    -- todo: put the magic 40 into config
    while index and (numiter < 40) do
      local entity = data.entity
      local signal = data.signal

      -- if entity is valid, update it, otherwise remove the signal and the associated data
      if entity.valid then
        update[data.update](data)
      else
        if signal and signal.valid then
          signal.destroy()
        end
        overlays[index] = nil
      end
      numiter = numiter + 1

      index, data = next(overlays, index)
    end
    global.update_index = index
  elseif global.show_bottlenecks == -1 then
    local overlays = global.overlays
    local index = global.update_index
    --Check for existing index and associated data
    if index and overlays[index] then
      index, data = index, overlays[index]
    else
      index, data = next(overlays, index)
    end
    local numiter = 0
    -- only perform 40 updates per tick
    -- todo: put the magic 40 into config
    while index and (numiter < 40) do

      local data = overlays[index]
      local signal = data.signal

      -- if signal exists, destroy it
      if signal and signal.valid then
        change_signal(data, light.off)
      end
      numiter = numiter + 1
      index = next(overlays, index)
    end
    global.update_index = index
    -- if we have reached the end of the list (i.e., have removed all lights), pause updating until enabled by hotkey next
    if not index then
      global.show_bottlenecks = 0
      msg("Bottleneck: All icons disabled")
    end
  end
end

-------------------------------------------------------------------------------
--[[HOTKEYS]]--
local function on_hotkey(event)
  local player = game.players[event.player_index]
  if not player.admin then
    player.print('Bottleneck: you do not have privileges to toggle bottleneck')
    return
  end
  global.update_index = nil
  if global.show_bottlenecks == 1 then
    game.raise_event(bottleneck_toggle, {tick=event.tick, player_index=event.player_index, enable=false})
    global.show_bottlenecks = -1
  else
    game.raise_event(bottleneck_toggle, {tick=event.tick, player_index=event.player_index, enable=true})
    global.show_bottlenecks = 1
  end
end

local function toggle_highcontrast(event) --luacheck: ignore
  local player = game.players[event.player_index]
  if not player.admin then
    player.print('Bottleneck: you do not have privileges to toggle contrast')
    return
  end
  if global.output_idle_signal ~= "yellow-bottleneck" then
    global.output_idle_signal = "yellow-bottleneck"
    msg('Bottleneck: high contrast mode disabled')
  else
    global.output_idle_signal = "blue-bottleneck"
    msg('Bottleneck: high contrast mode enabled')
  end
end

-------------------------------------------------------------------------------
--[[Init Events]]
local function init()
  --seperate out init and config changed
  global = {}
  global.show_bottlenecks = 1
  --global.output_idle_signal = "yellow-bottleneck"
  rebuild_overlays()
end

local function on_configuration_changed(event)
  --Any MOD has been changed/added/removed, including base game updates.
  if event.mod_changes ~= nil then --should never be nil
    msg("Bottlneck: game or mod version changes detected")

    --This mod has changed
    local changes = event.mod_changes["Bottleneck"]
    if changes ~= nil then -- THIS Mod has changed
      msg("Bottleneck Updated from ".. tostring(changes.old_version) .. " to " .. tostring(changes.new_version))
    end
  end
  global.show_bottlenecks = global.showbottlenecks or 1
  --global.output_idle_signal = global.output_idle_signal or "yellow-bottleneck"
  rebuild_overlays()
end

--[[ Setup event handlers ]]--
script.on_init(init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_preplayer_mined_item, remove_light)
script.on_event(defines.events.on_robot_pre_mined, remove_light)
script.on_event(defines.events.on_entity_died, remove_light)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
script.on_event("bottleneck-hotkey", on_hotkey)
--script.on_event("bottleneck-highcontrast", toggle_highcontrast)

--[[ Setup remote interface]]--
local interface = {}
--get_ids, return the table of event ids
interface.get_ids = function() return bottleneck_toggle end
--is_enabled - return show_bottlenecks
interface.enabled = function() if global.show_bottlenecks == 1 then return true else return false end end
--print the global to a file
interface.print_global = function() game.write_file("logs/Bottleneck/global.lua",serpent.block(global),false) end
--rebuild all icons
interface.rebuild = function() rebuild_overlays() end
remote.add_interface("Bottleneck", interface)
