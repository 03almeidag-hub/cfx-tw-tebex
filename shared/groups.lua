-- ============================================================
-- Groups / Permission system (built-in, no framework dependency)
-- ============================================================
-- Stores permissions in tw_permissions (DB) and keeps an in-memory
-- cache per player. Completely independent of ESX/QB group APIs.
--
-- Public API (server-side):
--   Groups.Set(source, group)        -> assign group
--   Groups.Revoke(source, group)     -> remove group
--   Groups.Has(source, group)        -> boolean
--   Groups.GetAll(source)            -> table of group strings
--
-- Exports (callable from any other resource):
--   exports['tw_tebexstore']:SetGroup(source, group)
--   exports['tw_tebexstore']:RevokeGroup(source, group)
--   exports['tw_tebexstore']:HasGroup(source, group)
--   exports['tw_tebexstore']:GetPlayerGroups(source)
--
-- Events fired on change (for other resources to react):
--   tw_tebexstore:groupSet(source, identifier, group)
--   tw_tebexstore:groupRevoked(source, identifier, group)
--
-- Hooks (optional, edit Groups.Custom below):
--   Groups.Custom.OnSet(source, identifier, group)
--   Groups.Custom.OnRevoke(source, identifier, group)

Groups = {}

if not IsDuplicityVersion() then return end

-- ============================================================
-- Optional hooks — edit to notify other systems on changes
-- ============================================================

Groups.Custom = {
	OnSet    = nil, -- function(source, identifier, group) end
	OnRevoke = nil, -- function(source, identifier, group) end
}

-- ============================================================
-- Internal
-- ============================================================

-- cache[identifier] = { groupName = true, ... }
local cache = {}

local function GetLicense(source)
	for _, id in ipairs(GetPlayerIdentifiers(source) or {}) do
		if id:sub(1, 8) == 'license:' then return id end
	end
	-- fallback to first available identifier
	local ids = GetPlayerIdentifiers(source) or {}
	return ids[1]
end

local function LoadGroups(source)
	local identifier = GetLicense(source)
	if not identifier then return end
	cache[identifier] = {}
	local rows = MySQL.query.await(
		'SELECT `group` FROM tw_permissions WHERE identifier = ? AND (expires_at IS NULL OR expires_at > NOW())',
		{ identifier }
	) or {}
	for _, row in ipairs(rows) do
		cache[identifier][row['group']] = true
	end
end

AddEventHandler('playerJoining', function()
	local src = source
	SetTimeout(100, function() LoadGroups(src) end)
end)

AddEventHandler('playerDropped', function()
	local identifier = GetLicense(source)
	if identifier then cache[identifier] = nil end
end)

-- ============================================================
-- Public API
-- ============================================================

function Groups.Set(source, group)
	if not source or not group then return end
	local identifier = GetLicense(source)
	if not identifier then return end

	cache[identifier] = cache[identifier] or {}
	cache[identifier][group] = true

	MySQL.insert(
		'INSERT INTO tw_permissions (identifier, `group`, granted_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE granted_at = NOW()',
		{ identifier, group }
	)

	TriggerEvent('tw_tebexstore:groupSet', source, identifier, group)
	if Groups.Custom.OnSet then Groups.Custom.OnSet(source, identifier, group) end
end

function Groups.Revoke(source, group)
	if not source or not group then return end
	local identifier = GetLicense(source)
	if not identifier then return end

	if cache[identifier] then cache[identifier][group] = nil end

	MySQL.query('DELETE FROM tw_permissions WHERE identifier = ? AND `group` = ?', { identifier, group })

	TriggerEvent('tw_tebexstore:groupRevoked', source, identifier, group)
	if Groups.Custom.OnRevoke then Groups.Custom.OnRevoke(source, identifier, group) end
end

function Groups.Has(source, group)
	if not source or not group then return false end
	local identifier = GetLicense(source)
	if not identifier then return false end
	if not cache[identifier] then LoadGroups(source) end
	return cache[identifier] and cache[identifier][group] == true or false
end

function Groups.GetAll(source)
	if not source then return {} end
	local identifier = GetLicense(source)
	if not identifier then return {} end
	if not cache[identifier] then LoadGroups(source) end
	local result = {}
	for g in pairs(cache[identifier] or {}) do
		result[#result + 1] = g
	end
	return result
end

-- ============================================================
-- Exports
-- ============================================================

exports('SetGroup',        function(src, group) Groups.Set(src, group)          end)
exports('RevokeGroup',     function(src, group) Groups.Revoke(src, group)       end)
exports('HasGroup',        function(src, group) return Groups.Has(src, group)   end)
exports('GetPlayerGroups', function(src)        return Groups.GetAll(src)        end)
