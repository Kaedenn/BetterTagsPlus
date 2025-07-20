--[[ DebugLib invocation:

eval SMODS.load_file("Lib/cat_tally.lua", "KaeCatRescue")().tally_cat_tags()
eval SMODS.load_file("Lib/cat_tally.lua", "KaeCatRescue")().collect_cat_tags()
eval SMODS.load_file("Lib/cat_tally.lua", "KaeCatRescue")().collect_cat_tags{asstr=true}

--]]

--[[ Determine the current cat tag counts ]]
function tally_cat_tags()
    local ability_levels = {}
    for i = 1, #G.GAME.tags do
        local tag = G.GAME.tags[i]
        if tag.key == "tag_cry_cat" then
            local level = tag.ability and tag.ability.level or 1
            if not ability_levels[level] then
                ability_levels[level] = 0
            end

            ability_levels[level] = ability_levels[level] + 1
        end
    end

    return ability_levels
end

--[[ Determine what the combined cat tags would look like.
--
-- @param args {tally: table?, asstr: boolean?}
-- @return table final tally, also including total clicks
--]]
function collect_cat_tags(args)
    local tally = args and args.tally or tally_cat_tags()
    local asstr = args and args.asstr or false

    local builder = setmetatable({}, {
        __index = function(self, key)
            return rawget(self, key) or 0
        end,
    })

    local stats = {clicks=0}

    local function add_entry(level)
        if builder[level] > 0 then
            stats.clicks = stats.clicks + 1
            builder[level] = builder[level] - 1
            add_entry(level + 1)
        else
            builder[level] = builder[level] + 1
        end
    end

    for i = 1, #G.GAME.tags do
        local tag = G.GAME.tags[i]
        if tag.key == "tag_cry_cat" then
            add_entry(tag.ability and tag.ability.level or 1)
        end
    end

    local result = {}
    for idx, count in pairs(builder) do
        if count ~= 0 then
            table.insert(result, idx)
        end
    end
    table.sort(result, function(v1, v2)
        return v1 < v2
    end)

    if asstr then
        local lines = {("Clicks: %d"):format(stats.clicks)}
        for _, entry in pairs(result) do
            table.insert(lines, ("Level %d"):format(entry))
        end
        return table.concat(lines, "\n")
    end
    result.clicks = stats.clicks
    return result
end

return {
    tally_cat_tags = tally_cat_tags,
    collect_cat_tags = collect_cat_tags,
}

-- vim: set ts=4 sts=4 sw=4:
