-- ============================================================
-- Version checker
-- ============================================================

local CURRENT_VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or 'unknown'
local VERSION_URL     = 'https://raw.githubusercontent.com/03almeidag-hub/cfx-tw-tebex/main/version.txt'
local REPO_URL        = 'https://github.com/03almeidag-hub/cfx-tw-tebex'

local latestVersion  = nil
local latestUpdates  = {}
local updateAvailable = false

local function ParseVersionFile(content)
	local version, updates = nil, {}
	local parsingUpdates = false

	for line in (content .. '\n'):gmatch('([^\r\n]*)\r?\n') do
		local trimmed = line:match('^%s*(.-)%s*$')

		if trimmed:match('^Version:%s*') then
			if version then break end -- second block reached, stop
			version = trimmed:match('^Version:%s*(.+)')

		elseif trimmed == 'Updates:' then
			parsingUpdates = true

		elseif parsingUpdates and trimmed:match('^%- ') then
			updates[#updates + 1] = trimmed
		end
	end

	return version, updates
end

local function CheckVersion()
	PerformHttpRequest(VERSION_URL, function(status, body)
		if status ~= 200 or not body or body == '' then
			print('^3[tw_tebexstore] Não foi possível verificar atualizações (HTTP ' .. tostring(status) .. ')^0')
			return
		end

		latestVersion, latestUpdates = ParseVersionFile(body)
		if not latestVersion then
			print('^3[tw_tebexstore] Formato do version.txt inválido.^0')
			return
		end

		updateAvailable = latestVersion ~= CURRENT_VERSION

		print('')
		print('^5╔════════════════════════════════════╗^0')
		print('^5║         TW-TebexStore              ║^0')
		print('^5╚════════════════════════════════════╝^0')
		print('^2 Version: ' .. CURRENT_VERSION .. '^0')

		if updateAvailable then
			print('^3 ⚠  Atualização disponível: ' .. latestVersion .. '^0')
			print('^3 Updates:^0')
			for _, u in ipairs(latestUpdates) do
				print('^3   ' .. u .. '^0')
			end
			print('^3 Download: ' .. REPO_URL .. '^0')
		else
			print('^2 ✔  Versão atualizada!^0')
		end

		print('')
	end, 'GET', '', {})
end

-- ============================================================
-- Startup
-- ============================================================

AddEventHandler('onResourceStart', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	-- small delay so MySQL / other resources are ready
	SetTimeout(2000, CheckVersion)
end)

-- ============================================================
-- Notify admins in chat on join
-- ============================================================

local function IsAdmin(source)
	return Groups.Has(source, 'admin')
		or Groups.Has(source, 'superadmin')
		or IsPlayerAceAllowed(source, 'command')
end

AddEventHandler('playerJoining', function()
	if not updateAvailable then return end
	local src = source

	-- wait for client to be in-game before sending chat
	SetTimeout(8000, function()
		if not GetPlayerName(src) then return end
		if not IsAdmin(src) then return end

		TriggerClientEvent('chat:addMessage', src, {
			color     = {255, 165, 0},
			multiline = true,
			args      = { '[tw_tebexstore]', _T('update_available_chat', latestVersion, REPO_URL) },
		})
	end)
end)
