-- ============================================================
-- Framework bridge (ESX / QBCore / QBox)
-- ============================================================
-- Auto-detects the running framework unless Config.Framework forces one
-- (see shared/config.lua). Exposes a normalized `Framework` table used by
-- client/client.lua and server/server.lua:
--   Framework.Name        -> "esx" | "qb" | "qbx"
--   Framework.Core         -> the ESX shared object, or a QBCore-compatible object
--   Framework.IsESX         -> true when running on ESX
--   Framework.IsQB          -> true for BOTH qb-core and QBox (Qbox ships a
--                              QBCore-compatible core object, so QB.Functions.*
--                              calls work unmodified against it)
--   Framework.IsQBX          -> true only for QBox, in case Qbox-specific
--                              behaviour is ever needed on top of the shared QB path

Framework = {}

local function ResolveFrameworkName()
	local forced = Config.Framework and Config.Framework:lower() or "auto"
	if forced == "qbox" then forced = "qbx" end
	if forced ~= "auto" then return forced end

	if GetResourceState('es_extended') == 'started' then return 'esx' end
	-- Must be checked before 'qb-core': Qbox's qbx_core resource `provide`s the
	-- 'qb-core' name for backwards compatibility, so GetResourceState('qb-core')
	-- would also report 'started' while qbx_core is running.
	if GetResourceState('qbx_core') == 'started' then return 'qbx' end
	if GetResourceState('qb-core') == 'started' then return 'qb' end
	return nil
end

Framework.Name = ResolveFrameworkName()
Framework.IsESX = Framework.Name == 'esx'
Framework.IsQBX = Framework.Name == 'qbx'
Framework.IsQB = Framework.Name == 'qb' or Framework.Name == 'qbx'

if Framework.IsESX then
	Framework.Core = exports.es_extended:getSharedObject()
elseif Framework.Name == 'qbx' then
	-- Prefer QBox's native export; fall back to the 'qb-core' name it provides
	-- for unmodified legacy QBCore scripts (same QBCore.Functions.* API either way).
	local ok, core = pcall(function() return exports.qbx_core:GetCoreObject() end)
	Framework.Core = ok and core or exports['qb-core']:GetCoreObject()
elseif Framework.Name == 'qb' then
	Framework.Core = exports['qb-core']:GetCoreObject()
else
	print('^1[tw_tebexstore]: Could not detect a supported framework (ESX / QBCore / QBox). Set Config.Framework manually in shared/config.lua.^0')
end
