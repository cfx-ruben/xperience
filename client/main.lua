local config = require 'shared.config'
local Xperience = {}
local event = 'playerSpawned'

if config.framework == 'esx' then
    event = 'esx:playerLoaded'
elseif config.framework == 'qb' then
    event = 'QBCore:Client:OnPlayerLoaded'
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CreateThread(function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(100)
        end

        Wait(1500)

        if not Xperience.Initialised then
            TriggerServerEvent('xperience:server:load')
        end
    end)
end)

RegisterKeyMapping('+xperience', 'Show Rank Bar', 'keyboard', config.key)

function Xperience:Init(data)
    self.CurrentXP      = tonumber(data.xp)
    self.CurrentRank    = tonumber(data.rank)

    self:InitialiseUI()

    RegisterCommand('+xperience', function()
        if self.Initialised then
            self:ToggleUI()
        end
    end)
    RegisterCommand('-xperience', function() end)

    TriggerEvent('chat:addSuggestion', '/addXP', 'Give XP to player', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to award' }
    })

    TriggerEvent('chat:addSuggestion', '/removeXP', 'Deduct XP from player', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to deduct' }
    })

    TriggerEvent('chat:addSuggestion', '/setXP', 'Set a player\'s current XP', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to set' }
    })

    TriggerEvent('chat:addSuggestion', '/setRank', 'Set a player\'s current rank', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "rank",        help = 'The rank value to set' }
    })
end


----------------------------------------------------
--                 EVENT CALLBACKS                --
----------------------------------------------------

function Xperience:OnRankChange(data, cb)
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

function Xperience:OnUIInitialised(data, cb)
    self.Initialised = true
    self.UIOpen = false

    cb('ok')
end

function Xperience:OnSave(data, cb)
    self:SetData(data.xp)

    TriggerServerEvent('xperience:server:save', self.CurrentXP, self.CurrentRank)

    cb('ok')
end

function Xperience:OnUIClosed(data, cb)
    self.UIOpen = false
    cb('ok')
end


----------------------------------------------------
--                       UI                       --
----------------------------------------------------

function Xperience:InitialiseUI()
    local ranks = self:GetRanksForUI()
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
        xp = self:GetXP(),
        ranks = ranks,
        timeout = config.timeout,
        theme = theme,
    })
end

function Xperience:OpenUI()
    self.UIOpen = true
    SendNUIMessage({ event = 'show' })
end

function Xperience:CloseUI()
    self.UIOpen = false
    SendNUIMessage({ event = 'hide' })
end

function Xperience:ToggleUI()
    if self.UIOpen then
        self:CloseUI()
    else
        self:OpenUI()
    end
end

----------------------------------------------------
--                    SETTERS                     --
----------------------------------------------------

function Xperience:AddXP(xp)
    if not IsInt(xp) then
        return
    end

    self:SetData(xp)

    SendNUIMessage({
        event = 'add',
        xp = xp
    })
end

function Xperience:RemoveXP(xp)
    if not IsInt(xp) then
        return
    end

    local newXP = self:GetXP() - xp

    self:SetData(newXP)

    SendNUIMessage({
        event = 'remove',
        xp = xp
    })
end

function Xperience:SetXP(xp)
    if not IsInt(xp) then
        return
    end

    self:SetData(xp)

    SendNUIMessage({
        event = 'set',
        xp = xp
    })
end

function Xperience:SetRank(rank)
    rank = tonumber(rank)

    if not rank or not config.ranks[rank] then
        PrintError('Invalid rank (' .. tostring(rank) .. ') passed to SetRank method')
        return
    end

    local newXP = config.ranks[rank].XP

    if newXP ~= nil then
        if newXP > self.CurrentXP then
            self:AddXP(newXP - self.CurrentXP)
        elseif newXP < self.CurrentXP then
            self:RemoveXP(self.CurrentXP - newXP)
        end
    end
end

function Xperience:SetData(xp)
    self.CurrentXP = self:LimitXP(xp)
    self.CurrentRank = self:GetRank(xp)
end


----------------------------------------------------
--                    GETTERS                     --
----------------------------------------------------

function Xperience:GetXP()
    return tonumber(self.CurrentXP)
end

function Xperience:GetMaxXP()
    return config.ranks[#config.ranks].XP
end

function Xperience:GetXPToNextRank()
    local currentRank = self:GetRank()

    if currentRank == #config.ranks then
        return 0
    end

    return config.ranks[currentRank + 1].XP - tonumber(self.CurrentXP)
end

function Xperience:GetXPToRank(rank)
    local GoalRank = tonumber(rank)
    -- Check for valid rank
    if not config.ranks[rank] or not GoalRank or (GoalRank < 1 or GoalRank > #config.ranks) then
        PrintError('Invalid rank ('.. GoalRank ..') passed to GetXPToRank method')
        return
    end

    local goalXP = tonumber(config.ranks[GoalRank].XP)

    return goalXP - self.CurrentXP
end

function Xperience:GetRank(xp)
    if xp == nil then
        return tonumber(self.CurrentRank)
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

function Xperience:GetMaxRank()
    return #config.ranks
end

function Xperience:SetTheme(theme)
    if theme == nil then
        return TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = { "xperience", 'A theme name is required' }
        })
    end

    if config.themes[theme] == nil then
        return TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = { "xperience", 'Invalid theme name' }
        })
    end

    SetResourceKvp('xp_theme', theme)

    -- Send the theme data to the NUI
    SendNUIMessage({
        event = 'theme',
        theme = {
            theme = theme,
            segments = config.themes[theme].segments,
            width = config.themes[theme].width,
        },
    })

    -- Let the player know the theme was changed successfully
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { "xperience", 'Theme set to: ' .. theme }
    })
end


----------------------------------------------------
--                    UTILITIES                   --
----------------------------------------------------
function Xperience:GetRanksForUI()
    local ranks = {}
    local len = #config.ranks

    for i = 1, len do
        ranks[i] = config.ranks[i].XP
    end

    return ranks
end

-- Prevent XP from going over / under limits
function Xperience:LimitXP(xp)
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

RegisterNetEvent('xperience:client:init', function(...) Xperience:Init(...) end)
RegisterNetEvent('xperience:client:addXP', function(...) Xperience:AddXP(...) end)
RegisterNetEvent('xperience:client:removeXP', function(...) Xperience:RemoveXP(...) end)
RegisterNetEvent('xperience:client:setXP', function(...) Xperience:SetXP(...) end)
RegisterNetEvent('xperience:client:setRank', function(...) Xperience:SetRank(...) end)

RegisterNUICallback('rankchange', function(...) Xperience:OnRankChange(...) end)
RegisterNUICallback('ui_initialised', function(...) Xperience:OnUIInitialised(...) end)
RegisterNUICallback('ui_closed', function(...) Xperience:OnUIClosed(...) end)
RegisterNUICallback('save', function(...) Xperience:OnSave(...) end)

RegisterCommand('setXPTheme', function(source, args) Xperience:SetTheme(args[1]) end)


----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------

exports('AddXP', function(...) return Xperience:AddXP(...) end)
exports('RemoveXP', function(...) return Xperience:RemoveXP(...) end)
exports('SetXP', function(...) return Xperience:SetXP(...) end)
exports('SetRank', function(...) return Xperience:SetRank(...) end)

exports('GetXP', function(...) return Xperience:GetXP(...) end)
exports('GetMaxXP', function(...) return Xperience:GetMaxXP(...) end)
exports('GetXPToRank', function(...) return Xperience:GetXPToRank(...) end)
exports('GetXPToNextRank', function(...) return Xperience:GetXPToNextRank(...) end)
exports('GetRank', function(...) return Xperience:GetRank(...) end)
exports('GetMaxRank', function(...) return Xperience:GetMaxRank(...) end)
exports('SetTheme', function(...) return Xperience:SetTheme(...) end)
