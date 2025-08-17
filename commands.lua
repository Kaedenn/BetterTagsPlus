--[[
-- This file exists to allow for commands to be added or modified
-- without needing to restart Balatro.
--]]

local commands = {
    {
        name = "redraw",
        shortDesc = "Redraw",
        desc = "Redraw the tags",
        exec = function(args, rawArgs, dp)
            btpGenerateTagUi(true)
        end,
    },
    {
        name = "count",
        shortDesc = "Count cat tags",
        desc = "This command counts the current number of cat tags",
        exec = function(args, rawArgs, dp)
            local tally = assert(SMODS.load_file("Lib/cat_tally.lua", "BetterTagsPlus"))()
            local lines = {}
            for level, count in pairs(tally.tally_cat_tags()) do
                local name = ("Level %s"):format(level)
                local suffix = ("x%d"):format(count)
                table.insert(lines, count == 1 and name or name .. " " .. suffix)
            end
            return table.concat(lines, "\n")
        end,
    },
    {
        name = "tally",
        shortDesc = "Count collected cat tags",
        desc = "This command counts the cat tags you'd have after combining",
        exec = function(args, rawArgs, dp)
            local tally = assert(SMODS.load_file("Lib/cat_tally.lua", "BetterTagsPlus"))()
            return tally.collect_cat_tags{asstr=true}
        end,
    },
}

return {
    BTPCommands = commands
}
