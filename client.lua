local isUIOpen = false

ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

RegisterCommand('report', function()
    if isUIOpen then return end
    
    SetNuiFocus(true, true)
    SendNUIMessage({type = 'openReport'})
    isUIOpen = true
end, false)

RegisterCommand('reports', function(source, args)
    if isUIOpen then return end
    
    TriggerServerEvent('modx:checkAdmin')
end, false)

RegisterNetEvent('modx:openAdminPanel')
AddEventHandler('modx:openAdminPanel', function()
    SetNuiFocus(true, true)
    SendNUIMessage({type = 'openAdmin'})
    isUIOpen = true
end)

RegisterNetEvent('modx:refreshReports')
AddEventHandler('modx:refreshReports', function()
    if isUIOpen then
        TriggerServerEvent('modx:getReports')
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

RegisterNUICallback('getPlayers', function(data, cb)
    TriggerServerEvent('modx:getPlayers')
    cb('ok')
end)

RegisterNetEvent('modx:sendPlayers')
AddEventHandler('modx:sendPlayers', function(players)
    SendNUIMessage({type = 'playersList', players = players})
end)

RegisterNUICallback('submitReport', function(data, cb)
    TriggerServerEvent('modx:submitReport', data.category, data.message, data.playerId)
    cb('ok')
end)

RegisterNUICallback('getReports', function(data, cb)
    TriggerServerEvent('modx:getReports')
    cb('ok')
end)

RegisterNetEvent('modx:sendReports')
AddEventHandler('modx:sendReports', function(reports)
    SendNUIMessage({type = 'reportsList', reports = reports})
end)

RegisterNUICallback('getReportDetails', function(data, cb)
    TriggerServerEvent('modx:getReportDetails', data.reportId)
    cb('ok')
end)

RegisterNetEvent('modx:sendReportDetails')
AddEventHandler('modx:sendReportDetails', function(report)
    SendNUIMessage({type = 'reportDetails', report = report})
end)

RegisterNUICallback('gotoReport', function(data, cb)
    TriggerServerEvent('modx:gotoReport', data.reportId)
    cb('ok')
end)

RegisterNUICallback('bringReport', function(data, cb)
    TriggerServerEvent('modx:bringReport', data.reportId)
    cb('ok')
end)

RegisterNUICallback('closeReport', function(data, cb)
    print('Closing report:', data.reportId)
    TriggerServerEvent('modx:closeReport', data.reportId)
    cb('ok')
end)

RegisterNetEvent('modx:getPlayerCoords')
AddEventHandler('modx:getPlayerCoords', function(adminSource, action)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    TriggerServerEvent('modx:receivePlayerCoords', adminSource, coords, action)
end)

RegisterNetEvent('modx:getAdminCoords')
AddEventHandler('modx:getAdminCoords', function(targetId)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    TriggerServerEvent('modx:receiveAdminCoords', targetId, coords)
end)

RegisterNetEvent('modx:gotoPlayer')
AddEventHandler('modx:gotoPlayer', function(coords)
    local ped = PlayerPedId()
    
    DoScreenFadeOut(1000)
    Citizen.Wait(1000)
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    
    DoScreenFadeIn(1000)
    ESX.ShowNotification('Teleported to player.')
end)

RegisterNetEvent('modx:bringPlayer')
AddEventHandler('modx:bringPlayer', function(coords)
    local ped = PlayerPedId()

    DoScreenFadeOut(1000)
    Citizen.Wait(1000)
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    
    DoScreenFadeIn(1000)
    ESX.ShowNotification('You have been brought by an admin.')
end)

function isAdmin(group)
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 322) and isUIOpen then 
            SetNuiFocus(false, false)
            SendNUIMessage({type = 'closeAll'})
            isUIOpen = false
        end
    end
end)