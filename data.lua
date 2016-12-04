data:extend(
{
	{
		type = "decorative",
		name = "red-bottleneck",
		flags = {"placeable-neutral", "player-creation", "not-repairable"},
		icon = "__Bottleneck__/graphics/red.png",
		order = 'z[red-bottleneck]',
		render_layer = "higher-object-above",

		pictures =
		{
			filename = "__Bottleneck__/graphics/red.png",
			priority = "extra-high",
			width = 32,
			height = 32,
			shift = {-0.5, -0.3}
		}
	},
	{
		type = "decorative",
		name = "yellow-bottleneck",
		flags = {"placeable-neutral", "player-creation", "not-repairable"},
		icon = "__Bottleneck__/graphics/yellow.png",
		order = 'z[yellow-bottleneck]',
		render_layer = "higher-object-above",

		pictures =
		{
			filename = "__Bottleneck__/graphics/yellow.png",
			priority = "extra-high",
			width = 32,
			height = 32,
			shift = {-0.5, -0.3}
		}
	},
	{
		type = "decorative",
		name = "blue-bottleneck",
		flags = {"placeable-neutral", "player-creation", "not-repairable"},
		icon = "__Bottleneck__/graphics/blue.png",
		order = 'z[blue-bottleneck]',
		render_layer = "higher-object-above",

		pictures =
		{
			filename = "__Bottleneck__/graphics/blue.png",
			priority = "extra-high",
			width = 32,
			height = 32,
			shift = {-0.5, -0.3}
		}
	},
	{
		type = "decorative",
		name = "green-bottleneck",
		flags = {"placeable-neutral", "player-creation", "not-repairable"},
		icon = "__Bottleneck__/graphics/green.png",
		order = 'z[green-bottleneck]',
		render_layer = "higher-object-above",

		pictures =
		{
			filename = "__Bottleneck__/graphics/green.png",
			priority = "extra-high",
			width = 32,
			height = 32,
			shift = {-0.5, -0.3}
		}
	},
	{
		type = "custom-input",
		name = "bottleneck-hotkey",
		key_sequence = "B",
		consuming = "script-only"
	},
	{
		type = "custom-input",
		name = "bottleneck-highcontrast",
		key_sequence = "SHIFT + B",
		consuming = "script-only"
	}
})
