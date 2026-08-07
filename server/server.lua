local DiscordWebhook = 'CHANGE_WEBHOOK'
local inProgress = false
local inProgressSince = 0
local NumberCharset = {}
local Charset = {}
-- plateQuery is set from Garage.PlateQuery (shared/garage.lua) after shared scripts load
local plateQuery = Garage.PlateQuery or ''

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

local function GetRandomNumber(length)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

local function GetRandomLetter(length)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

local function GeneratePlate(depth)
	depth = (depth or 0) + 1
	if depth > 50 then
		print('^3[tw_tebexstore]: GeneratePlate: could not find a free plate after 50 tries — using random fallback^0')
		return ('TW%06d'):format(math.random(100000, 999999)):upper()
	end
	local plate = Config.SpaceInLicensePlate and GetRandomLetter(Config.LicensePlateLetters)..' '..GetRandomNumber(Config.LicensePlateNumbers) or GetRandomLetter(Config.LicensePlateLetters) .. GetRandomNumber(Config.LicensePlateNumbers)
	local result = MySQL.scalar.await(plateQuery, {plate})
	return result and GeneratePlate(depth) or plate:upper()
end

local DISCORD_NAME = "tw_tebexstore"
local DISCORD_IMAGE = "https://cdn3.emoji.gg/emojis/78118-tebex-logo.png"

-- Logs every notable event (purchases, redemptions, exploit attempts, subscription changes, ...) to
-- Discord (if Config.DiscordLogs is on) AND to tw_logs (if that resource is running), independently
-- of each other — disabling one does not affect the other.
local function LogEvent(name, message, color)
	if Config.DiscordLogs then
		if DiscordWebhook == "CHANGE_WEBHOOK" then
			print(message)
		else
			local connect = {
				{
					["color"] = color,
					["title"] = "**".. name .."**",
					["description"] = message,
					["footer"] = {
						["text"] = "Tebex - Store",
					},
				}
			}
			PerformHttpRequest(DiscordWebhook, function() end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatar_url = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
		end
	end

	if GetResourceState('tw_logs') == 'started' then
		local ok = pcall(function()
			exports.tw_logs:CreateLog({
				category = 'tebex',
				action = name,
				message = message,
				metadata = { color = color },
			})
		end)
	end
end

local ESX = Framework.IsESX and Framework.Core or nil
local QBCore = Framework.IsQB and Framework.Core or nil


AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		local tebexConvar = GetConvar('sv_tebexSecret', '')
		if tebexConvar == '' then
			print('^1[tw_tebexstore]: Tebex Secret Missing please set in server.cfg and try again. The script will not work without it.^0')
			StopResource(GetCurrentResourceName())
			return
		end
		if not Config.DiscordLogs then
			print('^3Webhooks Disabled^0') -- ^3 is the yellow color code for the console, ^0 is white to reset the color for everything after this message
		end
	end
end)

-- ============================================================
-- Framework helpers
-- ============================================================

local function GetPlayer(source)
	if Framework.IsESX then
		return ESX.GetPlayerFromId(source)
	elseif Framework.IsQB then
		return QBCore.Functions.GetPlayer(source)
	end
end

local function GetIdentifier(player)
	if Framework.IsESX then
		return player.identifier
	elseif Framework.IsQB then
		return player.PlayerData.citizenid
	end
end

local function GetPlayerDisplayName(player, source)
	if Framework.IsESX then
		return player.getName()
	elseif Framework.IsQB then
		return player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
	end
end


-- Looks up a player by framework identifier, only if they're currently online (source == nil otherwise).
local function GetOnlinePlayerByIdentifier(identifier)
	if Framework.IsESX then
		local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
		if xPlayer then return xPlayer.source, xPlayer end
	elseif Framework.IsQB then
		local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
		if player then return player.PlayerData.source, player end
	end
	return nil, nil
end

local function GrantItem(source, player, item)
	if item.type == 'item' or item.type == 'weapon' then
		local isWeapon = item.type == 'weapon'
		if Inventory.IsOx then
			if isWeapon then
				exports.ox_inventory:AddItem(source, item.name, 1, nil, {ammo = item.amount})
			else
				exports.ox_inventory:AddItem(source, item.name, item.amount)
			end
		elseif Inventory.IsQS then
			if isWeapon then
				exports['qs-inventory']:AddItem(source, item.name, 1, nil, {ammo = item.amount})
			else
				exports['qs-inventory']:AddItem(source, item.name, item.amount)
			end
		elseif Inventory.IsCustom then
			if isWeapon and Inventory.Custom.AddWeapon then
				Inventory.Custom.AddWeapon(source, item.name, item.amount)
			elseif Inventory.Custom.AddItem then
				Inventory.Custom.AddItem(source, item.name, item.amount)
			else
				print('^1[tw_tebexstore]: Inventory.Custom.AddItem/AddWeapon not defined in shared/inventory.lua^0')
			end
		elseif Framework.IsESX then
			if isWeapon then
				player.addWeapon(item.name, item.amount)
			else
				player.addInventoryItem(item.name, item.amount)
			end
		elseif Framework.IsQB then
			player.Functions.AddItem(item.name, item.amount)
		end
	elseif item.type == 'account' then
		if Framework.IsESX then
			player.addAccountMoney(item.name, item.amount)
		elseif Framework.IsQB then
			player.Functions.AddMoney(item.name, item.amount, "server-donation")
		end
	elseif item.type == 'car' then
		local identifier = GetIdentifier(player)
		local plate = GeneratePlate()
		local garage = Config.CarRewardGarage or 'legion'
		Garage.StoreVehicle(identifier, item.model, plate, garage)
		local playerName = GetPlayerDisplayName(player, source)
		TriggerClientEvent('tw_tebexstore:notify', source, _T('vehicle_added_garage', garage, plate))
		LogEvent('Veículo Adicionado à Garagem', '**Jogador:** ' .. playerName .. '\n**Modelo:** ' .. item.model .. '\n**Matrícula:** ' .. plate .. '\n**Garagem:** ' .. garage, 3066993)
	end
	-- "physical" items are not auto-granted, they are only logged for staff fulfillment
end

-- Custom reward types: check Config.RewardHandlers first, fall back to the generic event.
-- Built-in types (item/weapon/account/car) always go through GrantItem.
local function GrantCustomReward(source, player, reward)
	if reward.type == 'item' or reward.type == 'weapon' or reward.type == 'account' or reward.type == 'car' then
		GrantItem(source, player, reward)
		return
	end

	local handler = Config.RewardHandlers and Config.RewardHandlers[reward.type]
	if handler and handler.grant then
		local ok, err = pcall(handler.grant, source, reward.amount or 0, reward)
		if not ok then
			print(('[tw_tebexstore]: RewardHandlers.grant failed for type "%s": %s'):format(reward.type, err))
		end
	else
		-- No handler defined — fire event so other resources can react.
		TriggerEvent('tw_tebexstore:customReward', source, reward.type, reward.amount, reward.label)
	end

	TriggerClientEvent('tw_tebexstore:notify', source, _T('reward_received', reward.label or reward.type))
end

-- Calls the revoke handler for each reward in the list and fires tw_tebexstore:revokeReward.
-- Built-in types (item/weapon/account/car) are intentionally NOT auto-revoked (too risky).
local function RevokeItemRewards(source, rewards, identifier)
	if not rewards or not source then return end
	for _, reward in pairs(rewards) do
		local handler = Config.RewardHandlers and Config.RewardHandlers[reward.type]
		if handler and handler.revoke then
			local ok, err = pcall(handler.revoke, source, reward.amount or 0, reward)
			if not ok then
				print(('[tw_tebexstore]: RewardHandlers.revoke failed for type "%s": %s'):format(reward.type, err))
			end
		end
		TriggerEvent('tw_tebexstore:revokeReward', source, reward.type, reward.amount, reward.label, identifier)
	end
end

local function GrantCustomRewards(source, player, rewards)
	if not rewards then return end
	for _, reward in pairs(rewards) do
		GrantCustomReward(source, player, reward)
		Wait(100)
	end
end

-- Best-effort integration: applied via the active inventory system when supported.
-- Outfit slots / free clothing shop have no standard cross-framework export —
-- they stay informational (Privileges) until wired to your own resource.
local function ApplyMaxWeight(source, tier)
	if not tier.MaxWeight then return end
	local ok, err
	if Inventory.IsOx then
		ok, err = pcall(function()
			exports.ox_inventory:SetMaxWeight(source, tier.MaxWeight)
		end)
	elseif Inventory.IsQS then
		-- qs-inventory does not expose a SetMaxWeight export; skip silently
		return
	elseif Inventory.IsCustom and Inventory.Custom.SetMaxWeight then
		ok, err = pcall(function()
			Inventory.Custom.SetMaxWeight(source, tier.MaxWeight)
		end)
	else
		return
	end
	if not ok then
		print('[tw_tebexstore]: Failed to apply MaxWeight for tier '..tier.id..': '..(err or ''))
	end
end

-- `key` is whatever Tebex sent us for a purchase: the numeric package ID (preferred, stable even if you
-- rename the package) or, for backwards compatibility with old codes already in the database, the package name.
local function FindTierByPackageKey(key)
	for _, tier in pairs(Config.Tiers) do
		if (tier.PackageId and tostring(tier.PackageId) == tostring(key)) or tier.PackageName == key then
			return tier
		end
	end
	return nil
end

local function FindTierById(id)
	for _, tier in pairs(Config.Tiers) do
		if tier.id == id then return tier end
	end
	return nil
end

local function LogTransaction(identifier, transactionId, packagename, label, kind)
	MySQL.insert('INSERT INTO tw_transaction_log (identifier, transaction_id, package_name, label, `type`, created_at) VALUES (?, ?, ?, ?, ?, NOW())',
		{identifier, transactionId, packagename, label, kind})
end

-- ============================================================
-- Subscription handling
-- ============================================================

local function ApplyTierRewards(source, player, tier)
	for _, item in pairs(tier.Items) do
		GrantItem(source, player, item)
		Wait(100)
	end
	Groups.Set(source, tier.Group)
	ApplyMaxWeight(source, tier)
end

local function GrantMilestone(source, player, tier, monthsActive, identifier, playerName)
	local milestones = Config.Milestones[tier.id]
	if not milestones or not milestones[monthsActive] then return end

	local already = MySQL.scalar.await('SELECT 1 FROM tw_milestones_claimed WHERE identifier = ? AND tier = ? AND `month` = ?', {identifier, tier.id, monthsActive})
	if already then return end

	for _, reward in pairs(milestones[monthsActive]) do
		if reward.type == 'physical' then
			MySQL.insert('INSERT INTO tw_physical_claims (identifier, player_name, tier, `month`, label, status, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
				{identifier, playerName, tier.id, monthsActive, reward.label, 'pending'})
			TriggerClientEvent('tw_tebexstore:notify', source, _T('physical_reward_unlocked', reward.label))
			LogEvent('Prémio Físico Desbloqueado', '**Jogador:** '..playerName..'\n**Tier:** '..tier.Label..'\n**Mês:** '..monthsActive..'\n**Prémio:** '..reward.label, 15844367)
		else
			GrantItem(source, player, reward)
			TriggerClientEvent('tw_tebexstore:notify', source, _T('loyalty_reward_unlocked', reward.label or reward.name or reward.model))
		end
		Wait(100)
	end

	MySQL.insert('INSERT INTO tw_milestones_claimed (identifier, tier, `month`, claimed_at) VALUES (?, ?, ?, NOW())', {identifier, tier.id, monthsActive})
end

-- Extends/creates the subscription for identifier+tier by one period, grants rewards, checks milestones.
local function ProcessSubscriptionRenewal(source, player, tier, transactionId)
	local identifier = GetIdentifier(player)
	local playerName = GetPlayerDisplayName(player, source)

	local existing = MySQL.single.await('SELECT * FROM tw_subscriptions WHERE identifier = ? AND tier = ?', {identifier, tier.id})

	local monthsActive
	local isFirstPurchase = not existing
	if existing then
		monthsActive = existing.months_active + 1
		MySQL.update('UPDATE tw_subscriptions SET months_active = ?, expires_at = DATE_ADD(GREATEST(expires_at, NOW()), INTERVAL ? DAY), status = ?, last_transaction = ? WHERE id = ?',
			{monthsActive, Config.SubscriptionDays, 'active', transactionId, existing.id})
	else
		monthsActive = 1
		MySQL.insert('INSERT INTO tw_subscriptions (identifier, tier, months_active, started_at, expires_at, status, last_transaction) VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY), ?, ?)',
			{identifier, tier.id, monthsActive, Config.SubscriptionDays, 'active', transactionId})
	end

	ApplyTierRewards(source, player, tier)
	GrantCustomRewards(source, player, isFirstPurchase and tier.FirstPurchaseRewards or tier.RenewalRewards)
	GrantMilestone(source, player, tier, monthsActive, identifier, playerName)
	LogTransaction(identifier, transactionId, tier.PackageName, tier.Label..' (Mês '..monthsActive..')', 'subscription')

	TriggerClientEvent('tw_tebexstore:notify', source, _T('subscription_renewed', tier.Label, monthsActive))
	LogEvent('Subscrição Renovada', '**Jogador:** '..playerName..'\n**Tier:** '..tier.Label..'\n**Mês:** '..monthsActive, 3066993)
end

-- `key` is the package ID or package name (see FindTierByPackageKey above). Returns the matched
-- package config (with a .Label to display) or nil.
local function FindPackageByKey(key)
	for _, pack in pairs(Config.Packages) do
		if (pack.PackageId and tostring(pack.PackageId) == tostring(key)) or pack.PackageName == key then
			return pack
		end
	end
	return nil
end

local function GrantLegacyPackage(source, player, pack)
	for _, item in pairs(pack.Items) do
		GrantCustomReward(source, player, item)
		Wait(100)
	end
	return true
end

local activeRedemptions = {}
-- Kept well above realistic granting time so the safety net can never release a lock while a
-- redemption is still handing out rewards, which would re-open the duplication window.
local REDEMPTION_LOCK_TIMEOUT = 60000

-- Redeems a Tebex transaction code for `source`. Used both by /redeem and the store UI modal.
local function RedeemTransaction(source, encode, cb)
	-- The /redeem command guards this, but the NUI callback passes `code` straight through, so a
	-- nil/empty value would blow up on `activeRedemptions[encode] = lock` ("table index is nil").
	if not encode or encode == '' then
		if cb then cb(false, _T('invalid_code')) end
		return
	end

	local player = GetPlayer(source)
	if not player then
		print(('^1[tw_tebexstore]: Redeem falhou (jogador inválido) | source: %s | código: %s^0'):format(source, encode))
		if cb then cb(false, "Jogador inválido.") end
		return
	end
	local playerName = GetPlayerDisplayName(player, source)

	if activeRedemptions[encode] then
		local msg = _T('redemption_in_progress')
		print(('^1[tw_tebexstore]: Redeem falhou (código já em processamento) | jogador: %s | source: %s | código: %s^0'):format(playerName, source, encode))
		TriggerClientEvent('tw_tebexstore:notify', source, msg)
		if cb then cb(false, msg) end
		return
	end

	-- `lock` identifies this attempt so the timeout below never releases a lock taken by a later one.
	local lock = {}
	activeRedemptions[encode] = lock

	local function Release()
		if activeRedemptions[encode] == lock then
			activeRedemptions[encode] = nil
		end
	end

	-- Safety net in case the query callback never fires (dropped DB connection, resource error).
	SetTimeout(REDEMPTION_LOCK_TIMEOUT, function()
		if activeRedemptions[encode] == lock then
			print(('^3[tw_tebexstore]: Lock expirado, libertado | código: %s^0'):format(encode))
			activeRedemptions[encode] = nil
		end
	end)

	MySQL.query('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
		if not result[1] then
			Release()
			local msg = _T('invalid_code')
			print(('^1[tw_tebexstore]: Redeem falhou (código inválido) | jogador: %s | source: %s | código: %s^0'):format(playerName, source, encode))
			TriggerClientEvent('tw_tebexstore:notify', source, msg)
			if cb then cb(false, msg) end
			return
		end

		local packs = json.decode(result[1].packagename)
		local redeemedAny = false

		-- Rewards run inside pcall so a failure releases the lock and leaves the code in the database
		-- for a retry, instead of the player paying and losing it.
		local ok, err = pcall(function()
			for _, packageKey in pairs(packs) do
				local tier = FindTierByPackageKey(packageKey)
				local pack = not tier and FindPackageByKey(packageKey) or nil
				if tier then
					ProcessSubscriptionRenewal(source, player, tier, encode)
					redeemedAny = true
				elseif pack then
					GrantLegacyPackage(source, player, pack)
					TriggerClientEvent('tw_tebexstore:notify', source, _T('package_redeemed', pack.PackageName))
					LogEvent('Código Resgatado', '**Pacote: **'..pack.PackageName..'\n**Jogador: **'..playerName, 3066993)
					LogTransaction(GetIdentifier(player), encode, pack.PackageName, pack.PackageName, 'package')
					redeemedAny = true
				else
					TriggerClientEvent('tw_tebexstore:notify', source, _T('package_not_configured', packageKey))
				end
			end
		end)

		if not ok then
			Release()
			print(('^1[tw_tebexstore]: Redeem falhou (erro ao entregar prémios) | jogador: %s | source: %s | código: %s | erro: %s^0'):format(playerName, source, encode, tostring(err)))
			LogEvent('Erro no Resgate', '**Jogador: **'..playerName..'\n**Código: **'..encode..'\n**Erro: **'..tostring(err), 15158332)
			if cb then cb(false, "Erro ao processar a transação. Tenta novamente.") end
			return
		end

		if redeemedAny then
			MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode})
			print(('^2[tw_tebexstore]: Redeem com sucesso | jogador: %s | source: %s | código: %s^0'):format(playerName, source, encode))
		else
			print(('^1[tw_tebexstore]: Redeem falhou (nenhum pacote válido) | jogador: %s | source: %s | código: %s^0'):format(playerName, source, encode))
		end

		Release()

		if cb then cb(redeemedAny, redeemedAny and _T('transaction_success') or _T('no_valid_packages')) end
	end)
end

RegisterCommand('redeem', function(source, args)
	local encode = args[1]
	if not encode or encode == '' then return end
	RedeemTransaction(source, encode)
end, false)

if Framework.IsESX then
	ESX.RegisterServerCallback('tw_tebexstore:redeemTransaction', function(source, cb, code)
		RedeemTransaction(source, code, cb)
	end)
elseif Framework.IsQB then
	QBCore.Functions.CreateCallback('tw_tebexstore:redeemTransaction', function(source, cb, code)
		RedeemTransaction(source, code, cb)
	end)
end

-- ============================================================
-- Store UI data (/loja)
-- ============================================================

local function BuildStoreData(source)
	local player = GetPlayer(source)
	if not player then return nil end
	local identifier = GetIdentifier(player)

	local subs = MySQL.query.await('SELECT * FROM tw_subscriptions WHERE identifier = ? AND status = ?', {identifier, 'active'}) or {}
	local claimedRows = MySQL.query.await('SELECT tier, `month` FROM tw_milestones_claimed WHERE identifier = ?', {identifier}) or {}

	local claimed = {}
	for _, row in pairs(claimedRows) do
		claimed[row.tier] = claimed[row.tier] or {}
		claimed[row.tier][row.month] = true
	end

	local activeTiers = {}
	for _, sub in pairs(subs) do
		local tier = FindTierById(sub.tier)
		if tier then
			local wasFirstPurchase = sub.months_active == 1
			activeTiers[#activeTiers+1] = {
				id = tier.id,
				label = tier.Label,
				group = tier.Group,
				items = wasFirstPurchase and tier.FirstPurchaseRewards or tier.RenewalRewards,
				isFirstPurchase = wasFirstPurchase,
				nextRenewalRewards = tier.RenewalRewards,
				privileges = tier.Privileges,
				monthsActive = sub.months_active,
				startedAt = sub.started_at,
				expiresAt = sub.expires_at,
				milestones = Config.Milestones[tier.id] or {},
				claimedMilestones = claimed[tier.id] or {},
			}
		end
	end

	local allTiers = {}
	for _, tier in pairs(Config.Tiers) do
		allTiers[#allTiers+1] = {
			id = tier.id,
			Label = tier.Label,
			Privileges = tier.Privileges,
			Items = tier.Items,
			Milestones = Config.Milestones[tier.id] or {},
			ClaimedMilestones = claimed[tier.id] or {},
		}
	end

	local history = MySQL.query.await('SELECT * FROM tw_transaction_log WHERE identifier = ? ORDER BY created_at DESC LIMIT 50', {identifier}) or {}

	local useOxImages = Config.UseOxInventoryImages
	if useOxImages == "auto" or useOxImages == nil then
		useOxImages = Inventory.IsOx
	end

	local uiStrings = {
		ui_date_locale          = _T('ui_date_locale'),
		ui_tab_overview         = _T('ui_tab_overview'),
		ui_tab_history          = _T('ui_tab_history'),
		ui_hero_title           = _T('ui_hero_title'),
		ui_hero_desc            = _T('ui_hero_desc'),
		ui_hero_redeem_btn      = _T('ui_hero_redeem_btn'),
		ui_redeem_title         = _T('ui_redeem_title'),
		ui_redeem_hint          = _T('ui_redeem_hint'),
		ui_redeem_btn           = _T('ui_redeem_btn'),
		ui_redeem_loading       = _T('ui_redeem_loading'),
		ui_subs_title           = _T('ui_subs_title'),
		ui_subs_month_one       = _T('ui_subs_month_one'),
		ui_subs_month_many      = _T('ui_subs_month_many'),
		ui_subs_active_until    = _T('ui_subs_active_until'),
		ui_subs_progress        = _T('ui_subs_progress'),
		ui_subs_progress_done   = _T('ui_subs_progress_done'),
		ui_subs_progress_month  = _T('ui_subs_progress_month'),
		ui_subs_first_purchase  = _T('ui_subs_first_purchase'),
		ui_subs_renewal         = _T('ui_subs_renewal'),
		ui_subs_next_renewal    = _T('ui_subs_next_renewal'),
		ui_subs_next_renewal_days = _T('ui_subs_next_renewal_days'),
		ui_subs_privileges      = _T('ui_subs_privileges'),
		ui_subs_empty           = _T('ui_subs_empty'),
		ui_subs_empty_hint      = _T('ui_subs_empty_hint'),
		ui_miles_title          = _T('ui_miles_title'),
		ui_miles_desc           = _T('ui_miles_desc'),
		ui_miles_month          = _T('ui_miles_month'),
		ui_miles_unlocked       = _T('ui_miles_unlocked'),
		ui_miles_locked         = _T('ui_miles_locked'),
		ui_miles_physical       = _T('ui_miles_physical'),
		ui_miles_physical_default = _T('ui_miles_physical_default'),
		ui_miles_delivered      = _T('ui_miles_delivered'),
		ui_history_title        = _T('ui_history_title'),
		ui_history_desc         = _T('ui_history_desc'),
		ui_history_vip          = _T('ui_history_vip'),
		ui_history_package      = _T('ui_history_package'),
		ui_history_empty        = _T('ui_history_empty'),
		ui_history_empty_hint   = _T('ui_history_empty_hint'),
		ui_scroll_prev          = _T('ui_scroll_prev'),
		ui_scroll_next          = _T('ui_scroll_next'),
	}

	return {
		activeTiers = activeTiers,
		allTiers = allTiers,
		transactionHistory = history,
		useOxImages = useOxImages,
		uiColors = Config.UIColors,
		uiStrings = uiStrings,
		uiLogo = Config.UILogo or "",
		uiHeroBanner = Config.UIHeroBanner or "",
	}
end

if Framework.IsESX then
	ESX.RegisterServerCallback('tw_tebexstore:getStoreData', function(source, cb)
		cb(BuildStoreData(source))
	end)
elseif Framework.IsQB then
	QBCore.Functions.CreateCallback('tw_tebexstore:getStoreData', function(source, cb)
		cb(BuildStoreData(source))
	end)
end

-- ============================================================
-- Expiry sweep
-- ============================================================

local function GetSourceByIdentifier(identifier)
	for _, playerId in ipairs(GetPlayers()) do
		for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
			if id == identifier then return tonumber(playerId) end
		end
	end
	return nil
end

CreateThread(function()
	while true do
		Wait(Config.ExpiryCheckInterval * 60 * 1000)
		local expired = MySQL.query.await("SELECT * FROM tw_subscriptions WHERE status = 'active' AND expires_at < NOW()") or {}
		for _, sub in pairs(expired) do
			MySQL.update('UPDATE tw_subscriptions SET status = ? WHERE id = ?', {'expired', sub.id})
			local playerSource = GetSourceByIdentifier(sub.identifier)
			if playerSource then
				local tier = FindTierById(sub.tier)
				if tier then
					Groups.Revoke(playerSource, tier.Group)
					TriggerClientEvent('tw_tebexstore:notify', playerSource, _T('subscription_expired', tier.Label))
				end
			end
			LogEvent('Subscrição Expirada', '**Identifier:** '..sub.identifier..'\n**Tier:** '..sub.tier, 15158332)
		end
	end
end)

RegisterCommand('purchase_package_tebex', function(source, args)
	if source == 0 then
		local dec = json.decode(args[1])
		local tbxid = dec.transid
		-- Prefer the numeric package ID (stable, doesn't break if you rename the package on Tebex).
		-- Falls back to the package name if your GSM command only sends {packageName}.
		local packageKey = dec.packageid or dec.packagename
		local packTab = {}
		while inProgress do
			if GetGameTimer() - inProgressSince > 30000 then
				print('^3[tw_tebexstore]: inProgress lock timed out — resetting^0')
				inProgress = false
				break
			end
			Wait(1000)
		end
		inProgress = true
		inProgressSince = GetGameTimer()
		MySQL.query('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = tbxid}, function(result)
			if result[1] then
				local packagetable = json.decode(result[1].packagename)
				packagetable[#packagetable+1] = packageKey
				MySQL.update('UPDATE codes SET packagename = ? WHERE code = ?', {json.encode(packagetable), tbxid}, function(rowsChanged)
					if rowsChanged > 0 then
						LogEvent('Purchase', '`'..packageKey..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
					else
						LogEvent('Error', '`'..tbxid..'` was not inserted into database. Please check for errors!', 15158332)
					end
				end)
			else
				packTab[#packTab+1] = packageKey
				MySQL.insert("INSERT INTO codes (code, packagename) VALUES (?, ?)", {tbxid, json.encode(packTab)}, function(rowsChanged)
					LogEvent('Purchase', '`'..packageKey..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
					print('^2Purchase '..tbxid..' was succesfully inserted into the database.^0')
				end)
			end
			inProgress = false
		end)
	else
		print(GetPlayerName(source)..' tried to give themself a donation code.')
		LogEvent('Attempted Exploit', GetPlayerName(source)..' tried to give themself a donation code!', 15158332)
	end
end, false)

-- ============================================================
-- Refunds / chargebacks / removals
-- ============================================================
-- Bind this SAME command to Tebex's "When the package is removed", "When the package is refunded"
-- and "When the package is chargebacked" triggers, one `reason` per trigger, e.g.:
--   revoke_package_tebex {"transid":"{transaction}", "packageid":{packageId}, "reason":"refunded"}
--   revoke_package_tebex {"transid":"{transaction}", "packageid":{packageId}, "reason":"chargeback"}
--   revoke_package_tebex {"transid":"{transaction}", "packageid":{packageId}, "reason":"removed"}
--
-- Only VIP tier subscriptions are revoked automatically (subscription marked "cancelled" + group taken
-- away if the player is online right now). Items/money/vehicles already granted by a one-off package are
-- NOT clawed back automatically (too invasive/framework-inconsistent to reverse safely) — those get
-- reported to Discord for the staff to review manually instead.
RegisterCommand('revoke_package_tebex', function(source, args)
	if source ~= 0 then
		print(GetPlayerName(source)..' tried to trigger a revoke.')
		LogEvent('Attempted Exploit', GetPlayerName(source)..' tried to trigger revoke_package_tebex!', 15158332)
		return
	end

	local dec = json.decode(args[1])
	local tbxid = dec.transid
	local packageKey = dec.packageid or dec.packagename
	local reason = dec.reason or 'unknown'

	while inProgress do
		if GetGameTimer() - inProgressSince > 30000 then
			print('^3[tw_tebexstore]: inProgress lock timed out — resetting^0')
			inProgress = false
			break
		end
		Wait(1000)
	end
	inProgress = true
	inProgressSince = GetGameTimer()

	-- If the code hasn't been redeemed yet, just strip this package out of the pending code so it
	-- can no longer be claimed.
	local codeRow = MySQL.single.await('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = tbxid})
	if codeRow then
		local packagetable = json.decode(codeRow.packagename)
		local remaining = {}
		for _, key in pairs(packagetable) do
			if tostring(key) ~= tostring(packageKey) then remaining[#remaining+1] = key end
		end
		if #remaining > 0 then
			MySQL.update('UPDATE codes SET packagename = ? WHERE code = ?', {json.encode(remaining), tbxid})
		else
			MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = tbxid})
		end
	end
	inProgress = false

	-- Find who (if anyone) already redeemed this transaction.
	local logRow = MySQL.single.await('SELECT * FROM tw_transaction_log WHERE transaction_id = ? ORDER BY id DESC LIMIT 1', {tbxid})
	if not logRow then
		LogEvent('Purchase Reversed (' ..reason.. ')', '`'..packageKey..'` (transação `'..tbxid..'`) foi revertido, mas ainda ninguém o tinha resgatado. Código removido.', 15158332)
		return
	end

	local identifier = logRow.identifier
	local tier = FindTierByPackageKey(packageKey)

	if tier then
		local existing = MySQL.single.await('SELECT * FROM tw_subscriptions WHERE identifier = ? AND tier = ?', {identifier, tier.id})
		if existing and existing.status == 'active' then
			MySQL.update('UPDATE tw_subscriptions SET status = ? WHERE id = ?', {'cancelled', existing.id})

			local onlineSource, onlinePlayer = GetOnlinePlayerByIdentifier(identifier)
			if onlineSource then
				Groups.Revoke(onlineSource, tier.Group)
				RevokeItemRewards(onlineSource, tier.Items, identifier)
				TriggerEvent('tw_tebexstore:revokeSubscription', onlineSource, identifier, tier.id, reason)
				TriggerClientEvent('tw_tebexstore:notify', onlineSource, _T('subscription_cancelled', tier.Label, reason))
			else
				-- Player is offline — fire revoke event with source = -1 so listeners can queue it.
				TriggerEvent('tw_tebexstore:revokeSubscription', -1, identifier, tier.id, reason)
			end

			LogEvent('Subscrição Cancelada (' ..reason.. ')', '**Identifier:** '..identifier..'\n**Tier:** '..tier.Label..'\n**Transação:** '..tbxid, 15158332)
		else
			LogEvent('Purchase Reversed (' ..reason.. ')', '`'..packageKey..'` (transação `'..tbxid..'`) revertido para **'..identifier..'**, mas não havia subscrição ativa desse tier para cancelar.', 15158332)
		end
	else
		-- One-off package revoke: call handlers for custom types, fire event for built-in ones.
		local revokedPack = FindPackageByKey(packageKey)
		if revokedPack then
			local pkgSource, _ = GetOnlinePlayerByIdentifier(identifier)
			if pkgSource then
				RevokeItemRewards(pkgSource, revokedPack.Items, identifier)
			end
			TriggerEvent('tw_tebexstore:revokePackage', pkgSource or -1, identifier, revokedPack.PackageName, reason)
		end
		LogEvent('Purchase Reversed (' ..reason.. ') — Manual Review Required',
			'**Identifier:** '..identifier..'\n**Package:** '..packageKey..'\n**Transaction:** '..tbxid..
			'\nBuilt-in rewards (items/money/vehicles) are NOT auto-revoked — review manually if needed.', 15158332)
	end
end, false)


-- ============================================================
-- Staff: physical reward fulfillment
-- ============================================================

local function IsAdmin(source)
	if source == 0 then return true end
	if Framework.IsESX then
		local xPlayer = ESX.GetPlayerFromId(source)
		return xPlayer and (xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin')
	elseif Framework.IsQB then
		return QBCore.Functions.HasPermission(source, 'admin')
	end
	return false
end

RegisterCommand('lojapendentes', function(source)
	if not IsAdmin(source) then return end
	local pending = MySQL.query.await("SELECT * FROM tw_physical_claims WHERE status = 'pending' ORDER BY created_at ASC") or {}
	if #pending == 0 then
		TriggerClientEvent('tw_tebexstore:notify', source, _T('no_pending_physical'))
		return
	end
	for _, claim in pairs(pending) do
		print(('[tw_tebexstore] #%d | %s | %s | Tier: %s | Mês: %d | %s'):format(claim.id, claim.player_name or claim.identifier, claim.label, claim.tier, claim.month, claim.identifier))
	end
	TriggerClientEvent('tw_tebexstore:notify', source, _T('pending_physical_count', #pending))
end, false)

RegisterCommand('lojaenviado', function(source, args)
	if not IsAdmin(source) then return end
	local id = tonumber(args[1])
	if not id then
		TriggerClientEvent('tw_tebexstore:notify', source, _T('usage_shipped'))
		return
	end
	MySQL.update('UPDATE tw_physical_claims SET status = ? WHERE id = ?', {'shipped', id})
	TriggerClientEvent('tw_tebexstore:notify', source, _T('physical_marked_shipped', id))
end, false)
