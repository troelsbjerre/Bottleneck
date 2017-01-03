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
  animation_speed = 0
}

local test_stoplight1 = {
  type = "lamp",
  name = "bottleneck-icons-lamp",
  icon = "__base__/graphics/icons/small-lamp.png",
  --flags = {},
  --minable = {hardness = 0.2, mining_time = 0.5, result = "small-lamp"},
  max_health = 0,
  corpse = "small-remnants",
  --collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  --selectable_in_game = false,
  --vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
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
    --filename = "__base__/graphics/entity/small-lamp/light-off.png",
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



local test_stoplight2 = { --luacheck: ignore
  type = "rail-signal",
  name = "bottleneck-icons",
  icon = "__Bottleneck__/graphics/stoplights.png",
  flags = {"placeable-player", "placeable-neutral", "player-creation", "building-direction-8-way"},
  order = "AintNobodyGotTimeForThat",
  minable = {mining_time = 0.5, result = "rail-signal"},
  max_health = 0,
  selectable_in_game=false,
  collision_box = {{-0.0, -0.0}, {0.0, 0.0}},
  selection_box = {{-0.0, -0.0}, {0.0, 0.0}},
  animation =
  {
    filename = "__Bottleneck__/graphics/stoplights.png",
    priority = "high",
    width = 32,
    height = 32,
    frame_count = 3,
    direction_count = 8,
    scale=0.6,
    shift = {-0.5, -0.3}
  },
  green_light = {intensity = 0.2, size = 4, color={g=1}},
  orange_light = {intensity = 0.2, size = 4, color={g=1}},
  red_light = {intensity = 0.2, size = 4, color={g=1}},
}

local stoplight = {
  type = "storage-tank",
  name = "bottleneck-icons",
  icon = "__Bottleneck__/graphics/red.png",
  flags = {"building-direction-8-way", "placeable-off-grid", "not-blueprintable", "not-deconstructable"},
  minable = nil,
  max_health = 0,
  order = "AintNobodyGotTimeForThat",
  selectable_in_game = false,
  collision_box = {{-0.0,-0.0}, {0.0,0.0}},
  selection_box = {{-0.0,-0.0}, {0.0,0.0}},
  fluid_box = {
    base_area = 0,
    pipe_covers = nil,
    pipe_connections = {},
  },
  window_bounding_box = {{-0.0,-0.0}, {0.0, 0.0}},
  pictures = {
    picture = {
      north = {
        filename = "__Bottleneck__/graphics/off.png",
        priority = "extra-high",
        x=0,
        y=0,
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      east = {
        filename = "__Bottleneck__/graphics/red.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      south = {
        filename = "__Bottleneck__/graphics/yellow.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      west = {
        filename = "__Bottleneck__/graphics/green.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      northwest = {
        filename = "__Bottleneck__/graphics/blue.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      northeast = {
        filename = "__Bottleneck__/graphics/blue.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      southwest = {
        filename = "__Bottleneck__/graphics/blue.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
      southeast = {
        filename = "__Bottleneck__/graphics/blue.png",
        priority = "extra-high",
        width = 32,
        height = 32,
        scale=0.6,
        frame_count=1,
        shift = {-0.2, -0.3}
      },
    },
    fluid_background = Proto.empty_sprite,
    window_background = Proto.empty_sprite,
    flow_sprite = Proto.empty_sprite,
  },
  flow_length_in_ticks = 360,
  vehicle_impact_sound = nil,
  working_sound = nil,
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
data:extend({stoplight, test_stoplight1, key1, key2})
