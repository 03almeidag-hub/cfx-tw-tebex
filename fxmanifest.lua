fx_version 'cerulean'
game 'gta5'

-- ============================================================================
--  TW-TebexStore | Tebex Store Reward Redemption System
-- ============================================================================
--
--  Tebex   - https://www.tebex.io
--  FiveM   - https://fivem.net
--
--  IMPORTANT: When creating products/packages on your Tebex store, make sure
--  they comply with the FiveM ToS (https://fivem.net/terms) and Tebex's
--  policies (https://www.tebex.io/terms). This includes rules around pay-to-win
--  mechanics, prohibited items, and platform-specific monetization guidelines.
--
--  Note: Items considered "merchandise" (e.g. branded/exclusive cosmetic
--  items, etc.) CANNOT be sold directly as Tebex store packages, but can be
--  distributed as redeemable rewards through this system at your discretion.
-- ============================================================================

author '.tribalwars <https://github.com/03almeidag-hub>'
description 'Tebex Store Reward Redemption System - TW-TebexStore'
version '1.0.3'
credits 'najeetpie - https://github.com/najeetpie/nass_tebexstore'

shared_scripts {
	'shared/config.lua',
	'locales/*.lua',
	'shared/locale.lua',
	'shared/framework.lua',
	'shared/inventory.lua',
	'shared/garage.lua',
	'shared/groups.lua',
}

client_script 'client/client.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/version.lua',
	'server/server.lua'
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/style.css',
	'html/script.js'
}

dependency 'oxmysql'

lua54 'yes'
use_experimental_fxv2_oal 'yes'
