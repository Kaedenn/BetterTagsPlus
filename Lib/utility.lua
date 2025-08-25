
function btpFormatCallFrame(frame, absolute)
    local location = frame.short_src
    if not absolute and frame.currentline ~= -1 then
        location = ("%s:%d"):format(location, frame.currentline)
    end
    location = ("%s[%d:%d]"):format(location, frame.linedefined, frame.lastlinedefined)
    if not absolute then
        if frame.namewhat and frame.namewhat ~= "" then
            location = ("%s %s"):format(location, frame.namewhat)
        end
    end
    if frame.what ~= "Lua" then
        location = ("%s (%s)"):format(location, frame.what)
    end
    return location
end

--[[ Get the current stack trace.
--
-- @param above_func fun() report frames above this function
-- @return table frames formatted as strings
--]]
function btpGetStackTrace(above_func)
    local frames = {}
    local level = 1
    local info = debug.getinfo(level)
    local reference_frame = nil
    if above_func and type(above_func) == "function" then
        reference_frame = btpFormatCallFrame(debug.getinfo(above_func), true)
    end
    while info do
        local cmp_frame = btpFormatCallFrame(info, true)
        if reference_frame and cmp_frame == reference_frame then
            frames = {}
        elseif info.what ~= "C" then
            local frame = btpFormatCallFrame(info)
            table.insert(frames, frame)
        end
        level = level + 1
        info = debug.getinfo(level)
    end
    return frames
end


function btpDebug(message)
    if BetterTagsPlus.config.debug then
        -- Determine stack trace starting at level above btpDebug
        local stack_trace = btpGetStackTrace(btpDebug)
        local caller_frame = nil
        if #stack_trace > 0 then
            caller_frame = stack_trace[1]
        else
            -- Unreliable; use only as a fallback
            caller_frame = btpFormatCallFrame(debug.getinfo(2))
        end
        print(("KDB [%s]: %s"):format(caller_frame, message))
    end
end

