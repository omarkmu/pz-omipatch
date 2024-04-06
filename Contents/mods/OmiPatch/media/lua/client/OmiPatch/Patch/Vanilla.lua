---Minor vanilla patches.

local OmiPatch = require 'OmiPatch'

-- Patch to disable admin powers that are automatically enabled on game start.
OmiPatch.registerPatch {
    name = 'Vanilla_NoAdminPowersOnStart',
    onCreatePlayer = function(_, player)
        if player:getAccessLevel() == 'None' then
            return
        end

        player:setInvisible(false)
        player:setGhostMode(false)
    end,
    onFirstPlayerUpdate = function(_, player)
        if player:getAccessLevel() == 'None' then
            return
        end

        player:setGodMod(false)
    end,
}
