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

## 🤝 Contributing
Contributions and pull requests should be made through GitHub. All feedback is welcome — report bugs or suggest improvements by opening an [issue](https://github.com/03almeidag-hub/cfx-tw-tebex/issues).

**Note:** If you're using this project, please download it from the **Releases** page instead of the source code.
⚠️ Keep in mind that the source code may contain changes that are not yet available for production (features in development, internal testing, etc.). Bug fixes are released immediately in a new patch as soon as they're identified, and you'll be notified directly in the server console whenever an update is available.

## Features

**Inherited from nass_tebexstore:**
- Store automation: Tebex runs a server command on purchase, no manual intervention needed
- Grants items, weapons, vehicles and money
- Discord logs
- Easily configurable

## ✨ Features

### 🖥️ In-Game Store UI
- Own UI (`/store`) — players see their active subscription, items received, perks, loyalty milestones and transaction history, and can redeem a Transaction ID without leaving the game (chat command `/redeem [Transaction ID]` still works as a fallback)
- Configurable UI colour theme — `Config.UIColors { primary, accent, glow }` in `shared/config.lua`, applied at runtime without a resource restart
- Configurable logo and hero banner — `Config.UILogo` (60×60 px) and `Config.UIHeroBanner` set in config, no source edits needed
- Multilingual store interface — 40 locale keys across 15 languages (en, pt, pt-BR, es, de, fr, pl, ru, tr, nl, sv, zh, ja, it, ro), UI language follows `Config.Locale` automatically, date formatting adapts per locale
- Fixed panel dimensions (1200×720 px) — layout no longer shifts based on active subscriptions or milestones
- Semi-transparent panel background with `backdrop-filter: blur`

### 💳 Subscriptions & Rewards
- Recurring subscriptions (VIP tiers) with automatic active-months tracking, renewal, and automatic expiry when a subscription isn't renewed
- Subscription expiry now revokes the VIP group immediately for online players instead of waiting for a reconnect
- Different rewards on first purchase vs. every renewal
- Loyalty milestones per number of consecutive active months, including physical rewards

### 🔌 Compatibility
- Multi-framework: auto-detects ESX, QBCore or QBox, or can be forced manually
- Multi-inventory: auto-detects ox_inventory, qs-inventory, or falls back to the framework's native inventory
- Rewards this script doesn't implement natively (e.g. skill points, third-party store credit) fire an event (`tw_tebexstore:customReward`) for another resource to handle

### 🔒 Logging & Security
- Redeem attempts are logged to the server console (success/failure), in addition to Discord logs
- Anti-exploit protections: the purchase command is only accepted from the console, vehicles are validated by a server-side callback before spawning, and suspicious attempts are reported to Discord


## Installation
Follow Documentation, [click here](https://cfxtw.vercel.app/).

## Preview

<div align="center">

| Home Page | History | Redeem Modal |
|:---:|:---:|:---:|
| ![Home Page](https://i.imgur.com/Q7g3f1t.png) | ![History](https://i.imgur.com/xQETJqv.png) | ![Redeem Modal](https://i.imgur.com/9CO922Q.png) |

</div>

## 💜 Supported by

<p align="center">
  <a href="https://lusoroleplay.pt/">
    <img src="https://lusoroleplay.pt/data/imagens/logo.png" alt="LusoRoleplay" width="172" height="82">
  </a>
</p>

This project is supported by **[LusoRoleplay](https://lusoroleplay.pt/)**. It was developed out of this server's own interest, and we decided to share this resource with the community.

## Credits
- Base Tebex code redemption system: **[nass_tebexstore](https://github.com/najeetpie/nass_tebexstore)** by **najeetpie**
- Original project support: [Discord](https://discord.gg/fz655NHeDq)
