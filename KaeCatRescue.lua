if not KaeCatRescue then KaeCatRescue = {} end

KaeCatRescue.config = SMODS.current_mod.config

local function load_module(path)
    return assert(SMODS.load_file(path, "KaeCatRescue"))()
end

load_module("Lib/tag_ui.lua")

--[[ Called to draw the mod's config box ]]
SMODS.current_mod.config_tab = function()
    return load_module("config_ui.lua")()
end

local function getTagKey(tag)
    if tag.key == "tag_cry_cat" then
        return ("tag_cry_cat-%d"):format(tag.ability and tag.ability.level or 1)
    end
    return tag.key
end

--[[ This function is called by the Lovely injection ]]
function kcrGenerateTagUi(do_reload)
    if do_reload then
        load_module("Lib/tag_ui.lua")
    end

    -- We're in the main menu, likely
    if not G.HUD_tags then
        return false
    end

    if G.HUD_tags and #G.HUD_tags > 0 then
        for key, val in pairs(G.HUD_tags) do
            val:remove()
            G.HUD_tags[key] = nil
        end
    end

    local counts = {}
    for _, tag in pairs(G.GAME.tags) do
        counts[getTagKey(tag)] = (counts[getTagKey(tag)] or 0) + 1
    end
    local done = {}
    for _, tag in pairs(G.GAME.tags) do
        local key = getTagKey(tag)
        if not done[key] then
            tag.count = counts[key]
            G.HUD_tags[#G.HUD_tags+1] = kcrGenerateSingleTagUi(tag)
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
        --if not tag.HUD_tag then
            tag.HUD_tag = done[key].HUD_tag
        --end
    end

    -- Ensure the tags don't scroll off-screen (taken from Cryptid)
    if #G.HUD_tags > 13 then
        for i = 2, #G.HUD_tags do
            G.HUD_tags[i].config.offset.y = 0.9 - 0.9 * 13 / #G.HUD_tags
        end
    end

    KaeCatRescue.tag_count = 0
    for _, tag in pairs(done) do
        KaeCatRescue.tag_count = KaeCatRescue.tag_count + tag.tag.count
    end

    return true
end 

--[[ Register commands for debugplus ]]
local success, dpAPI = pcall(require, "debugplus-api")
if success and dpAPI.isVersionCompatible(1) then
    local debugplus = dpAPI.registerID("KaeCatRescue")
    local commands = {}
    table.insert(commands, {
        name = "kcr",
        shortDesc = "Kaedenn's Cat Rescue command",
        desc = "List KCR commands or invoke a KCR command",
        exec = function(args, rawArgs, dp)
            local cmdlib = load_module("commands.lua")
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
                table.insert(lines, "kcr help: List KCR commands")
                return table.concat(lines, "\n")
            end

            for _, command in ipairs(kcr_commands) do
                if command.name == args[1] then
                    return command.exec(args, rawArgs, dp)
                end
            end
            return "ERROR: Cannot find command matching " .. rawArgs
        end,
    })

    for _, command in ipairs(commands) do
        debugplus.addCommand(command)
    end
end
