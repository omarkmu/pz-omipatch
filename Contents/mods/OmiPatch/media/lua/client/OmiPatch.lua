---Main driver for handling and applying patches.
---@class omi.OmiPatchModule
---@field private patches table<string, omi.Patch>
local OmiPatch = {}

OmiPatch.utils = require 'OmiPatch/utils'
OmiPatch.patches = {}

---@class omi.Patch
---@field name string The unique name of the patch.
---@field dependencies string[]? A list of mod dependency IDs.
---@field onCreatePlayer fun(self: omi.Patch, player: IsoPlayer, index: integer)? The patch function to run on player spawn, if the patch is enabled.
---@field onGameStart fun(self: omi.Patch)? The patch function to run on game start, if the patch is enabled.


---Checks whether a patch's dependencies are available.
---@param patch any
---@return boolean
local function checkPatchDependencies(patch)
    -- no dependencies → allow
    if not patch.dependencies then
        return true
    end

    -- ignore option enabled → allow
    if SandboxVars.OmiPatch.IgnorePatchDependencies then
        return true
    end

    -- check dependencies against active mods
    local activeMods = getActivatedMods()
    for i = 1, #patch.dependencies do
        local dep = patch.dependencies[i]
        if not activeMods:contains(dep) then
            return false
        end
    end

    return true
end

---Returns the configured allow and blocklists.
---@return string[]
---@return string[]
local function getAllowBlockLists()
    local allowlistStr = string.trim(SandboxVars.OmiPatch.Allowlist)
    local blocklistStr = string.trim(SandboxVars.OmiPatch.Blocklist)

    local allowlist
    local blocklist

    if #allowlistStr > 0 then
        allowlist = string.split(allowlistStr, ';')
    else
        allowlist = {}
    end

    if #blocklistStr > 0 then
        blocklist = string.split(blocklistStr, ';')
    else
        blocklist = {}
    end

    return allowlist, blocklist
end


---Checks whether a patch is enabled by name.
---@param name string
---@return boolean
function OmiPatch.isPatchEnabled(name)
    local patch = OmiPatch.patches[name]
    if not patch then
        return false
    end

    local allowlist, blocklist = getAllowBlockLists()
    return OmiPatch.shouldApplyPatch(patch, allowlist, blocklist)
end

---Registers a new patch by name.
---@param patch omi.Patch
function OmiPatch.registerPatch(patch)
    OmiPatch.patches[patch.name] = patch
end

---Checks whether a patch should be applied.
---@param patch omi.Patch
---@param allowlist table
---@param blocklist table
---@return boolean
function OmiPatch.shouldApplyPatch(patch, allowlist, blocklist)
    if #allowlist > 0 then
        local found = false
        for _, name in pairs(allowlist) do
            if patch.name == name then
                found = true
                break
            end
        end

        if not found then
            return false
        end
    end

    for _, name in pairs(blocklist) do
        if patch.name == name then
            return false
        end
    end

    return checkPatchDependencies(patch)
end


---@protected
function OmiPatch._onGameStart()
    local allowlist, blocklist = getAllowBlockLists()

    for _, patch in pairs(OmiPatch.patches) do
        if patch.onGameStart and OmiPatch.shouldApplyPatch(patch, allowlist, blocklist) then
            patch:onGameStart()
        end
    end
end

---@param index integer
---@param player IsoPlayer
---@protected
function OmiPatch._onCreatePlayer(index, player)
    local allowlist, blocklist = getAllowBlockLists()

    for _, patch in pairs(OmiPatch.patches) do
        if patch.onCreatePlayer and OmiPatch.shouldApplyPatch(patch, allowlist, blocklist) then
            patch:onCreatePlayer(player, index)
        end
    end
end


Events.OnGameStart.Add(OmiPatch._onGameStart)
Events.OnCreatePlayer.Add(OmiPatch._onCreatePlayer)

return OmiPatch
