---Patches for Debug Trash UI to prevent errors and disallow deleting favorites.
---@diagnostic disable: undefined-global

local OmiPatch = require 'OmiPatch'

---Checks whether an item should be allowed for deletion.
---@param item InventoryItem
---@return boolean
local function allowDelete(item)
    if not OmiPatch.isPatchEnabled('DebugTrashUI_NoFavorites') then
        return true
    end

    return not item:isFavorite()
end

---Checks whether the given item is in a player inventory.
---@param item InventoryItem
---@return boolean
local function isInPlayerInventory(item)
    local container = item:getContainer()
    local parent = container and container:getParent()
    if not parent then
        return false
    end

    return parent == getPlayer()
end

---Replacement for the bugged `RemoveItemOption` function.
---@param player IsoPlayer
---@param context ISContextMenu
---@param items table
local function patchRemove(player, context, items)
    local seenItems = {}
    local isPlayerInv = false

    for i = 1, #items do
        local v = items[i]
        if instanceof(v, 'InventoryItem') then
            seenItems[v] = true
            isPlayerInv = isPlayerInv or isInPlayerInventory(v)
        elseif v.items and v.items[1] and isInPlayerInventory(v.items[1]) then
            isPlayerInv = true
            for _, item in pairs(v.items) do
                seenItems[item] = true
            end
        end
    end

    local itemList = {}
    for item in pairs(seenItems) do
        if allowDelete(item) then
            itemList[#itemList + 1] = item
        end
    end

    if not isPlayerInv or #itemList == 0 then
        return
    end

    local removeOption = context:addOption('Delete:')
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(removeOption, subMenu)
    subMenu:addOption('1 item', itemList[1], removeItem, player)
    subMenu:addOption('Selected', itemList, removeItems, player)
end


-- Patch to disable deletion of favorites.
-- This has no effect unless `DebugTrashUI_Fix` is enabled.
OmiPatch.registerPatch { name = 'DebugTrashUI_NoFavorites' }

-- Patch to fix errors in the option handling code.
OmiPatch.registerPatch {
    name = 'DebugTrashUI_Fix',
    dependencies = { 'Debug Trash UI' },
    onGameStart = function(_)
        OmiPatch.utils.patchEvent(
            'OnFillInventoryObjectContextMenu',
            RemoveItemOption,
            patchRemove
        )
    end,
}
