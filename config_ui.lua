--[[
-- This file builds the configuration menu for KaeCatRescue.
--
-- This exists to allow for iterative development without needing to restart
-- Balatro.
--]]

-- https://github.com/Steamodded/smods/wiki/UI-Guide

local function on_kcr_config_updated(conf)
    -- Prevent update spam
    if type(conf) == "table" and conf.ref_value == "x_fine_adjust" then
        local prior_key = conf.ref_value .. "_prior"
        local prior_value = conf.ref_table[prior_key]
        local curr_value = conf.ref_table[conf.ref_value]
        if prior_value == curr_value then
            return
        end
        conf.ref_table[prior_key] = curr_value
    end
    if G.STAGE == G.STAGES.RUN then
        local save_reduce = G.SETTINGS.reduced_motion
        G.SETTINGS.reduced_motion = true
        kcrGenerateTagUi()
        G.SETTINGS.reduced_motion = save_reduce
    end
end

G.FUNCS.kcr_on_config_updated = on_kcr_config_updated

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
            create_slider{
                label = "Location Adjustment",
                id = "kcr_x_adjust",
                colour = G.C.RED,
                ref_table = KaeCatRescue.config,
                ref_value = "x_fine_adjust",
                label_scale = 0.5,
                w = 2,
                min = 0,
                max = 3,
                decimal_places = 1,
                callback = "kcr_on_config_updated",
            },
            create_toggle{
                label = "Right Anchor",
                info = {
                    "If grouping is enabled, draw text",
                    "to the right of the parent tag, ",
                    "instead of the left"
                },
                ref_table = KaeCatRescue.config,
                ref_value = "anchor_right",
                active_colour = G.C.RED,
                callback = on_kcr_config_updated,
            },
            --[[create_option_cycle{
                label = "Grouped Text Anchor",
                info = {
                    "If grouping is enabled, where should the",
                    "text be displayed, in relation to the tag?"
                },
                scale = 0.8,
                w = 4,
                options = { "Left", "Right" },
                current_option = KaeCatRescue.config.anchor or 2,
                ref_table = KaeCatRescue.config,
                ref_value = "anchor",
                callback = on_kcr_config_updated,
            },]]
            create_toggle{
                label = "Hide 'x1' Text",
                info = {
                    "Hide 'x1' text when there's",
                    "just one tag of that level"
                },
                ref_table = KaeCatRescue.config,
                ref_value = "hide_x1",
                active_colour = G.C.RED,
                callback = on_kcr_config_updated,
            },
            create_toggle{
                label = "Hide All Text",
                info = {"Hide all text (overrides above)"},
                ref_table = KaeCatRescue.config,
                ref_value = "hide_text",
                active_colour = G.C.RED,
                callback = on_kcr_config_updated,
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
                label = "Autosave",
                info = {"Save when combining cat tags"},
                ref_table = KaeCatRescue.config,
                ref_value = "autosave",
                active_colour = G.C.RED,
                callback = on_kcr_config_updated,
            },
        }},
    }}
end
