-- ============================================================
-- Garage bridge (jg-advancedgarages / cd_garage / default)
-- ============================================================
-- Auto-detects the active garage resource and exposes a unified
-- Garage.StoreVehicle(identifier, model, plate, garageName) function
-- (server-side only) so car rewards work regardless of the garage system.
--
-- Supported:
--   "jg"      -> jg-advancedgarages  (jg_garages_vehicles)
--   "cd"      -> cd_garage            (cd_garage_vehicles)
--   "op"      -> op_garage/opgarages  (framework tables + `vehicleGarage`)
--   "default" -> framework tables     (owned_vehicles / player_vehicles)
--
-- To force a specific system set Config.GarageSystem in config.lua,
-- e.g.: Config.GarageSystem = "jg"
--
-- NOTE (op): op_garage keeps vehicles in the framework's own tables
-- (owned_vehicles / player_vehicles) and identifies the garage with the
-- INTEGER column `vehicleGarage` (an Index from opgarages_garages2 /
-- opgarages_ownedgarages). For this system Config.CarRewardGarage must be a
-- number, e.g. Config.CarRewardGarage = 1.

Garage = {}

local function ResolveGarageName()
	local forced = Config.GarageSystem and Config.GarageSystem:lower() or "auto"
	if forced ~= "auto" then return forced end

	if GetResourceState('jg-advancedgarages') == 'started' then return 'jg' end
	if GetResourceState('cd_garage')            == 'started' then return 'cd' end
	if GetResourceState('op_garage')          == 'started' then return 'op' end
	if GetResourceState('op-garages')         == 'started' then return 'op' end
	if GetResourceState('opgarages')          == 'started' then return 'op' end
	return 'default'
end

Garage.Name = ResolveGarageName()

-- ============================================================
-- Server-only: plate query + StoreVehicle
-- ============================================================
if not IsDuplicityVersion() then return end

-- Which table to check so GeneratePlate() avoids duplicate plates.
-- server.lua reads this into plateQuery after this file loads.
if Garage.Name == 'jg' then
	Garage.PlateQuery = 'SELECT 1 FROM jg_garages_vehicles WHERE plate = ?'
elseif Garage.Name == 'cd' then
	Garage.PlateQuery = 'SELECT 1 FROM cd_garage_vehicles WHERE plate = ?'
elseif Framework.IsESX then
	Garage.PlateQuery = 'SELECT 1 FROM owned_vehicles WHERE plate = ?'
elseif Framework.IsQB then
	Garage.PlateQuery = 'SELECT 1 FROM player_vehicles WHERE plate = ?'
end

local function BuildProps(model, plate)
	return json.encode({
		model          = GetHashKey(model),
		plate          = plate,
		plateIndex     = 0,
		bodyHealth     = 1000.0,
		engineHealth   = 1000.0,
		tankHealth     = 1000.0,
		fuelLevel      = 100.0,
		dirtLevel      = 0.0,
		color1         = 0,
		color2         = 0,
		pearlescentColor = 0,
		wheelColor     = 156,
		wheels         = 0,
		windowTint     = 0,
		neonEnabled    = {false, false, false, false},
		extras         = {},
		tyreSmokeColor = {r = 255, g = 255, b = 255},
	})
end

-- Inserts `model` with `plate` into the garage system for `identifier`.
-- `garageName` must be a valid garage ID in your garage config (e.g. "legion").
function Garage.StoreVehicle(identifier, model, plate, garageName)
	local props = BuildProps(model, plate)

	if Garage.Name == 'jg' then
		MySQL.insert(
			'INSERT INTO jg_garages_vehicles (plate, model, stored, owner, props, fuel, engine, body) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
			{ plate, model, garageName, identifier, props, 100, 1000.0, 1000.0 }
		)

	elseif Garage.Name == 'cd' then
		MySQL.insert(
			'INSERT INTO cd_garage_vehicles (plate, model, garage, identifier, vehicle_props, fuel, engine, body_health) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
			{ plate, model, garageName, identifier, props, 100, 1000.0, 1000.0 }
		)

	elseif Garage.Name == 'op' then
		-- op_garage stores vehicles in the framework's own tables and identifies
		-- the garage with the INTEGER column `vehicleGarage`. state = 1 => stored.
		local garageIndex = tonumber(garageName) or 1
		if Framework.IsESX then
			-- ESX owned_vehicles: the `vehicle` column IS the props JSON.
			MySQL.insert(
				'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, vehicleGarage) VALUES (?, ?, ?, ?, ?, ?)',
				{ identifier, plate, props, 'car', 1, garageIndex }
			)
		elseif Framework.IsQB then
			-- QB player_vehicles: `vehicle` is the model NAME, `hash` the model
			-- hash, and `mods` the props JSON (what op_garage reads to spawn).
			MySQL.insert(
				'INSERT INTO player_vehicles (citizenid, plate, vehicle, hash, mods, state, vehicleGarage) VALUES (?, ?, ?, ?, ?, ?, ?)',
				{ identifier, plate, model, GetHashKey(model), props, 1, garageIndex }
			)
		else
			print('^1[tw_tebexstore]: op_garage requires ESX or QB framework. Vehicle not saved!^0')
		end

	else -- default: framework own tables
		if Framework.IsESX then
			MySQL.insert(
				'INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (?, ?, ?, ?)',
				{ identifier, plate, props, 1 }
			)
		elseif Framework.IsQB then
			MySQL.insert(
				'INSERT INTO player_vehicles (citizenid, plate, vehicle, state) VALUES (?, ?, ?, ?)',
				{ identifier, plate, props, 1 }
			)
		else
			print('^1[tw_tebexstore]: Garage.StoreVehicle — no supported garage or framework detected. Vehicle not saved!^0')
		end
	end
end
