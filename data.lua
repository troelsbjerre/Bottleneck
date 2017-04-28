--Quick to use empty sprite
local Proto = {}
Proto.empty_sprite ={
  filename = "__Bottleneck__/graphics/off.png",
  priority = "extra-high",
  width = 1,
  height = 1
}

--Quick to use empty animation
Proto.empty_animation = {
  filename = Proto.empty_sprite.filename,
  width = Proto.empty_sprite.width,
  height = Proto.empty_sprite.height,
  line_length = 1,
  frame_count = 1,
  shift = { 0, 0},
  animation_speed = 1
}

--off, green, red, yellow, blue
local stoplight = {
  type = "storage-tank",
  name = "bottleneck-stoplight",
  icon = "__Bottleneck__/graphics/red.png",
  max_health = 0,
  selectable_in_game = false,
  collision_box = nil,
  selection_box = nil,
  collision_mask = {"floor-layer"},
  fluid_box = {
    base_area = 0,
    pipe_covers = nil,
    pipe_connections = {},
  },
  window_bounding_box = {{-0.0,-0.0}, {0.0, 0.0}},
  pictures = {
    picture = {
      north = {
        --off
        filename = "__Bottleneck__/graphics/stoplights.png",
        priority = "extra-high",
        x = 0,
        y = 0,
        width = 32,
        height = 32,
        scale = 0.6,
        frame_count = 1,
        shift = {-0.5, -0.3}
      },
      east = {
        --green
        filename = "__Bottleneck__/graphics/stoplights.png",
        x = 0,
        y = 32,
        priority = "extra-high",
        width = 32,
        height = 32,
        scale = 0.6,
        frame_count = 1,
        shift = {-0.5, -0.3}
      },
      south = {
        --red
        filename = "__Bottleneck__/graphics/stoplights.png",
        x = 0,
        y = 64,
        priority = "extra-high",
        width = 32,
        height = 32,
        scale = 0.6,
        frame_count = 1,
        shift = {-0.5, -0.3}
      },
      west = {
        --yellow
        x = 0,
        y = 96,
        filename = "__Bottleneck__/graphics/stoplights.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale = 0.6,
        frame_count = 1,
        shift = {-0.5, -0.3}
      },
    },
    gas_flow = Proto.empty_animation,
    fluid_background = Proto.empty_sprite,
    window_background = Proto.empty_sprite,
    flow_sprite = Proto.empty_sprite,
  },
  flow_length_in_ticks = 360,
  vehicle_impact_sound = nil,
  working_sound = nil,
}

local stoplight_high = table.deepcopy(stoplight)
stoplight_high.name = "bottleneck-stoplight-high"
stoplight_high.pictures.picture.west.x = 0
stoplight_high.pictures.picture.west.y = 128


local key1 = {
  type = "custom-input",
  name = "bottleneck-hotkey",
  key_sequence = "B",
  consuming = "script-only"
}
local key2 = {
  type = "custom-input",
  name = "bottleneck-highcontrast",
  key_sequence = "SHIFT + B",
  consuming = "script-only"
}
data:extend({stoplight, stoplight_high, key1, key2})
