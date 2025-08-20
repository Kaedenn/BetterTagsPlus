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

--[[ Determine what's required to obtain the given Cat Tags
--
-- Display what's needed to obtain one Level 15 Cat Tag:
-- print(measure_progress_to({target={[15]=1}}))
--
-- Display what's needed to go from one Level 14 to one Level 15 Cat Tag:
-- print(measure_progress_to({tally={[14]=1}, target={[15]=1})
--
-- @param args {target: table, tally: table? asstr: boolean?}
-- @returns string if asstr=true
-- @returns pair num_tags: number, num_clicks: number otherwise
--]]
function measure_progress_to(args)
    if not args then error("missing args object") end
    local target = args.target or error("missing required kwarg target")
    local tally = args.tally or tally_cat_tags()

    local num_tags_curr = expand_tag_count(tally)
    local num_tags_target = expand_tag_count(target)
    if args.asstr then
        local need = num_tags_target - num_tags_curr
        if need < 0 then
            return ("You have %d more tags than you need"):format(-need)
        end
        return ("You need %d more tags"):format(need)
    end
    return num_tags_target - num_tags_curr, 0
end

--[[ Determine how many Cat Tags went into making the given tally
--
-- @param tally {[level] = count}
-- @return number
--]]
function expand_tag_count(tally)
    local total = 0
    for level, count in pairs(tally) do
        total = total + count * math.pow(2, level - 1)
    end
    return total
end

return {
    tally_cat_tags = tally_cat_tags,
    collect_cat_tags = collect_cat_tags,
    measure_progress_to = measure_progress_to,
    expand_tag_count = expand_tag_count,
}

-- vim: set ts=4 sts=4 sw=4:
