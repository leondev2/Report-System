ESX = exports['es_extended']:getSharedObject()

local reports = {}
local reportIdCounter = 1

RegisterServerEvent('modx:checkAdmin')
AddEventHandler('modx:checkAdmin', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer and isAdmin(xPlayer.getGroup()) then
        TriggerClientEvent('modx:openAdminPanel', src)
    else
        TriggerClientEvent('esx:showNotification', src, 'You do not have permission to use this command.')
    end
end)

RegisterServerEvent('modx:getPlayers')
AddEventHandler('modx:getPlayers', function()
    local src = source
    local players = ESX.GetPlayers()
    local playerList = {}
    
    for i=1, #players do
        local xPlayer = ESX.GetPlayerFromId(players[i])
        if xPlayer then
            table.insert(playerList, {
                id = players[i],
                name = xPlayer.getName()
            })
        end
    end
    
    TriggerClientEvent('modx:sendPlayers', src, playerList)
end)

RegisterServerEvent('modx:submitReport')
AddEventHandler('modx:submitReport', function(category, message, playerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local report = {
        id = reportIdCounter,
        playerId = src,
        playerName = xPlayer.getName(),
        category = category,
        message = message,
        reportedPlayerId = tonumber(playerId),
        time = os.time() * 1000,
        status = 'open'
    }
    
    reports[reportIdCounter] = report
    reportIdCounter = reportIdCounter + 1
    
    TriggerClientEvent('esx:showNotification', src, 'Report submitted successfully!')
    
    local players = ESX.GetPlayers()
    for i=1, #players do
        local xTarget = ESX.GetPlayerFromId(players[i])
        if xTarget and isAdmin(xTarget.getGroup()) then
            TriggerClientEvent('esx:showNotification', players[i], 'New report submitted! Use /reports to view it.')
        end
    end
end)

RegisterServerEvent('modx:getReports')
AddEventHandler('modx:getReports', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not isAdmin(xPlayer.getGroup()) then
        TriggerClientEvent('modx:sendReports', src, {})
        return
    end
    
    local reportsList = {}
    for id, report in pairs(reports) do
        table.insert(reportsList, report)
    end
    
    table.sort(reportsList, function(a, b)
        return a.time > b.time
    end)
    
    TriggerClientEvent('modx:sendReports', src, reportsList)
end)

RegisterServerEvent('modx:getReportDetails')
AddEventHandler('modx:getReportDetails', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not isAdmin(xPlayer.getGroup()) then
        TriggerClientEvent('modx:sendReportDetails', src, {})
        return
    end
    
    local report = reports[tonumber(reportId)]
    if report then
        TriggerClientEvent('modx:sendReportDetails', src, report)
    else
        TriggerClientEvent('modx:sendReportDetails', src, {})
    end
end)

RegisterServerEvent('modx:gotoReport')
AddEventHandler('modx:gotoReport', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not isAdmin(xPlayer.getGroup()) then return end
    
    local report = reports[tonumber(reportId)]
    if not report or report.status ~= 'open' then return end
    
    local targetId = report.reportedPlayerId or report.playerId
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, 'Player is no longer online.')
        return
    end
    
    TriggerClientEvent('modx:getPlayerCoords', targetId, src, 'goto')
end)

RegisterServerEvent('modx:bringReport')
AddEventHandler('modx:bringReport', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not isAdmin(xPlayer.getGroup()) then return end
    
    local report = reports[tonumber(reportId)]
    if not report or report.status ~= 'open' then return end
    
    local targetId = report.reportedPlayerId or report.playerId
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, 'Player is no longer online.')
        return
    end
    
    TriggerClientEvent('modx:getAdminCoords', src, targetId)
end)

RegisterServerEvent('modx:closeReport')
AddEventHandler('modx:closeReport', function(reportId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not isAdmin(xPlayer.getGroup()) then 
        print(('Player %s attempted to close report without permission!'):format(src))
        return 
    end
    
    local reportIdNum = tonumber(reportId)
    if not reportIdNum then
        print(('Invalid report ID: %s'):format(reportId))
        TriggerClientEvent('esx:showNotification', src, 'Invalid report ID.')
        return 
    end
    
    local report = reports[reportIdNum]
    if not report then 
        print(('Report %s not found!'):format(reportIdNum))
        TriggerClientEvent('esx:showNotification', src, 'Report not found.')
        return 
    end
    
    report.status = 'closed'
    report.adminId = src
    report.adminName = xPlayer.getName()
    report.closedTime = os.time() * 1000
    
    print(('Report %s closed by admin %s'):format(reportIdNum, xPlayer.getName()))
    TriggerClientEvent('esx:showNotification', src, 'Report #' .. reportIdNum .. ' has been closed.')
    
    local players = ESX.GetPlayers()
    for i=1, #players do
        local xTarget = ESX.GetPlayerFromId(players[i])
        if xTarget and isAdmin(xTarget.getGroup()) then
            TriggerClientEvent('modx:refreshReports', players[i])
        end
    end
end)

RegisterServerEvent('modx:receivePlayerCoords')
AddEventHandler('modx:receivePlayerCoords', function(adminSource, coords, action)
    if action == 'goto' then
        TriggerClientEvent('modx:gotoPlayer', adminSource, coords)
        TriggerClientEvent('esx:showNotification', adminSource, 'Teleported to player.')
    end
end)

RegisterServerEvent('modx:receiveAdminCoords')
AddEventHandler('modx:receiveAdminCoords', function(targetId, coords)
    TriggerClientEvent('modx:bringPlayer', targetId, coords)
    TriggerClientEvent('esx:showNotification', targetId, 'You have been brought by an admin.')
end)

function isAdmin(group)
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end
    return false
end