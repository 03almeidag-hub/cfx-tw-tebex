-- ============================================================
-- Inventory bridge (ox_inventory / qs-inventory / custom / native)
-- ============================================================
-- Auto-detects the active inventory system so item/weapon rewards and the
-- MaxWeight perk go through the right API regardless of what is installed.
--
--   Inventory.Name     -> "ox" | "qs" | "custom" | "native"
--   Inventory.IsOx     -> ox_inventory running (weapons = items + ammo metadata)
--   Inventory.IsQS     -> qs-inventory running (same weapon model as ox)
--   Inventory.IsCustom -> Config.InventorySystem = "custom" (see below)
--   Inventory.IsNative -> fallback: ESX/QB framework calls
--
-- To force a specific system set Config.InventorySystem in config.lua.

Inventory = {}

local function ResolveInventoryName()
	local forced = Config.InventorySystem and Config.InventorySystem:lower() or "auto"
	if forced ~= "auto" then return forced end

	if GetResourceState('ox_inventory') == 'started' then return 'ox' end
	if GetResourceState('qs-inventory') == 'started' then return 'qs' end
	return 'native'
end

Inventory.Name     = ResolveInventoryName()
Inventory.IsOx     = Inventory.Name == 'ox'
Inventory.IsQS     = Inventory.Name == 'qs'
Inventory.IsCustom = Inventory.Name == 'custom'
Inventory.IsNative = Inventory.Name == 'native'

-- ============================================================
-- Custom inventory callbacks
-- ============================================================
-- Edit these functions when Config.InventorySystem = "custom".
-- All callbacks run server-side only.
--
-- AddItem    (source, name, amount)   -> grant a regular item
-- AddWeapon  (source, name, ammo)     -> grant a weapon (ammo = bullet count)
-- SetMaxWeight (source, weight)       -> apply tier weight perk (nil = unsupported)

Inventory.Custom = {
	AddItem = function(source, name, amount)
		-- exports['my-inventory']:AddItem(source, name, amount)
	end,

	AddWeapon = function(source, name, ammo)
		-- exports['my-inventory']:AddItem(source, name, 1, nil, {ammo = ammo})
	end,

	SetMaxWeight = function(source, weight)
		-- exports['my-inventory']:SetMaxWeight(source, weight)
	end,
}
