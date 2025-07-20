if not KaeCatRescue then KaeCatRescue = {} end

KaeCatRescue.config = SMODS.current_mod.config

local ANCHOR_LEFT = 1
local ANCHOR_RIGHT = 2

--[[ Called to draw the mod's config box ]]
SMODS.current_mod.config_tab = function()
    return assert(SMODS.load_file("config_ui.lua", "KaeCatRescue"))()()
end

local function getTagKey(tag)
    if tag.key == "tag_cry_cat" then
        return ("tag_cry_cat-%d"):format(tag.ability and tag.ability.level or 1)
    end
    return tag.key
end

local function getTagCounts()
    local result = {}
    for _, tag in pairs(G.GAME.tags) do
        result[getTagKey(tag)] = (result[getTagKey(tag)] or 0) + 1
    end
    return result
end 

--[[ This function is called by the Lovely injection ]]
function kcrGenerateTagUi()
    if not KaeCatRescue.config.do_group then
        return
    end

    if G.HUD_tags then
        for key, val in pairs(G.HUD_tags) do
            val:remove()
            G.HUD_tags[key] = nil
        end
    end
    local counts = getTagCounts()
    local done = {}

    local left_sided = KaeCatRescue.config.anchor == ANCHOR_LEFT
    local right_sided = KaeCatRescue.config.anchor == ANCHOR_RIGHT
    local padding = right_sided and 0.05 or 0.1
    for _, tag in pairs(G.GAME.tags) do
        local key = getTagKey(tag)
        if not done[key] then
            local tag_sprite_ui = tag:generate_UI()
            tag.count = counts[key]

            local show_count = true
            if KaeCatRescue.config.hide_x1 and tag.count == 1 then
                show_count = false
            end

            G.HUD_tags[#G.HUD_tags+1] = UIBox{
                definition = {
                    n = G.UIT.ROOT,
                    config = {align = "cm", padding = 0.05, colour = G.C.CLEAR},
                    nodes = {
                        right_sided and tag_sprite_ui or nil,
                        {n = G.UIT.C, config = {align = "cm", padding = padding}, nodes = {
                            show_count and {n = G.UIT.T, config = {
                                text = 'x'..tag.count,
                                scale = 0.4,
                                colour = G.C.UI.TEXT_LIGHT}
                            } or nil,
                        }},
                        left_sided and tag_sprite_ui or nil,
                    }
                },
                config = {
                    align = G.HUD_tags[1] and 'tm' or 'bri',
                    offset = G.HUD_tags[1] and {x = 0, y = 0} or {x = 1, y = 0},
                    major = G.HUD_tags[1] and G.HUD_tags[#G.HUD_tags] or G.ROOM_ATTACH
                },
            }
            if Handy then
                local _handy_tag_click_target = tag.tag_sprite
                local _handy_tag_click_ref = _handy_tag_click_target.click
                _handy_tag_click_target.click = function(...)
                    if Handy.controller.process_tag_click(tag) then return end
                    return _handy_tag_click_ref(...)
                end
            end
            done[key] = {
                HUD_tag = G.HUD_tags[#G.HUD_tags],
                tag = tag
            }
        end
        
        tag.HUD_tag = done[key].HUD_tag
    end
    KaeCatRescue.tag_count = 0
    for _, tag in pairs(done) do
        KaeCatRescue.tag_count = KaeCatRescue.tag_count + tag.tag.count
    end
end 

--[[ Register commands for debugplus ]]
local success, dpAPI = pcall(require, "debugplus-api")
if success and dpAPI.isVersionCompatible(1) then
    local debugplus = dpAPI.registerID("KaeCatRescue")
    local commands = {}
    table.insert(commands, {
        name = "save",
        shortDesc = "Save the game",
        desc = "Manually save the game. Be careful if there are events running!",
        exec = function(args, rawArgs, dp)
            if G.STAGE ~= G.STAGES.RUN then
                return "ERROR: can only use this command during a run"
            end
            save_run()
            return "Saved"
        end,
    })
    table.insert(commands, {
        name = "menu",
        shortDesc = "Quit to main menu",
        desc = "Quit to the main menu without saving",
        exec = function(args, rawArgs, dp)
            if G.STAGE ~= G.STAGES.RUN then
                return "ERROR: can only use this command during a run"
            end
            G.FUNCS.go_to_menu()
            return "Returned to menu"
        end,
    })
    table.insert(commands, {
        name = "quit",
        shortDesc = "Quit to desktop",
        desc = "Close Balatro without saving",
        exec = function(args, rawArgs, dp)
            G.FUNCS.quit()
        end,
    })

    table.insert(commands, {
        name = "kcr",
        shortDesc = "Kaedenn's Cat Rescue command",
        desc = "List KCR commands or invoke a KCR command",
        exec = function(args, rawArgs, dp)
            local cmdlib = assert(SMODS.load_file("Lib/kcr_commands.lua", "KaeCatRescue"))()
            local kcr_commands = cmdlib.KCRCommands
            if #args == 0 or args[1] == "help" then
                local lines = {"Commands added by KaeCatRescue:"}
                if args[1] == "help" then
                    for _, command in ipairs(commands) do
                        table.insert(lines, ("%s: %s"):format(
                            command.name,
                            command.desc or command.shortDesc))
                    end
                end
                for _, command in ipairs(kcr_commands) do
                    table.insert(lines, ("%s: %s"):format(
                        "kcr " .. command.name,
                        args[1] == "help" and command.desc or command.shortDesc))
                end
                return table.concat(lines, "\n")
            end

            for _, command in ipairs(kcr_commands) do
                if command.name == args[1] then
                    return command.exec(args, rawArgs, dp)
                end
            end
            print("ERROR: Cannot find command matching " .. rawArgs)
        end,
    })

    for _, command in ipairs(commands) do
        debugplus.addCommand(command)
    end
end
