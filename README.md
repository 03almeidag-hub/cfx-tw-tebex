![TWTebex banner](https://i.postimg.cc/sxh9s08z/Subscription-System.png)

FiveM resource that connects your **Tebex** store to your server: processes purchases automatically, grants items/weapons/vehicles/money, manages **recurring VIP subscriptions** with loyalty-month tracking, and exposes its own in-game interface (`/store`) so players can check what they have and redeem transactions without leaving the game.

> This project is an improved integration built on top of **[nass_tebexstore](https://github.com/najeetpie/nass_tebexstore)** by **najeetpie**. All credit to him for the base Tebex code redemption system — this resource extends that base with subscriptions, loyalty milestones, its own UI, and multi-framework/multi-inventory support.

<table>
<tr>
<td>

### Run Your Server Like A Business

Monetize your game server with the same tools used by Hypixel and FiveM. Sell items, subscriptions, and passes – while Tebex handles payments, compliance, and risk.

<a href="https://www.tebex.io/server"><img alt="Get Started with Tebex" src="https://img.shields.io/badge/Tebex-Get%20Started-e11d2c?style=for-the-badge"></a>

</td>
</tr>
</table>

## Features

**Inherited from nass_tebexstore:**
- Store automation: Tebex runs a server command on purchase, no manual intervention needed
- Grants items, weapons, vehicles and money
- Discord logs
- Easily configurable

**Added in this version:**
- Own UI (`/store`) — players see their active subscription, items received, perks, loyalty milestones and transaction history, and can redeem a Transaction ID without leaving the game (chat command `/redeem [Transaction ID]` still works as a fallback)
- Recurring subscriptions (VIP tiers) with automatic active-months tracking, renewal, and automatic expiry when a subscription isn't renewed
- Different rewards on first purchase vs. every renewal
- Loyalty milestones per number of consecutive active months, including **physical** rewards.
- **Multi-framework**: auto-detects **ESX**, **QBCore** or **QBox**, or can be forced manually
- **Multi-inventory**: auto-detects **ox_inventory**, **qs-inventory**, or falls back to the framework's native inventory
- Rewards this script doesn't implement natively (e.g. skill points, third-party store credit) fire an event (`tw_tebexstore:customReward`) for another resource to handle
- Redeem attempts are logged to the server console (success/failure), in addition to Discord logs
- Anti-exploit protections: the purchase command is only accepted from the console, vehicles are validated by a server-side callback before spawning, and suspicious attempts are reported to Discord

## Compatibility

| | Supported |
|---|---|
| Framework | ESX, QBCore, QBox (auto-detected via `Config.Framework = "auto"`, or force `"ESX"` / `"QB"` / `"QBX"`) |
| Inventory | ox_inventory, qs-inventory, the framework's native inventory (auto-detected) |

## Installation

1. Drop the resource into your server's `resources` folder
2. Import `[INSTALL]/database.sql` into your database
3. Add `ensure cfx_tw_tebex` to your `server.cfg`
4. Set `sv_tebexSecret` in `server.cfg` — the resource won't start without it
5. Configure `shared/config.lua` (see below)

### Tebex
On the package (one-off or recurring), under **Store Commands**, set the command executed on purchase:
```
purchase_package_tebex {"transid":"{transaction}", "packageid":{packageId}}
```
- Enable **"Execute the command even if the player is offline"**
- `packageid` is the package's numeric ID (preferred — doesn't break if you rename the package on Tebex). `packagename` is also accepted as an alternative/fallback.

### Garage
Depending on the garage system your server uses, you may need to adapt the `tw_tebex:setVehicle` event in `server/server.lua` to match it.

## Configuration

Everything lives in `shared/config.lua`:
- `Config.Framework` — `"auto"` (recommended), or force `"ESX"` / `"QB"` / `"QBX"`
- `Config.Tiers` — each VIP tier: `PackageId`/`PackageName`, `Group`, `MaxWeight`, `Privileges`, and rewards (`FirstPurchaseRewards`, `RenewalRewards`, `Items`)
- `Config.Packages` — one-off (non-recurring) packages
- `Config.Milestones` — rewards per number of consecutive active months, per tier
- `Config.SubscriptionDays` — length of each subscription period (30 days by default)
- `Config.StoreCommand` — command that opens the store UI (`/store`)
- `Config.UseOxInventoryImages` — `"auto"` (follows inventory detection) or force `true`/`false`; each item also accepts a custom `image` field

## Usage

**Player:**
- `/store` opens the store: active subscription, items, perks, loyalty milestones and transaction history
- "Redeem Transaction" modal in the UI, or `/redeem [Transaction ID]` via chat

**Staff:**
- `/twstore_pending` — lists pending physical rewards (server console)
- `/twstore_sended [id]` — marks a physical reward as shipped

## Credits
- Base Tebex code redemption system: **[nass_tebexstore](https://github.com/najeetpie/nass_tebexstore)** by **najeetpie**
- Original project support: [Discord](https://discord.gg/fz655NHeDq)
