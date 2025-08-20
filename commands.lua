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
        name = "debug",
        desc = "Toggle debugging",
        exec = function(args, rawArgs, dp)
            BetterTagsPlus.config.debug = not BetterTagsPlus.config.debug
            if BetterTagsPlus.config.debug then
                return "BetterTagsPlus: debugging on"
            end
            return "BetterTagsPlus: debugging off"
        end,
    },
    {
        name = "config",
        shortDesc = "Display or update configuration",
        desc = "Display configuration or update individual keys",
        exec = function(args, rawArgs, dp)
            if #args == 1 then
                for key, val in pairs(BetterTagsPlus.config) do
                    print(("BetterTagsPlus.config.%s = [%s] %s"):format(
                        key, type(val), val))
                end
                return true
            end
            if args[2] == "set" then
                if #args ~= 4 then
                    print("Usage: 'config set <key> <value>'")
                    return false
                end

                local key, val = args[3], args[4]
                if BetterTagsPlus.config[key] == nil then
                    print(("Invalid configuration option %s"):format(args[3]))
                    return false
                end

                local valtype = type(BetterTagsPlus.config[key])
                local value = val
                if valtype == "number" then
                    value = tonumber(val)
                elseif valtype == "boolean" then
                    value = (val == "true" or val == "1")
                elseif valtype ~= "string" then
                    print(("Refusing to store '%s' to %s %s"):format(
                        val, valtype, key))
                    return false
                end

                print(("Setting %s = [%s] %s"):format(key, valtype, value))
                BetterTagsPlus.config[key] = value
                return true
            end

            print(("Invalid subcommand %s"):format(args[2]))
            return false
        end
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
