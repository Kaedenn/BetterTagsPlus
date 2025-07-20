--[[
-- This file builds the configuration menu for KaeCatRescue.
--
-- This exists to allow for iterative development without needing to restart
-- Balatro.
--]]

-- https://github.com/Steamodded/smods/wiki/UI-Guide

G.FUNCS.kcr_config_updated = function(config)
    if config.cycle_config.ref_value == "anchor" then
        KaeCatRescue.config.anchor = config.to_key
    end
end

return function()
    return {n = G.UIT.ROOT, config = {
        emboss = 0.05,
        minh = 6,
        minw = 6,
        r = 0.1,
        align = "cm",
        colour = G.C.CLEAR,
    }, nodes = {
        --[[
        {n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
            {n = G.UIT.O, config = {
                object = DynaText({
                    string = "Placeholder text",
                    colours = {G.C.WHITE},
                    shadow = true,
                    scale = 0.4
                })
            }}
        }},
        ]]
        {n = G.UIT.R, config = {
            align = "cm",
            padding = 0.2,
            r = 0.1,
            colour = G.C.BLACK,
            emboss = 0.05,
        }, nodes = {
            create_toggle{
                label = "Group Tags",
                info = {"Visually group tags of the same level"},
                ref_table = KaeCatRescue.config,
                ref_value = "do_group",
                active_colour = G.C.RED
            },
            create_option_cycle{
                label = "Grouped Text Anchor",
                info = {
                    "If grouping is enabled, where should the",
                    "text be displayed, in relation to the tag?"
                },
                scale = 0.8,
                w = 4,
                options = { "Left", "Right" },
                current_option = 2,
                ref_table = KaeCatRescue.config,
                ref_value = "anchor",
                opt_callback = "kcr_config_updated",
            },
        }},
        {n = G.UIT.R, config = {
            align = "cm",
            padding = 0.1,
            r = 0.1,
            colour = G.C.BLACK,
            emboss = 0.05,
        }, nodes = {
            create_toggle{
                label = "Hide x1",
                info = {
                    "Hide 'x1' text when there's",
                    "just one tag of that level"
                },
                ref_table = KaeCatRescue.config,
                ref_value = "hide_x1",
                active_colour = G.C.RED
            },
        }},
        --[[{n = G.UIT.R, config = {
            align = "cm",
            padding = 0.1,
            r = 0.1,
            colour = G.C.BLACK,
            emboss = 0.05,
        }, nodes = {
            create_toggle{
                label = "Show Count Hints",
                info = {"Show combined cat tag levels"},
                ref_table = KaeCatRescue.config,
                ref_value = "show_hints",
                active_colour = G.C.RED
            },
        }},]]
        {n = G.UIT.R, config = {
            align = "cm",
            padding = 0.1,
            r = 0.1,
            colour = G.C.BLACK,
            emboss = 0.05,
        }, nodes = {
            create_toggle{
                label = "Autosave",
                info = {"Save when combining cat tags"},
                ref_table = KaeCatRescue.config,
                ref_value = "autosave",
                active_colour = G.C.RED
            },
        }},
    }}
end
