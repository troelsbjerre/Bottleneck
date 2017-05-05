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

--off, green, red, yellow, blue
local stoplight = {
    type = "simple-entity-with-force",
    name = "bottleneck-stoplight",
    flags = {"not-blueprintable", "not-deconstructable", "not-on-map"},
    icon = "__Bottleneck__/graphics/red.png",
    max_health = 100,
    selectable_in_game = false,
    mined_sound = nil,
    minable = nil,
    collision_box = nil,
    selection_box = nil,
    collision_mask = {},
    render_layer = "explosion",
    vehicle_impact_sound = nil,
    pictures =
    {
        {
            --0 off
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 0,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --1 green
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 32,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --2 red
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 64,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --3 yellow
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 96,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --4 blue
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 128,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --5 red x
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 160,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --6 yellow -
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 192,
            width = 32,
            height = 32,
            scale = 0.6,
            shift = {-0.5, -0.3}
        },
        {
            --7 off small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 0,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --8 green small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 32,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --9 red small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 64,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --10 yellow small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 96,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --11 blue small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 128,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --12 red x small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 160,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
        {
            --13 yellow - small
            filename = "__Bottleneck__/graphics/stoplights.png",
            priority = "extra-high",
            x = 0,
            y = 192,
            width = 32,
            height = 32,
            scale = 0.3,
            shift = {-0.6, -0.2}
        },
    },
}

data:extend{stoplight}
