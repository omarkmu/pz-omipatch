---Main driver for handling and applying patches.
---@class omi.OmiPatchModule
---@field private patches table<string, omi.Patch>
local OmiPatch = {}

OmiPatch.utils = require 'OmiPatch/utils'
OmiPatch.patches = {}

---@class omi.Patch
---@field name string The unique name of the patch.
---@field dependencies string[]? List of mod dependency IDs.
---@field onCreatePlayer fun(self: omi.Patch, player: IsoPlayer, index: integer)? Function to run on player spawn, if the patch is enabled.
---@field onFirstPlayerUpdate fun(self: omi.Patch, player: IsoPlayer)? Function to run on the first player update, if the patch is enabled.
---@field onGameStart fun(self: omi.Patch)? Function to run on game start, if the patch is enabled.

local allowlist = {} ---@type string[]
local blocklist = {} ---@type string[]
local cachedAllowStr ---@type string
local cachedBlockStr ---@type string

local trim = string.trim
local split = string.split


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

---Checks whether a patch should be applied.
---@param patch omi.Patch
---@return boolean
local function shouldApplyPatch(patch)
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

---Updates the cached allow and block lists.
local function updateAllowBlockLists()
    local allowStr = trim(SandboxVars.OmiPatch.Allowlist)
    local blockStr = trim(SandboxVars.OmiPatch.Blocklist)
    if allowStr ~= cachedAllowStr then
        if #allowStr > 0 then
            allowlist = split(allowStr, ';')
        else
            allowlist = {}
        end

        cachedAllowStr = allowStr
    end

    if blockStr ~= cachedBlockStr then
        if #blockStr > 0 then
            blocklist = split(blockStr, ';')
        else
            blocklist = {}
        end

        cachedBlockStr = blockStr
    end
end

---Applies enabled patches with a registered callback.
---@param callback string The name of the patch function callback to trigger.
---@param ... unknown Arguments for patch function callbacks.
local function applyPatches(callback, ...)
    updateAllowBlockLists()

    for _, patch in pairs(OmiPatch.patches) do
        local cb = patch[callback]
        if cb and shouldApplyPatch(patch) then
            cb(patch, ...)
        end
    end
end


---Checks whether a patch is enabled by name.
---@param name string
---@return boolean
function OmiPatch.isPatchEnabled(name)
    local patch = OmiPatch.patches[name]
    if not patch then
        return false
    end

    updateAllowBlockLists()
    return shouldApplyPatch(patch)
end

---Registers a new patch.
---@param patch omi.Patch
function OmiPatch.registerPatch(patch)
    OmiPatch.patches[patch.name] = patch
end


---@protected
function OmiPatch._onGameStart()
    applyPatches('onGameStart')
end

---@param index integer
---@param player IsoPlayer
---@protected
function OmiPatch._onCreatePlayer(index, player)
    applyPatches('onCreatePlayer', player, index)
end

---@param player IsoPlayer
function OmiPatch._onFirstPlayerUpdate(player)
    Events.OnPlayerUpdate.Remove(OmiPatch._onFirstPlayerUpdate)
    applyPatches('onFirstPlayerUpdate', player)
end


Events.OnGameStart.Add(OmiPatch._onGameStart)
Events.OnCreatePlayer.Add(OmiPatch._onCreatePlayer)
Events.OnPlayerUpdate.Add(OmiPatch._onFirstPlayerUpdate)

return OmiPatch
