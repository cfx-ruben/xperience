local config = require 'shared.config'
local Initialised = false
local event = 'QBCore:Client:OnPlayerLoaded'

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(100)
        end

        Wait(1500)

        if not Initialised then
            TriggerServerEvent('xperience:server:load')
        end
    end)
end)

lib.addKeybind({
    name = 'xperience',
    description = 'Mostrar barra de rango',
    defaultKey = config.key or 'Z',
    onPressed = function()
        if Initialised then
            ToggleUI()
        end
    end
})

function Init(data)
    CurrentXP   = tonumber(data.xp)
    CurrentRank = tonumber(data.rank)

    InitialiseUI()
end

----------------------------------------------------
--                 EVENT CALLBACKS                --
----------------------------------------------------

function OnRankChange(data, cb)
    local player = PlayerPedId()
    local current = tonumber(data.current)
    local previous = tonumber(data.previous)

    if data.rankUp then
        TriggerEvent("xperience:client:rankUp", current, previous, player)
        TriggerServerEvent("xperience:server:rankUp", current, previous)
    else
        TriggerEvent("xperience:client:rankDown", current, previous, player)
        TriggerServerEvent("xperience:server:rankDown", current, previous)
    end

    local Rank = config.ranks[current]
    if Rank.Action ~= nil and type(Rank.Action) == "function" then
        Rank.Action(data.rankUp, previous, player)
    end

    cb('ok')
end

function OnUIInitialised(data, cb)
    Initialised = true
    UIOpen = false

    cb('ok')
end

function OnSave(data, cb)
    SetData(data.xp)
    TriggerServerEvent('xperience:server:save', CurrentXP, CurrentRank)
    cb('ok')
end

function OnUIClosed(data, cb)
    UIOpen = false
    cb('ok')
end

----------------------------------------------------
--                       UI                       --
----------------------------------------------------

function InitialiseUI()
    local ranks = GetRanksForUI()
    local savedTheme = GetResourceKvpString('xp_theme')
    local theme = {
        theme = config.theme,
        segments = config.themes[config.theme].segments,
        width = config.themes[config.theme].width,
    }

    if savedTheme and config.themes[savedTheme] ~= nil then
        theme = {
            theme = savedTheme,
            segments = config.themes[savedTheme].segments,
            width = config.themes[savedTheme].width,
        }
    else
        SetResourceKvp('xp_theme', config.theme)
    end

    SendNUIMessage({
        init = true,
        xp = GetXP(),
        ranks = ranks,
        timeout = config.timeout,
        theme = theme,
    })
end

function OpenUI()
    UIOpen = true
    SendNUIMessage({ event = 'show' })
end

function CloseUI()
    UIOpen = false
    SendNUIMessage({ event = 'hide' })
end

function ToggleUI()
    if UIOpen then
        CloseUI()
    else
        OpenUI()
    end
end

----------------------------------------------------
--                    SETTERS                     --
----------------------------------------------------

function AddXP(xp)
    if not IsInt(xp) then return end

    SetData(GetXP() + xp)

    SendNUIMessage({
        event = 'add',
        xp = xp
    })
end

function RemoveXP(xp)
    if not IsInt(xp) then return end

    local newXP = GetXP() - xp
    SetData(newXP)

    SendNUIMessage({
        event = 'remove',
        xp = xp
    })
end

function SetXP(xp)
    if not IsInt(xp) then return end

    SetData(xp)

    SendNUIMessage({
        event = 'set',
        xp = xp
    })
end

function SetRank(rank)
    rank = tonumber(rank)

    if not rank or not config.ranks[rank] then
        print('Invalid rank (' .. tostring(rank) .. ') passed to SetRank method')
        return
    end

    local newXP = config.ranks[rank].XP

    if newXP ~= nil then
        if newXP > CurrentXP then
            AddXP(newXP - CurrentXP)
        elseif newXP < CurrentXP then
            RemoveXP(CurrentXP - newXP)
        end
    end
end

function SetData(xp)
    CurrentXP = LimitXP(xp)
    CurrentRank = GetRank(xp)
end

----------------------------------------------------
--                    GETTERS                     --
----------------------------------------------------

function GetXP()
    return tonumber(CurrentXP)
end

function GetMaxXP()
    return config.ranks[#config.ranks].XP
end

function GetXPToNextRank()
    local currentRank = GetRank()

    if currentRank == #config.ranks then
        return 0
    end

    return config.ranks[currentRank + 1].XP - tonumber(CurrentXP)
end

function GetXPToRank(rank)
    local GoalRank = tonumber(rank)
    -- Check for valid rank
    if not GoalRank or not config.ranks[GoalRank] or (GoalRank < 1 or GoalRank > #config.ranks) then
        print('Invalid rank (' .. tostring(rank) .. ') passed to GetXPToRank method')
        return
    end

    local goalXP = tonumber(config.ranks[GoalRank].XP)

    return goalXP - CurrentXP
end

function GetRank(xp)
    if xp == nil then
        return tonumber(CurrentRank)
    end

    local len = #config.ranks
    for rank = 1, len do
        if rank < len then
            if config.ranks[rank + 1].XP > tonumber(xp) then
                return rank
            end
        else
            return rank
        end
    end
end

function GetMaxRank()
    return #config.ranks
end

----------------------------------------------------
--                    UTILITIES                   --
----------------------------------------------------
function GetRanksForUI()
    local ranks = {}
    local len = #config.ranks

    for i = 1, len do
        ranks[i] = config.ranks[i].XP
    end

    return ranks
end

-- Prevent XP from going over / under limits
function LimitXP(xp)
    local Max = tonumber(config.ranks[#config.ranks].XP)

    if xp > Max then
        xp = Max
    elseif xp < 0 then
        xp = 0
    end

    return xp
end

----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

RegisterNetEvent(event, function()
    Wait(1000)
    TriggerServerEvent('xperience:server:load')
end)

RegisterNetEvent('xperience:client:init', function(...)
    Init(...)
end)

RegisterNetEvent('xperience:client:addXP', function(...)
    AddXP(...)
end)

RegisterNetEvent('xperience:client:removeXP', function(...)
    RemoveXP(...)
end)

RegisterNetEvent('xperience:client:setXP', function(...)
    SetXP(...)
end)

RegisterNetEvent('xperience:client:setRank', function(...)
    SetRank(...)
end)

RegisterNUICallback('rankchange', function(...)
    OnRankChange(...)
end)

RegisterNUICallback('ui_initialised', function(...)
    OnUIInitialised(...)
end)

RegisterNUICallback('ui_closed', function(...)
    OnUIClosed(...)
end)

RegisterNUICallback('save', function(...)
    OnSave(...)
end)

----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------
exports('AddXP', AddXP)
exports('RemoveXP', RemoveXP)
exports('SetXP', SetXP)
exports('SetRank', SetRank)

exports('GetXP', GetXP)
exports('GetMaxXP', GetMaxXP)
exports('GetXPToRank', GetXPToRank)
exports('GetXPToNextRank', GetXPToNextRank)
exports('GetRank', GetRank)
exports('GetMaxRank', GetMaxRank)
