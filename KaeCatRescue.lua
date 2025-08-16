if not KaeCatRescue then KaeCatRescue = {} end
local MOD_NAME = "KaeCatRescue"

KaeCatRescue.config = SMODS.current_mod.config

function kcrDebug(message)
    if KaeCatRescue.config.debug then
        print(message)
    end
end

local function load_module(path)
    return assert(SMODS.load_file(path, MOD_NAME))()
end

load_module("Lib/tag_ui.lua")

--[[ Called to draw the mod's config box ]]
SMODS.current_mod.config_tab = function()
    return load_module("Lib/config_ui.lua")()
end

--[[ Obtain a key that can be used to combine like tags ]]
local function getTagKey(tag)
    if tag.key == "tag_cry_cat" then
        -- "tag_cry_cat-01", "tag_cry_cat-10", etc
        return ("%s-%02d"):format(tag.key, tag.ability and tag.ability.level or 1)
    end
    return tag.key
end

--[[ This function is called by the Lovely injection to draw the tags ]]
function kcrGenerateTagUi(do_reload, do_reduce_motion)
    if do_reload then
        load_module("Lib/tag_ui.lua")
    end

    -- We're in the main menu, likely
    if not G.HUD_tags then
        return false
    end

    local counts = {}
    for _, tag in pairs(G.GAME.tags) do
        local key = getTagKey(tag)
        counts[key] = (counts[key] or 0) + 1
    end

    --[[ TODO:
    -- Preserve G.HUD_tags entries if there are no changes
    --
    -- Instead of removing all tags, remove tags with count 0
    -- Instead of inserting all tags, insert tags with newly nonzero count
    -- Ensure G.HUD_tags is sorted at all times (table.insert)
    --]]
    if G.HUD_tags and #G.HUD_tags > 0 then
        for idx, val in pairs(G.HUD_tags) do
            val:remove()
            G.HUD_tags[idx] = nil
        end
    end

    local done = {}
    for _, tag in pairs(G.GAME.tags) do
        local key = getTagKey(tag)
        if not done[key] then
            tag.count = counts[key]
            local hud_tag, sprite_tag = kcrGenerateSingleTagUi(tag, do_reduce_motion)
            G.HUD_tags[#G.HUD_tags+1] = hud_tag
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

    -- Ensure the tags don't scroll off-screen (taken from Cryptid)
    if #G.HUD_tags > 13 then
        for i = 2, #G.HUD_tags do
            G.HUD_tags[i].config.offset.y = 0.9 - 0.9 * 13 / #G.HUD_tags
        end
    end

    -- TODO: Figure out why this exists in BetterTags
    KaeCatRescue.tag_count = 0
    for _, entry in pairs(done) do
        KaeCatRescue.tag_count = KaeCatRescue.tag_count + entry.tag.count
    end

    return true
end

--[[ This function is called by the Lovely injection to replace combining logic
--
-- @return boolean true to interrupt default behavior; false to invoke it
--]]
function kcrDoCombine(source, target)
    if KaeCatRescue.config.fast_combine then
        kcrDebug("Combining tags %s and %s quickly...", source, target)
    end
    return false
end

--[[ This function is called by the Lovely injection when combining tags ]]
function kcrOnTagCombined(source, target)
    if KaeCatRescue.config.autosave then
        local tag_level = (target.ability and target.ability.level or 1) + 1
        if tag_level >= KaeCatRescue.config.save_tag_min_level then
            kcrDebug("Saving...")
            save_run()
        end
    end
end

--[[ Register commands for debugplus ]]
local success, dpAPI = pcall(require, "debugplus-api")
if success and dpAPI.isVersionCompatible(1) then
    local debugplus = dpAPI.registerID(MOD_NAME)
    local commands = {}
    table.insert(commands, {
        name = "kcr",
        shortDesc = "Kaedenn's Cat Rescue command",
        desc = "List KCR commands or invoke a KCR command",
        exec = function(args, rawArgs, dp)
            local cmdlib = load_module("commands.lua")
            local kcr_commands = cmdlib.KCRCommands
            if #args == 0 or args[1] == "help" then
                local lines = {("Commands added by %s:"):format(MOD_NAME)}
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

