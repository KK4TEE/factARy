-- Mod: factARy
-- description": "Search for, format, and then store circuit network data into a JSON file
-- Written by KK4TEE
-- http://persigehl.com/
-- Licence: MIT

------------ Settings ---------------------------------------------------------

data:extend({
    {
        type = "bool-setting",
        name = "json_enabled",
        setting_type = "runtime-global",
        default_value = false
    },
    {
        type = "int-setting",
        name = "maximum_entities_between_ticks",
        setting_type = "runtime-global",
        default_value = 60
    },
    {
        type = "int-setting",
        name = "ticks_between_entity_scans",
        setting_type = "runtime-global",
        default_value = 7200
    },
    {
        type = "int-setting",
        name = "ticks_between_chunk_scans",
        setting_type = "runtime-global",
        default_value = 600
    }
})