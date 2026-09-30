local config = require 'shared.config'

function Init()
    local Ranks = CheckRanks()

    if #Ranks > 0 then
        print(json.encode(Ranks))
        return
    end

    local status = GetResourceState('qbx_core')
    if status ~= 'started' then
        return print(string.format('QBX is %s!', status))
    end
end

function Load(src)
    src = tonumber(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local result = {
        xp = tonumber(player.PlayerData.metadata.xp) or 0,
        rank = tonumber(player.PlayerData.metadata.rank) or 1
    }

    if config.debug then
        print(string.format("^5LOADED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), result.xp,
            result.rank))
    end

    TriggerClientEvent('xperience:client:init', src, result)
end

-- Rank that corresponds to a given amount of XP
local function RankFromXP(xp)
    local rank = 1
    for i = 1, #config.ranks do
        if tonumber(config.ranks[i].XP) <= xp then
            rank = i
        else
            break
        end
    end
    return rank
end

function Save(src, xp, rank)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    -- Never trust the client: validate the XP and derive the rank from it
    if not IsInt(xp) then return end

    xp = math.max(0, math.min(tonumber(xp), tonumber(config.ranks[#config.ranks].XP)))
    rank = RankFromXP(xp)

    player.Functions.SetMetaData('xp', xp)
    player.Functions.SetMetaData('rank', rank)
    player.Functions.Save()

    if config.debug then
        print(string.format("^5SAVED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), xp, rank))
    end
end

function GetPlayerXP(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if player then return tonumber(player.PlayerData.metadata.xp) or 0 end
    return false
end

function GetPlayerRank(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if player then return tonumber(player.PlayerData.metadata.rank) or 1 end
end

function GetPlayerXPToNextRank(playerId)
    local currentXP = GetPlayerXP(playerId)
    local currentRank = GetPlayerRank(playerId)
    if not currentXP or not currentRank then return end

    -- Already at max rank
    if currentRank >= #config.ranks then return 0 end

    return tonumber(config.ranks[currentRank + 1].XP) - tonumber(currentXP)
end

function GetPlayerXPToRank(playerId, rank)
    local currentXP = GetPlayerXP(playerId)
    rank = tonumber(rank)

    -- Check for valid rank
    if not rank or (rank < 1 or rank > #config.ranks) then
        print('Invalid rank (' .. tostring(rank) .. ') passed to GetPlayerXPToRank method')
        return
    end

    local goalXP = tonumber(config.ranks[rank].XP)

    return goalXP - currentXP
end

function CheckRanks()
    local Limit = #config.ranks
    local InValid = {}

    for i = 1, Limit do
        local RankXP = config.ranks[i].XP

        if not IsInt(RankXP) then
            table.insert(InValid, string.format('Rank %s: %s', i, RankXP))
            print(string.format('Invalid XP (%s) for Rank %s', RankXP, i))
        end
    end

    return InValid
end

function Restart()
    CreateThread(function()
        for i, src in pairs(GetPlayers()) do
            Load(src)
        end
    end)
end

CreateThread(function()
    Init()
end)

----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

RegisterNetEvent('xperience:server:load')
AddEventHandler('xperience:server:load', function()
    Load(source)
end)

RegisterNetEvent('xperience:server:save')
AddEventHandler('xperience:server:save', function(xp, rank)
    Save(source, xp, rank)
end)

----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------
exports('GetPlayerXP', GetPlayerXP)
exports('GetPlayerRank', GetPlayerRank)
exports('GetPlayerXPToRank', GetPlayerXPToRank)
exports('GetPlayerXPToNextRank', GetPlayerXPToNextRank)
