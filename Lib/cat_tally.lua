--[[ Support functions for analyzing cat tags ]]

--[[ Determine the current cat tag counts
--
-- @return table{[level] = count}
--]]
function tally_cat_tags()
    local ability_levels = {}
    for i = 1, #G.GAME.tags do
        local tag = G.GAME.tags[i]
        if tag.key == "tag_cry_cat" then
            local level = tag.ability and tag.ability.level or 1
            ability_levels[level] = (ability_levels[level] or 0) + 1
        end
    end
    return ability_levels
end

--[[ Determine what the combined cat tags would look like.
--
-- Condense current tags:
-- print(collect_cat_tags({asstr=true}))
--
-- Condense 500 Level 1 tags:
-- print(collect_cat_tags({tally={[1]=500}, asstr=true}))
--
-- @param args {tally: table?, asstr: boolean?}
-- @return string if asstr=true
-- @return table{level, clicks=number} otherwise
--]]
function collect_cat_tags(args)
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

    if args and args.tally then
        for level, count in ipairs(args.tally) do
            for i = 1, count do
                add_entry(level)
            end
        end
    else
        for i = 1, #G.GAME.tags do
            local tag = G.GAME.tags[i]
            if tag.key == "tag_cry_cat" then
                add_entry(tag.ability and tag.ability.level or 1)
            end
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
