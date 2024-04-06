---Contains utilities for applying patches.
local utils = {}

---Patches an event handler.
---@param name string The name of the event.
---@param old function The handler to remove.
---@param new function? An optional new handler to apply.
---@return boolean success
function utils.patchEvent(name, old, new)
    local event = Events[name]
    if not event then
        utils.warn('Attempted patch of unknown event: ' .. tostring(name))
        return false
    end

    if not old then
        -- nothing to patch
        return false
    end

    event.Remove(old)
    if new then
        event.Add(new)
    end

    return true
end

---Logs an error with the mod name prefix.
---@param err string The error string.
---@param ... unknown? Format args.
function utils.warn(err, ...)
    if select('#', ...) > 0 then
        err = string.format(err, ...)
    end

    print('[OmiPatch] ' .. err)
end

return utils
