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
  direction_count = 1,
  shift = { 0, 0},
  animation_speed = 0
}

local stoplight = {
  type = "car",
  name = "bottleneck-stoplight",
  icon = "__Bottleneck__/graphics/red.png",
  flags = {},
  max_health = 0,
  energy_per_hit_point = 0,
  effectivity = 100,
  braking_power = "1W",
  burner =
  {
    effectivity = 100,
    fuel_inventory_size = 1,
  },
  consumption = "1W",
  friction = 0,
  animation =
  {
    layers =
    {
      {
        width = 32,
        priority="extra-high",
        height = 32,
        frame_count = 1,
        direction_count = 7,
        scale = 0.6,
        shift = {-0.3, -0.2},
        animation_speed = 0,
        max_advance = 0,
        stripes =
        {
          {
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority="extra-high",
            width_in_frames = 1,
            height_in_frames = 7,
          },
        }
      },
    }
  },
  rotation_speed = 0, --0.015,
  inventory_size = 0
}

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
data:extend({stoplight, key1, key2})
