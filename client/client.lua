local ESX = Framework.IsESX and Framework.Core or nil
local QBCore = Framework.IsQB and Framework.Core or nil
local storeOpen = false

if not Framework.Name then
	TriggerEvent("tw_tebexstore:notify", "tw_tebexstore: Could not detect a supported framework (ESX/QBCore/QBox). Check shared/config.lua.")
end

RegisterNetEvent('tw_tebexstore:notify', function(message)
	if Framework.IsESX then
		ESX.ShowNotification(message)
	elseif Framework.IsQB then
		QBCore.Functions.Notify(message, 'primary', 5000)
	end
end)


-- ============================================================
-- /loja UI
-- ============================================================

local function GetStoreData(cb)
	if Framework.IsESX then
		ESX.TriggerServerCallback('tw_tebexstore:getStoreData', cb)
	elseif Framework.IsQB then
		QBCore.Functions.TriggerCallback('tw_tebexstore:getStoreData', cb)
	end
end

local function OpenStore()
	if storeOpen then return end
	GetStoreData(function(data)
		if not data then return end
		storeOpen = true
		SetNuiFocus(true, true)
		SendNUIMessage({
			action = 'open',
			data = data,
		})
	end)
end

local function CloseStore()
	if not storeOpen then return end
	storeOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.StoreCommand, function()
	OpenStore()
end, false)

RegisterKeyMapping(Config.StoreCommand, 'Abrir a Loja TW-TebexStore', 'keyboard', '')

RegisterNUICallback('close', function(_, cb)
	CloseStore()
	cb('ok')
end)

RegisterNUICallback('redeem', function(payload, cb)
	local code = payload.code
	if not code or code == '' then
		cb({ success = false, message = 'Insere um Transaction ID válido.' })
		return
	end

	if Framework.IsESX then
		ESX.TriggerServerCallback('tw_tebexstore:redeemTransaction', function(success, message)
			cb({ success = success, message = message })
			if success then
				GetStoreData(function(data)
					SendNUIMessage({ action = 'refresh', data = data })
				end)
			end
		end, code)
	elseif Framework.IsQB then
		QBCore.Functions.TriggerCallback('tw_tebexstore:redeemTransaction', function(success, message)
			cb({ success = success, message = message })
			if success then
				GetStoreData(function(data)
					SendNUIMessage({ action = 'refresh', data = data })
				end)
			end
		end, code)
	end
end)
