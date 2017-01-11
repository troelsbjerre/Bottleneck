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

local test_stoplight = {
  type = "lamp",
  name = "bottleneck-icons-lamp",
  icon = "__base__/graphics/icons/small-lamp.png",
  max_health = 0,
  corpse = "small-remnants",
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  --selectable_in_game = false,
  energy_source =
  {
    type = "burner",
    usage_priority = "secondary-input",
    effectivity = 10000,
    fuel_inventory_size = 1
  },
  energy_usage_per_tick = "0.00000000000001W",
  light = {intensity = 0.4, size = 6},
  light_when_colored = {intensity = 0.4, size = 6},
  glow_size = 2,
  glow_color_intensity = 0.135,
  picture_off =
  {
    filename = "__Bottleneck__/graphics/off.png",
    priority = "extra-high",
    x=0,
    y=0,
    width = 32,
    height = 32,
    scale=0.6,
    frame_count=1,
    shift = {0, 0},
    axially_symmetrical = false,
    direction_count = 1,
  },
  picture_on =
  {
    filename = "__Bottleneck__/graphics/stoplight-on-patch.png",
    priority = "high",
    width = 32,
    height = 32,
    frame_count = 1,
    axially_symmetrical = false,
    direction_count = 1,
    shift = {0, 0},
  },
  signal_to_color_mapping =
  {
    {signal="signal-red", color={r=1,g=0,b=0}},
    {signal="signal-green", color={r=0,g=1,b=0}},
    {signal="signal-blue", color={r=0,g=0,b=1}},
    {signal="signal-yellow", color={r=1,g=1,b=0}},
    {signal="signal-pink", color={r=1,g=0,b=1}},
    {signal="signal-cyan", color={r=0,g=1,b=1}},
  },
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
        shift = {-0.2, -0.3},
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
data:extend({stoplight, test_stoplight, key1, key2})
