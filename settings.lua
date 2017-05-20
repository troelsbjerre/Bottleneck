data:extend{
    {
        type = "bool-setting",
        name = "bottleneck-enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "bottleneck-aa[enabled]"
    },
    {
        type = "bool-setting",
        name = "bottleneck-high-contrast",
        setting_type = "runtime-global",
        default_value = false,
        order = "bottleneck-ab[high-contrast]"
    },
    {
        type = "bool-setting",
        name = "bottleneck-show-green-signal",
        setting_type = "runtime-global",
        default_value = true,
        order = "bottleneck-abc[show-green-signal]"
    },
    {
        type = "int-setting",
        name = "bottleneck-signals-per-tick",
        setting_type = "runtime-global",
        default_value = 40,
        maximum_value = 2000,
        minimum_value = 1,
        order = "bottleneck-ac[signals-per-tick]"
    },
}
