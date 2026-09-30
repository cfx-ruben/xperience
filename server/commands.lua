----------------------------------------------------
--                   COMMANDS                     --
----------------------------------------------------

-- Requires ace permissions: e.g. add_ace group.admin command.addXP allow

-- Allows for restarting the resource
lib.addCommand('restartXP', {
    help = 'Reinicia el sistema de experiencia y recarga las configuraciones',
    restricted = 'group.admin'
}, function(source)
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return
    end
    Restart()
end)

-- Award XP to player
lib.addCommand('addXP', {
    help = 'Dar XP a un jugador',
    params = {
        {
            name = 'playerId',
            type = 'playerId',
            help = 'ID del jugador'
        },
        {
            name = 'xp',
            type = 'number',
            help = 'XP a dar'
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return
    end
    TriggerClientEvent('xperience:client:addXP', args.playerId, args.xp)
end)

-- Deduct XP from player
lib.addCommand('removeXP', {
    help = 'Quitar XP a un jugador',
    params = {
        {
            name = 'playerId',
            type = 'playerId',
            help = 'ID del jugador'
        },
        {
            name = 'xp',
            type = 'number',
            help = 'XP a quitar'
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return
    end
    TriggerClientEvent('xperience:client:removeXP', args.playerId, args.xp)
end)

-- Set a player's XP
lib.addCommand('setXP', {
    help = 'Establecer la XP de un jugador',
    params = {
        {
            name = 'playerId',
            type = 'playerId',
            help = 'ID del jugador',
        },
        {
            name = 'xp',
            type = 'number',
            help = 'XP a establecer'
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return
    end
    TriggerClientEvent('xperience:client:setXP', args.playerId, args.xp)
end)

-- Set a player's rank
lib.addCommand('setRank', {
    help = 'Establece el nivel o rango de un jugador',
    params = {
        {
            name = 'playerId',
            type = 'playerId',
            help = 'ID del jugador',
        },
        {
            name = 'rank',
            type = 'number',
            help = 'Rango a establecer'
        },
    },
    restricted = 'group.admin'
}, function(source, args)
    if not exports.qbx_core:IsOptin(source) then
        exports.qbx_core:Notify(source, 'You are not opted in for admin duty. (/optin to toggle)', 'error')
        return
    end
    TriggerClientEvent('xperience:client:setRank', args.playerId, args.rank)
end)
