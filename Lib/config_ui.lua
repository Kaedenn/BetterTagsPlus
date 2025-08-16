--[[
-- This file builds the configuration menu for KaeCatRescue.
--
-- This exists to allow for iterative development without needing to restart
-- Balatro.
--]]

-- https://github.com/Steamodded/smods/wiki/UI-Guide

local function round_n(value, places)
    local power = math.pow(10, places)
    return math.floor((value * power) + 0.5) / power
end

local function is_slider(conf)
    if type(conf) == "table" then
        if conf.ref_value == "x_fine_adjust" then return true end
        if conf.ref_value == "save_tag_min_level" then return true end
    end
    return false
end

local function is_option_cycle(conf)
    return type(conf) == "table" and table.cycle_config ~= nil
end

-- Generic function called whenever any configuration toggle is changed
local function on_kcr_config_updated(conf)
    if type(conf) ~= "table" then
        kcrDebug(("on_kcr_config_updated called with non-table value %s"):format(conf))
    elseif is_slider(conf) then
        on_kcr_slider_updated(conf)
    elseif is_option_cycle(conf) then
        on_kcr_cycle_updated(conf)
    end

    if G.STAGE == G.STAGES.RUN then
        kcrGenerateTagUi(false, true)
    end
end

-- Function called when a slider is updated
local function on_kcr_slider_updated(conf)
    kcrDebug(conf)
    local prior_key = conf.ref_value .. "_prior"
    local prior_value = conf.ref_table[prior_key]
    local curr_value = conf.ref_table[conf.ref_value]
    -- Round to the number of displayed decimal places
    curr_value = round_n(curr_value, conf.decimal_places)
    -- Prevent update spam
    if prior_value ~= curr_value then
        conf.ref_table[prior_key] = curr_value
        if G.STAGE == G.STAGES.RUN then
            kcrGenerateTagUi(false, true)
        end
    end
end

-- Function called when an option cycle is updated
local function on_kcr_cycle_updated(conf)
    kcrDebug(conf)
    local from_value = conf.from_key
    local to_value = conf.to_key
    local curr_value = conf.cycle_config.ref_table[conf.cycle_config.ref_value]
    kcrDebug(("%s: value %s is %s -> %s"):format(
        conf.cycle_config.ref_value,
        from_value,
        to_value,
        curr_value))
    if to_value ~= curr_value then
        conf.cycle_config.ref_table[conf.cycle_config.ref_value] = to_value
    end
    if G.STAGE == G.STAGES.RUN then
        kcrGenerateTagUi(false, true)
    end
end

G.FUNCS.kcr_on_config_updated = on_kcr_config_updated
G.FUNCS.kcr_on_slider_updated = on_kcr_slider_updated
G.FUNCS.kcr_on_cycle_updated = on_kcr_cycle_updated

--[[ Build a proper callback function for config types needing one.
--
-- @param ref_value string Variable to store the updates
-- @param func function(table) Function to call
-- @return function
--]]
local function kcr_build_callback(ref_value, func)
    return function(new_value)
        return func({
            ref_value = ref_value,
            ref_table = KaeCatRescue.config,
            new_value = new_value,
        })
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
        -- Left column
        {n = G.UIT.C, config = {
            align = "cm",
            padding = 0.2,
            r = 0.1,
            colour = G.C.CLEAR,
            emboss = 0,
        }, nodes = {
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
                    callback = "kcr_on_slider_updated",
                },
                {n = G.UIT.R, config = {
                    align = "tm",
                    padding = 0,
                    r = 0.1,
                    colour = G.C.CLEAR,
                    emboss = 0,
                }, nodes = {
                    {n = G.UIT.O, config = {
                        object = DynaText({
                            string = {
                                "Slightly adjust where tags are drawn",
                                "Starts at 1.7; Balatro's default is 0.7",
                            },
                            colours = {G.C.WHITE},
                            shadow = true,
                            scale = 0.25
                        })
                    }},
                }},
            }},
            {n = G.UIT.R, config = {
                align = "cm",
                padding = 0.1,
                r = 0.1,
                colour = G.C.BLACK,
                emboss = 0.05,
            }, nodes = {
                create_option_cycle{
                    label = "Grouped Text Anchor",
                    info = {
                        "Changes where text is drawn, relative",
                        "to the tag (if text is enabled)"
                    },
                    scale = 0.8,
                    w = 4,
                    options = { "Left", "Right" },
                    current_option = KaeCatRescue.config.text_anchor or 2,
                    ref_table = KaeCatRescue.config,
                    ref_value = "text_anchor",
                    opt_callback = "kcr_on_cycle_updated",
                },
                create_toggle{
                    label = "Hide 'x1' Text",
                    id = "kcr_hide_x1",
                    info = {
                        "Hide 'x1' text when there's",
                        "just one tag of that level"
                    },
                    ref_table = KaeCatRescue.config,
                    ref_value = "hide_x1",
                    active_colour = G.C.RED,
                    callback = kcr_build_callback("hide_x1", on_kcr_config_updated),
                },
                create_toggle{
                    label = "Hide All Text",
                    id = "kcr_hide_text",
                    info = {"Hide all text (overrides above)"},
                    ref_table = KaeCatRescue.config,
                    ref_value = "hide_text",
                    active_colour = G.C.RED,
                    callback = kcr_build_callback("hide_text", on_kcr_config_updated),
                },
            }},
        }},
        -- Right column
        {n = G.UIT.C, config = {
            align = "tm",
            padding = 0.2,
            r = 0.1,
            colour = G.C.CLEAR,
            emboss = 0,
        }, nodes = {
            {n = G.UIT.R, config = {
                align = "cm",
                padding = 0.1,
                r = 0.1,
                colour = G.C.BLACK,
                emboss = 0.05,
            }, nodes = {
                create_toggle{
                    label = "Save on Combining",
                    id = "kcr_autosave",
                    ref_table = KaeCatRescue.config,
                    ref_value = "autosave",
                    active_colour = G.C.RED,
                    callback = kcr_build_callback("autosave", on_kcr_config_updated),
                },
                create_slider{
                    label = "Save on Tag Level",
                    id = "kcr_save_tag_min_level",
                    colour = G.C.RED,
                    ref_table = KaeCatRescue.config,
                    ref_value = "save_tag_min_level",
                    label_scale = 0.5,
                    w = 2,
                    min = 1,
                    max = 15,
                    decimal_places = 0,
                    callback = "kcr_on_slider_updated",
                },
                {n = G.UIT.R, config = {
                    align = "tm",
                    padding = 0,
                    r = 0.1,
                    colour = G.C.CLEAR,
                    emboss = 0,
                }, nodes = {
                    {n = G.UIT.T, config = {
                        text = "Save when generating a tag at or above this level",
                        scale = 0.25,
                        colour = G.C.UI.TEXT_LIGHT,
                    }},
                }},
            }},
            {n = G.UIT.R, config = {
                align = "tm",
                padding = 0.1,
                r = 0.1,
                colour = G.C.BLACK,
                emboss = 0.05,
            }, nodes = {
                create_toggle{
                    label = "Enable Debugging",
                    id = "kcr_debug",
                    ref_table = KaeCatRescue.config,
                    ref_value = "debug",
                    active_colour = G.C.RED,
                    callback = kcr_build_callback("debug", on_kcr_config_updated),
                },
            }},
            {n = G.UIT.R, config = {
                align = "tm",
                padding = 0.1,
                r = 0.1,
                colour = G.C.RED,
                emboss = 0.05,
            }, nodes = {
                {n = G.UIT.R, config = {
                    align = "tm",
                    padding = 0.05,
                    r = 0.1,
                    colour = G.C.RED,
                    emboss = 0,
                }, nodes = {
                    {n = G.UIT.O, config = {
                        object = DynaText({
                            string = {
                                "These options are dangerous!",
                                "Back-up your save before using!"
                            },
                            colours = {G.C.WHITE},
                            shadow = true,
                            scale = 0.4
                        })
                    }},
                }},
                {n = G.UIT.R, config = {
                    align = "cm",
                    padding = 0.1,
                    r = 0.1,
                    colour = G.C.BLACK,
                    emboss = 0.05,
                }, nodes = {
                    create_toggle{
                        label = "Quick Combination",
                        id = "kcr_fast_combine",
                        info = {"Make combining Cat Tags faster"},
                        ref_table = KaeCatRescue.config,
                        ref_value = "fast_combine",
                        active_colour = G.C.RED,
                        callback = kcr_build_callback("fast_combine", on_kcr_config_updated),
                    },
                    create_toggle{
                        label = "Auto-Combine",
                        id = "kcr_auto_combine",
                        info = {
                            "Automatically combine Cat Tags",
                            "(Back-up your save before using!)"
                        },
                        ref_table = KaeCatRescue.config,
                        ref_value = "auto_combine",
                        active_colour = G.C.RED,
                        callback = kcr_build_callback("auto_combine", on_kcr_config_updated),
                    },
                }},
            }},
        }},
    }}
end
