
local BTP_LEFT = 1
local BTP_RIGHT = 2

function btpGenerateSingleTagUi(tag, do_reduce_motion)
    local save_reduce = G.SETTINGS.reduced_motion
    if do_reduce_motion then
        G.SETTINGS.reduced_motion = true
    end
    local tag_sprite_ui, tag_sprite = tag:generate_UI()
    if do_reduce_motion then
        G.SETTINGS.reduced_motion = save_reduce
    end
    local right_sided = BetterTagsPlus.config.text_anchor == BTP_RIGHT
    local x_adjust = BetterTagsPlus.config.x_fine_adjust or 1.7

    local show_count = true
    if BetterTagsPlus.config.hide_text then
        show_count = false
    elseif BetterTagsPlus.config.hide_x1 and tag.count == 1 then
        show_count = false
    end

    local tag_count_node = nil

    if show_count then
        local x_node = {
            n = G.UIT.T,
            config = {
                text = 'x',
                scale = 0.4,
                colour = G.C.MULT
            }
        }

        local count_node = {
            n = G.UIT.T,
            config = {
                ref_table = tag,
                ref_value = "count",
                scale = 0.4,
                colour = G.C.UI.TEXT_LIGHT
            }
        }

        tag_count_node = {
            n = G.UIT.C,
            config = {
                align = "cl",
                colour = G.C.BLACK,
                padding = 0.05,
                r = 0.08,
                minw = 0.5,
                minh = 0.4,
            },
            nodes = right_sided and {
                x_node,
                count_node
            } or {
                count_node,
                x_node
            },
        }
    end

    return UIBox{
        definition = {
            n = G.UIT.ROOT,
            config = {
                align = right_sided and "cl" or "cr",
                padding = 0.05,
                colour = G.C.CLEAR,
                minw = 2,
            },
            nodes = right_sided and {
                tag_sprite_ui,
                tag_count_node
            } or {
                tag_count_node,
                tag_sprite_ui
            }
        },
        config = {
            align = G.HUD_tags[1] and 'tm' or 'bri',
            offset = G.HUD_tags[1] and {x = 0, y = 0} or {x = x_adjust, y = 0},
            major = G.HUD_tags[1] and G.HUD_tags[#G.HUD_tags] or G.ROOM_ATTACH
        }
    }
end
