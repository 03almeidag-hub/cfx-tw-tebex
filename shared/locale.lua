-- ============================================================
-- Locale / i18n bridge
-- ============================================================
-- Reads Config.Locale and exposes _T(key, ...) for translations.
-- Falls back to 'en' if the selected locale is missing.
-- Supports sub-locale fallback: 'pt-br' → 'pt' → 'en'.

local function ResolveStrings()
	local lang = (Config.Locale or 'en'):lower()

	if Locales[lang] then return Locales[lang] end

	-- try base language (e.g. 'pt-br' → 'pt')
	local base = lang:match('^(%a+)')
	if base and Locales[base] then return Locales[base] end

	return Locales['en'] or {}
end

local _strings = ResolveStrings()

function _T(key, ...)
	local str = _strings[key] or (Locales['en'] and Locales['en'][key]) or key
	if select('#', ...) > 0 then
		return str:format(...)
	end
	return str
end
