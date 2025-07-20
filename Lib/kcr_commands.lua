--[[
-- This file exists to allow for commands to be added or modified
-- without needing to restart Balatro.
--]]

local commands = {
    {
        name = "monitor-events",
        shortDesc = "Monitor events",
        desc = "Add monitoring information to events",
        exec = function(args, rawArgs, dp)
            local save_event_init = Event.init
            Event.init = function(self, config)
                if config.func then
                    self.func_info = debug.getinfo(config.func)
                end
                return save_event_init(self, config)
            end
        end,
    },
    {
        name = "show-events",
        shortDesc = "Show queued events",
        desc = "Show information about the queued events",
        exec = function(args, rawArgs, dp)
            for idx, entry in ipairs(G.E_MANAGER.queues.base) do
                if entry.func then
                    local info = entry.func_info or debug.getinfo(entry.func)
                    print(("%d: %s:%s"):format(idx, info.short_src, info.linedefined))
                end
            end
        end,
    },
    {
        name = "list",
        shortDesc = "Count cat tags",
        desc = "This command counts the current number of cat tags",
        exec = function(args, rawArgs, dp)
            local tally = assert(SMODS.load_file("Lib/cat_tally.lua", "KaeCatRescue"))()
            return tally.tally_cat_tags()
        end,
    },
    {
        name = "collect",
        shortDesc = "Count collected cat tags",
        desc = "This command counts the cat tags you'd have after combining",
        exec = function(args, rawArgs, dp)
            local tally = assert(SMODS.load_file("Lib/cat_tally.lua", "KaeCatRescue"))()
            return tally.collect_cat_tags{asstr=true}
        end,
    },
    -- Internal commands not intended for general use
    {
        name = "config",
        shortDesc = "[Internal] Dump configuration object",
        desc = "[Internal] Dump the current configuration object",
        exec = function(args, rawArgs, dp)
            return KaeCatRescue.config
        end,
    },
    {
        name = "debug",
        shortDesc = "[Internal] Debugging",
        desc = "[Internal] Debugging access",
        exec = function(args, rawArgs, dp)
            print("Args:", args)
            print("Raw Args:", rawArgs)
            print("DebugPlus:", dp)
        end,
    },
}

return {
    KCRCommands = commands
}
