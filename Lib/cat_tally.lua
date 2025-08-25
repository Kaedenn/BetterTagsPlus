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

--[[ Determine the number of double/triple/etc tags
--
-- @return table{[mult] = count}
--]]
function tally_tuple_tags()
    local counts = {}
    for i = 1, #G.GAME.tags do
        local tag = G.GAME.tags[i]
        if tag.config.type == "tag_add" then
            counts[tag.config.num] = (counts[tag.config.num] or 0) + 1
        end
    end
    return counts
end

--[[ Determine what the combined cat tags would look like
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
    if not args.asstr then
        return num_tags_target - num_tags_curr, 0
    end

    local need = num_tags_target - num_tags_curr
    if need < 0 then
        return ("You have %d more tags than you need"):format(-need)
    end
    local lines = {
        ("You need %d more tags"):format(need)
    }
    local tuple_tally = tally_tuple_tags()
    local pending = 0
    for mult, count in pairs(tuple_tally) do
        pending = pending + mult * count
    end
    local num_q_left = math.floor(need / 4)
    local num_t_left = need - (num_q_left * 4)
    if pending > 0 then
        local num_left = need - pending - 1
        num_q_left = math.floor(num_left / 4)
        num_t_left = num_left - (num_q_left * 4)
        table.insert(lines, ("You have %d tags pending"):format(pending))
        table.insert(lines, ("This leaves %d tags left"):format(need - pending - 1))
    end
    table.insert(lines, ("(attainable via %d * 4 + %d)"):format(num_q_left, num_t_left))
    return table.concat(lines, "\n")
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
    tally_tuple_tags = tally_tuple_tags,
    collect_cat_tags = collect_cat_tags,
    measure_progress_to = measure_progress_to,
    expand_tag_count = expand_tag_count,
}

-- vim: set ts=4 sts=4 sw=4:
