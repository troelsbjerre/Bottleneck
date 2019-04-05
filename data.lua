--Quick to use empty sprite
local Prototype = {}
--Quick to use empty sprite
Prototype.empty_sprite ={
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1
}

--Quick to use empty animation
Prototype.empty_animation = {
    filename = Prototype.empty_sprite.filename,
    width = Prototype.empty_sprite.width,
    height = Prototype.empty_sprite.height,
    line_length = 1,
    frame_count = 1,
    shift = { 0, 0},
    animation_speed = 1,
    direction_count=1
}

local SPRITE_DATA = {
    white = {
        filename = "__Bottleneck__/graphics/white.png",
        scale = 0.25
    },
    cross = {
        filename = "__Bottleneck__/graphics/white_cross.png",
        scale = 0.25
    },
    minus = {
        filename = "__Bottleneck__/graphics/white_minus.png",
        scale = 0.25
    },
    white_small = {
        filename = "__Bottleneck__/graphics/white.png",
        scale = 0.125
    },
    cross_small = {
        filename = "__Bottleneck__/graphics/white_cross.png",
        scale = 0.125
    },
    minus_small = {
        filename = "__Bottleneck__/graphics/white_minus.png",
        scale = 0.125
    }
}

local sprites = {}


for sprite_name, sprite_data in pairs(SPRITE_DATA) do
    local sprite = {
        type = "sprite",
        name = "bottleneck_" .. sprite_name,
        width = 64,
        height = 64,
        flags = {"no-crop"},
    }
    for k,v in pairs(sprite_data) do sprite[k] = v end
    table.insert(sprites, sprite)
end

data:extend(sprites)

local key = {
	type = "custom-input",
	name = "bottleneck-hotkey",
	key_sequence = "SHIFT + ALT + L",
	consuming = "none",
}

data:extend({key})

data:extend({
    {
      type = 'shortcut',
      name = 'toggle-bottleneck',
      toggleable = true,
      order = 'a[alt-mode]-b[copy]',
      action = 'lua',
      localised_name = {'shortcut.toggle-bottleneck'},
      icon = 
      {
        filename = "__Bottleneck__/graphics/shortcut/shortcut_32.png",
        priority = 'extra-high-no-scale',
        size = 32,
        scale = 1,
        flags = {'icon'}
      },
      small_icon =
      {
        filename = "__Bottleneck__/graphics/shortcut/shortcut_24.png",
        priority = 'extra-high-no-scale',
        size = 24,
        scale = 1,
        flags = {'icon'}
      },
      disabled_small_icon =
      {
        filename = "__Bottleneck__/graphics/shortcut/shortcut_24_disabled.png",
        priority = 'extra-high-no-scale',
        size = 24,
        scale = 1,
        flags = {'icon'}
      }
    }
  })
  
  