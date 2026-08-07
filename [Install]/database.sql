DROP TABLE IF EXISTS `codes`;
CREATE TABLE IF NOT EXISTS `codes` (
  `code` varchar(50) NOT NULL DEFAULT '',
  `packagename` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `tw_subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `tier` varchar(50) NOT NULL,
  `months_active` int(11) NOT NULL DEFAULT 0,
  `started_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  `status` enum('active','expired','cancelled') NOT NULL DEFAULT 'active',
  `last_transaction` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_tier` (`identifier`, `tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tw_milestones_claimed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `tier` varchar(50) NOT NULL,
  `month` int(11) NOT NULL,
  `claimed_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_tier_month` (`identifier`, `tier`, `month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tw_physical_claims` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `tier` varchar(50) NOT NULL,
  `month` int(11) NOT NULL,
  `label` varchar(150) NOT NULL,
  `status` enum('pending','shipped') NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tw_transaction_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `transaction_id` varchar(50) NOT NULL,
  `package_name` varchar(150) NOT NULL,
  `label` varchar(150) NOT NULL,
  `type` enum('subscription','package') NOT NULL DEFAULT 'package',
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Permanent inventory weight bonus (from "+25KG" style purchases). Stacks: buying it twice adds up.
-- This is ADDED on top of the player's tier MaxWeight (or Config.DefaultInventoryWeight) every time
-- weight is (re)applied — see ApplyTotalWeight in server.lua.
CREATE TABLE IF NOT EXISTS `tw_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `group` varchar(50) NOT NULL,
  `granted_at` datetime NOT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_group` (`identifier`, `group`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tw_inventory_bonus` (
  `identifier` varchar(64) NOT NULL,
  `extra_grams` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
