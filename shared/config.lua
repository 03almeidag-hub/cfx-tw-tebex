Config = {}

-- ============================================================
-- General Settings
-- ============================================================

-- Note: This config is intentionally heavily commented. As one of the most 
-- critical resources for your community/server, I chose to document every 
-- option in detail to help avoid misconfiguration. If something's unclear, 
-- please check our official documentation.

-- Some translations were AI-assisted, since covering 15+ languages manually 
-- isn't realistic. Thanks for your support and for using this project!

Config.Framework         = "auto"   -- "auto" detects ESX / QBCore / QBox. Force with: "ESX", "QB", "QBX"
Config.DiscordLogs       = true     -- Enable Discord webhook logs (set webhook URL in server.lua line 1)
Config.StoreCommand      = "loja"   -- Command that opens the store/status UI (/loja)

Config.SubscriptionDays    = 30    -- Days one recurring payment covers
Config.ExpiryCheckInterval = 5     -- Minutes between expired-subscription sweeps

-- Vehicle reward
Config.SpaceInLicensePlate = false    -- true → "ABC 123", false → "ABC123"
Config.LicensePlateLetters = 3
Config.LicensePlateNumbers = 3
Config.CarRewardGarage     = "legion" -- Garage ID where purchased cars land (must exist in your garage resource)
Config.GarageSystem        = "auto"   -- "auto" (recommended), or force: "jg", "cd", "default"

-- Inventory
Config.InventorySystem = "auto"  -- "auto" (recommended), or force: "ox", "qs", "native", "custom"

-- Language used for player-facing notifications.
-- Options: en, pt, pt-br, es, de, fr, pl, ru, tr, nl, sv, zh, ja, it, ro
Config.Locale = "pt"

-- Item images in the store UI.
-- "auto" → ox_inventory web images when detected, otherwise no image.
-- Override per-item with an `image` field (see examples below).
Config.UseOxInventoryImages = "auto"

-- Store UI accent colours. Applied as CSS custom properties on the NUI page.
--   primary  → main buttons, active tab underline, scrollbar, badges
--   accent   → hover states, glows, lighter highlights
--   glow     → rgba box-shadow colour (include alpha)
Config.UIColors = {
    primary = "#1d4ed8",
    accent  = "#3b82f6",
    glow    = "rgba(59,130,246,.35)",
}

-- Logo shown in the store hero (top-left of the panel).
-- Displayed at 60 × 60 px. Use a square PNG/WEBP for best results.
-- Set to "" to hide the logo.
Config.UILogo = "https://i.imgur.com/aSygWHc.png"

-- Background image for the hero section.
-- Recommended: at least 1 200 × 460 px, landscape/panoramic crop.
-- The hero panel is 228 px tall — wide images are cropped to centre.
-- Set to "" to use a solid dark gradient instead.
Config.UIHeroBanner = "https://i.imgur.com/EKCBakf.png"


-- ============================================================
-- BUILT-IN REWARD TYPES — reference
-- ============================================================
--
--   type = "item"
--       Grants an inventory item.
--       Example: { type="item", name="lockpick", amount=5, label="5x Lockpick" }
--
--   type = "weapon"
--       Grants a weapon + ammo. `amount` = ammo count.
--       Example: { type="weapon", name="WEAPON_PISTOL", amount=120, label="Pistol + 120 Ammo" }
--
--   type = "account"
--       Adds money to an account ("bank", "cash", "black_money", etc.)
--       Example: { type="account", name="bank", amount=50000, label="$50,000 Bank" }
--
--   type = "car"
--       Inserts the vehicle straight into the garage DB (no client spawn). `model` = spawn name.
--       Example: { type="car", model="adder", label="Adder" }
--
--   type = "physical"
--       NOT auto-granted — logged in tw_physical_claims for staff to fulfil manually.
--       Valid inside Config.Milestones only.
--       Example: { type="physical", label="TW T-Shirt", image="img/tshirt.png" }
--
-- Anything else ("skillpoints", "invweight", "storecredit", ...) is handled by
-- Config.RewardHandlers below. If no handler is defined for that type, the event
-- "tw_tebexstore:customReward" is fired as a fallback.
--
-- IMAGE OVERRIDE — add `image` to any item to override the default:
--   image = "img/myfile.png"   →  file inside html/img/ of this resource
--   image = "https://..."      →  any public URL


-- ============================================================
-- CUSTOM REWARD HANDLERS
-- ============================================================
-- Map any custom reward `type` to your own export calls.
--
--   grant  → called when the reward is given (purchase / redemption).
--   revoke → called when the subscription is cancelled or package is refunded.
--            Optional — omit the key if the reward cannot / should not be reversed.
--
-- If a handler is defined, `tw_tebexstore:customReward` is NOT fired for that type
-- (the handler IS the implementation). Types with no handler fall back to the event.
--
-- Revoke is also fired as the event "tw_tebexstore:revokeReward"
-- (src, type, amount, label, identifier) regardless, so you can listen to both.

Config.RewardHandlers = {
    -- skillpoints = {
    --     grant  = function(src, amount) exports['your_skilltree']:AddPoints(src, amount)    end,
    --     revoke = function(src, amount) exports['your_skilltree']:RemovePoints(src, amount) end,
    -- },

    -- invweight = {
    --     grant  = function(src, amount) exports['ox_inventory']:SetMaxWeight(src, exports['ox_inventory']:GetMaxWeight(src) + amount * 1000) end,
    --     revoke = function(src, amount) exports['ox_inventory']:SetMaxWeight(src, exports['ox_inventory']:GetMaxWeight(src) - amount * 1000) end,
    -- },

    -- storecredit = {
    --     grant  = function(src, amount) exports['your_standvip']:AddCredit(src, amount) end,
    --     -- no revoke: store credits are non-refundable
    -- },

    -- autocredit = {
    --     grant  = function(src, amount) exports['your_autocredit']:Add(src, amount)    end,
    --     revoke = function(src, amount) exports['your_autocredit']:Remove(src, amount) end,
    -- },

    -- unlockskills = {
    --     grant  = function(src, amount) exports['your_skills']:Unlock(src) end,
    --     revoke = function(src, amount) exports['your_skills']:Lock(src)   end,
    -- },

    -- unlockgangskills = {
    --     grant  = function(src, amount) exports['your_gangskills']:Unlock(src) end,
    --     revoke = function(src, amount) exports['your_gangskills']:Lock(src)   end,
    -- },

    -- plate = {
    --     grant  = function(src, amount) exports['your_plates']:GrantVoucher(src, amount) end,
    -- },
}

-- Revoke events fired automatically (no handler needed to listen to these):
--
--   "tw_tebexstore:revokeSubscription"  (src, identifier, tierId, reason)
--       → fired when a subscription tier is cancelled/refunded, after Group is revoked.
--
--   "tw_tebexstore:revokePackage"  (src, identifier, packageName, reason)
--       → fired when a one-off package is refunded. src may be -1 if player is offline.
--
--   "tw_tebexstore:revokeReward"  (src, type, amount, label, identifier)
--       → fired for every individual reward item during any revoke, alongside handler calls.
--
-- Example listener (in another resource):
--   AddEventHandler('tw_tebexstore:revokeSubscription', function(src, identifier, tierId, reason)
--       if tierId == 'prestigio' then
--           exports['your_whitelist']:Remove(identifier)
--       end
--   end)


-- ============================================================
-- HOW TO ADD A NEW TIER (recurring subscription)
-- ============================================================
-- 1. Create the recurring package on Tebex and copy its numeric Package ID.
-- 2. Add a block below. Set a unique `id`, `PackageId`, `PackageName`, `Label`, `Group`.
-- 3. Fill FirstPurchaseRewards (once), RenewalRewards (every renewal), Items (every payment).
-- 4. Add a matching entry in Config.Milestones (can be empty: yourid = {}).

Config.Tiers = {
    -- -------------------------------------------------------
    -- TIER 1 — Basic subscription
    -- -------------------------------------------------------
    {
        id          = "benfeitor",
        PackageId   = 7455661,           -- Tebex numeric Package ID (stable across renames)
        PackageName = "Passe Benfeitor", -- Exact Tebex package name (fallback match)
        Label       = "Passe Benfeitor",
        Group       = "vip_benfeitor",   -- Group granted while subscription is active

        MaxWeight        = 100000,  -- grams (100 kg) — applied via ox_inventory when detected
        OutfitSlots      = 5,
        FreeClothingShop = false,

        Privileges = {  -- display-only bullet points in the store UI
            "Inventory increased to 100 kg",
            "5 custom outfit slots",
            "Server queue priority",
            "VIP tag on Discord",
        },

        -- Granted ONCE on the very first subscription.
        FirstPurchaseRewards = {
            { type = "item",    name = "lockpick", amount = 5,     label = "5x Lockpick" },
            { type = "account", name = "bank",     amount = 25000, label = "$25,000 Bank" },
            { type = "storecredit", amount = 1,    label = "1x Store Credit" },
        },

        -- Granted on every renewal (month 2, 3, 4 …).
        RenewalRewards = {
            { type = "item",    name = "lockpick", amount = 2,     label = "2x Lockpick" },
            { type = "account", name = "bank",     amount = 10000, label = "$10,000 Bank" },
        },

        -- Granted on EVERY payment including the first (stacks with First/RenewalRewards).
        Items = {
            { type = "skillpoints", amount = 2, label = "2 Skill Points" },
        },
    },

    -- -------------------------------------------------------
    -- TIER 2 — Premium subscription
    -- -------------------------------------------------------
    {
        id          = "prestigio",
        PackageId   = 7455668,
        PackageName = "Passe Prestígio",
        Label       = "Passe Prestígio",
        Group       = "vip_prestigio",

        MaxWeight        = 150000,  -- grams (150 kg)
        OutfitSlots      = 10,
        FreeClothingShop = true,

        Privileges = {
            "Inventory increased to 150 kg",
            "10 custom outfit slots",
            "Free clothing shop access",
            "Maximum queue priority",
            "Prestige tag on Discord",
        },

        FirstPurchaseRewards = {
            { type = "car",     model = "sultanrs",      label = "Sultan RS" },
            { type = "weapon",  name = "WEAPON_PISTOL",  amount = 120, label = "Pistol + 120 Ammo" },
            { type = "account", name = "bank",           amount = 75000, label = "$75,000 Bank" },
            { type = "skillpoints", amount = 10,         label = "10 Skill Points" },
        },

        RenewalRewards = {
            { type = "account", name = "bank",   amount = 25000, label = "$25,000 Bank" },
            { type = "item",    name = "lockpick", amount = 5,   label = "5x Lockpick" },
            { type = "storecredit", amount = 1,   label = "1x Store Credit" },
        },

        Items = {
            { type = "skillpoints", amount = 5, label = "5 Skill Points" },
        },
    },

    -- -------------------------------------------------------
    -- HOW TO ADD A THIRD TIER — copy this block and uncomment:
    -- -------------------------------------------------------
    -- {
    --     id          = "elite",
    --     PackageId   = 9999999,           -- replace with your Tebex Package ID
    --     PackageName = "Elite Pass",
    --     Label       = "Elite Pass",
    --     Group       = "vip_elite",
    --     MaxWeight   = 200000,
    --     OutfitSlots = 15,
    --     FreeClothingShop = true,
    --     Privileges  = { "Everything in Prestige", "Elite badge", "..." },
    --     FirstPurchaseRewards = {
    --         { type = "car",     model = "zentorno",             label = "Zentorno" },
    --         { type = "weapon",  name = "WEAPON_CARBINERIFLE",   amount = 250, label = "Carbine + 250 Ammo" },
    --         { type = "account", name = "bank", amount = 150000, label = "$150,000 Bank" },
    --     },
    --     RenewalRewards = {
    --         { type = "account", name = "bank", amount = 50000, label = "$50,000 Bank" },
    --     },
    --     Items = {
    --         { type = "skillpoints", amount = 10, label = "10 Skill Points" },
    --     },
    -- },
}


-- ============================================================
-- Milestones — loyalty rewards after N consecutive months
-- ============================================================
-- One entry per tier id above (even if empty).
-- Supports all types including "physical" (fulfilled manually by staff).

Config.Milestones = {
    benfeitor = {
        -- [3] = { { type = "item",     name = "lockpick", amount = 10, label = "10x Lockpick (3 months)" } },
        -- [6] = { { type = "physical", label = "TW T-Shirt", image = "img/tshirt.png" } },
    },
    prestigio = {
        -- [3] = { { type = "account", name = "bank", amount = 50000, label = "$50k (3 months)" } },
        -- [6] = { { type = "car", model = "t20", label = "T20 (6 months VIP)" } },
    },
    -- elite = {},
}


-- ============================================================
-- HOW TO ADD A NEW PACKAGE (one-off purchase)
-- ============================================================
-- 1. Create the one-time package on Tebex. Copy its numeric Package ID.
-- 2. Add a block below with PackageId, PackageName, and an Items list.
-- 3. A package can grant multiple items at once — add as many entries as needed.
-- 4. Revoke is handled automatically via Config.RewardHandlers if defined.

Config.Packages = {
    -- -------------------------------------------------------
    -- Built-in type examples
    -- -------------------------------------------------------
    {
        PackageId   = 7455680,
        PackageName = "Thief Kit",
        Items = {
            { type = "item", name = "lockpick", amount = 10, label = "10x Lockpick" },
            { type = "item", name = "thermite", amount = 2,  label = "2x Thermite" },
        },
    },
    {
        PackageId   = 7455681,
        PackageName = "Weapon Kit",
        Items = {
            { type = "weapon", name = "WEAPON_PISTOL",   amount = 120, label = "Pistol + 120 Ammo" },
            { type = "weapon", name = "WEAPON_MICROSMG", amount = 200, label = "Micro SMG + 200 Ammo" },
        },
    },
    {
        PackageId   = 7455682,
        PackageName = "$100,000 Bank",
        Items = {
            { type = "account", name = "bank", amount = 100000, label = "$100,000 Bank", image = "img/money.png" },
        },
    },
    {
        PackageId   = 7455683,
        PackageName = "Vehicle — Sultan RS",
        Items = {
            { type = "car", model = "sultanrs", label = "Sultan RS" },
        },
    },
    -- -------------------------------------------------------
    -- Custom type examples (handled via Config.RewardHandlers / event)
    -- -------------------------------------------------------
    {
        PackageId   = 7398123,
        PackageName = "5 Skill Points",
        Items = {
            { type = "skillpoints", amount = 5, label = "5 Skill Points" },
        },
    },
    {
        PackageId   = 7398116,
        PackageName = "1x Auto Credit",
        Items = {
            { type = "autocredit", amount = 1, label = "1x Auto Credit" },
        },
    },
    {
        PackageId   = 7398118,
        PackageName = "2x Auto Credits",
        Items = {
            { type = "autocredit", amount = 2, label = "2x Auto Credits" },
        },
    },
    {
        PackageId   = 7398121,
        PackageName = "3x Auto Credits",
        Items = {
            { type = "autocredit", amount = 3, label = "3x Auto Credits" },
        },
    },
    {
        PackageId   = 7455684,
        PackageName = "Unlock Skills",
        Items = {
            { type = "unlockskills", amount = 1, label = "Unlock Skills" },
        },
    },
    {
        PackageId   = 7455705,
        PackageName = "Unlock Gang Skills",
        Items = {
            { type = "unlockgangskills", amount = 1, label = "Unlock Gang Skills" },
        },
    },
    -- -------------------------------------------------------
    -- Template — copy and fill to add a new package:
    -- -------------------------------------------------------
    -- {
    --     PackageId   = 9999999,
    --     PackageName = "Package Name on Tebex",
    --     Items = {
    --         { type = "item",    name = "bread",            amount = 5,      label = "5x Bread" },
    --         { type = "account", name = "cash",             amount = 5000,   label = "$5,000 Cash" },
    --         { type = "weapon",  name = "WEAPON_BAT",       amount = 0,      label = "Baseball Bat" },
    --         { type = "car",     model = "infernus",        label = "Infernus" },
    --         { type = "skillpoints", amount = 5,            label = "5 Skill Points" },
    --     },
    -- },
}
