if not BetterTagsPlus then BetterTagsPlus = {} end
local MOD_NAME = "BetterTagsPlus"

BetterTagsPlus.config = SMODS.current_mod.config

function btpDebug(message)
    if BetterTagsPlus.config.debug then
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

--[[ Determine the edition for the given tag level ]]
local function getTagEdition(ability_level)
    local edition = G.P_CENTER_POOLS.Edition[1]
    local j = 1
    while j < ability_level + 1 do
        for i = 2, #G.P_CENTER_POOLS.Edition do
            j = j + 1
            if j >= ability_level + 1 then
                edition = G.P_CENTER_POOLS.Edition[i]
                break
            end
        end
    end
    return edition
end

btpOnlyOnce = false

--[[ This function is called by the Lovely injection to draw the tags ]]
function btpGenerateTagUi(do_reload, do_reduce_motion)
    if do_reload then
        load_module("Lib/tag_ui.lua")
    end

    -- We're in the main menu, likely
    if not G.HUD_tags then
        return false
    end

    if BetterTagsPlus.config.auto_combine then
        print("BTP auto-combine: this is not yet implemented")
        BetterTagsPlus.config.auto_combine = false

        --[[local libcat = load_module("Lib/cat_tally.lua")
        local tally = libcat.tally_cat_tags()
        local combined = libcat.collect_cat_tags({tally=tally})
        if combined.clicks > 0 then
            if not btpOnlyOnce then
                btpDebug(("Wanting to perform %d click(s)"):format(combined.clicks))
                G.E_MANAGER:add_event({
                    func = (function()
                    end)
                })
                btpOnlyOnce = true
            end
        end]]
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
            local hud_tag, sprite_tag = btpGenerateSingleTagUi(tag, do_reduce_motion)
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
    BetterTagsPlus.tag_count = 0
    for _, entry in pairs(done) do
        BetterTagsPlus.tag_count = BetterTagsPlus.tag_count + entry.tag.count
    end

    return true
end

--[[ This function is called by the Lovely injection to replace combining logic
--
-- @return boolean true to interrupt default behavior; false to invoke it
--]]
function btpDoCombine(self_cat, other_cat)
    if not BetterTagsPlus.config.fast_combine then return false end

    local pitch = math.min((other_cat.ability.level + 1)/10, 1)
    local edition = getTagEdition(other_cat.ability.level + 1)

    other_cat.ability.level = other_cat.ability.level + 1
    other_cat.ability.edshader = edition.shader
    play_sound(edition.sound.sound,
        (edition.sound.per or 1)*1.3,
        (edition.sound.vol or 0.25)*0.6)
    self_cat:remove()
    btpOnTagCombined(self_cat, other_cat)

    if self_cat.ability.shiny then
        if not Cryptid.shinytagdata[self_cat.key] then
            Cryptid.shinytagdata[self_cat.key] = true
            Cryptid.save()
        end
    end

    btpGenerateTagUi(false, true)

    return true
end

--[[ This function is called by the Lovely injection when combining tags ]]
function btpOnTagCombined(source, target)
    if BetterTagsPlus.config.autosave then
        local tag_level = (target.ability and target.ability.level or 1) + 1
        if tag_level >= BetterTagsPlus.config.save_tag_min_level then
            btpDebug("Saving...")
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
        name = "btp",
        shortDesc = "Better Tags Plus command",
        desc = "List BTP commands or invoke a BTP command",
        exec = function(args, rawArgs, dp)
            local cmdlib = load_module("commands.lua")
            local btp_commands = cmdlib.BTPCommands
            if #args == 0 or args[1] == "help" then
                local lines = {("Commands added by %s:"):format(MOD_NAME)}
                if args[1] == "help" then
                    for _, command in ipairs(commands) do
                        table.insert(lines, ("%s: %s"):format(
                        command.name,
                        command.desc or command.shortDesc))
                    end
                end
                for _, command in ipairs(btp_commands) do
                    table.insert(lines, ("%s: %s"):format(
                    "btp " .. command.name,
                    args[1] == "help" and command.desc or command.shortDesc))
                end
                table.insert(lines, "btp help: List BTP commands")
                return table.concat(lines, "\n")
            end

            for _, command in ipairs(btp_commands) do
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

