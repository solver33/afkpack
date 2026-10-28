local _, ns = ...

local L = {
	TITLE = "AfkPack",

	LOOT_HEADER = "Loot rolls",
	MODE_OFF = "Off (roll manually)",
	MODE_PASS = "Pass on all loot",
	MODE_NEED = "Need if possible, otherwise the best available option",
	MODE_GREED = "Transmog / Greed only, never Need",

	ACCEPT_HEADER = "Auto-accept",
	AUTO_SUMMON = "Accept summons",
	AUTO_RESURRECT = "Accept resurrections",

	ROLL_PASS = "Pass",
	ROLL_NEED = "Need",
	ROLL_GREED = "Greed",
	ROLL_TRANSMOG = "Transmog",

	ON = "|cff00ff00on|r",
	OFF = "|cffff4040off|r",
	UNKNOWN = "?",

	ROLLED = "%s: %s",
	SUMMON_ACCEPTED = "Accepted summon from %s to %s.",
	SUMMON_WAITING = "Summon will be accepted as soon as possible (e.g. after combat).",
	SUMMON_START_AREA = "This summon would skip the starting area, accept it manually.",
	RES_ACCEPTED = "Accepted resurrection from %s.",
	RES_WAITING = "Resurrection will be accepted in %d sec.",

	STATUS_LOOT = "Loot rolls: %s",
	STATUS_SUMMON = "Accept summons: %s",
	STATUS_RESURRECT = "Accept resurrections: %s",
	UNKNOWN_COMMAND = "Unknown command \"%s\". Type /afkpack help.",
	HELP = {
		"/afkpack - open the settings window",
		"/afkpack off | pass | need | greed - set the loot roll mode",
		"/afkpack summon - toggle accepting summons",
		"/afkpack res - toggle accepting resurrections",
		"/afkpack status - show current settings",
	},
}

if GetLocale() == "ruRU" then
	L.LOOT_HEADER = "Броски за лут"
	L.MODE_OFF = "Выключено (бросаю сам)"
	L.MODE_PASS = "Отказываться от всего лута"
	L.MODE_NEED = "Need, если можно, иначе лучший доступный вариант"
	L.MODE_GREED = "Только Transmog / Greed, без Need"

	L.ACCEPT_HEADER = "Автопринятие"
	L.AUTO_SUMMON = "Принимать призыв (суммон)"
	L.AUTO_RESURRECT = "Принимать воскрешение"

	L.ROLL_PASS = "Отказ"
	L.ROLL_NEED = "Need"
	L.ROLL_GREED = "Greed"
	L.ROLL_TRANSMOG = "Transmog"

	L.ON = "|cff00ff00вкл|r"
	L.OFF = "|cffff4040выкл|r"

	L.SUMMON_ACCEPTED = "Принят призыв от %s в %s."
	L.SUMMON_WAITING = "Призыв будет принят, как только это станет возможно (например, после боя)."
	L.SUMMON_START_AREA = "Этот призыв пропустит стартовую зону, прими его вручную."
	L.RES_ACCEPTED = "Принято воскрешение от %s."
	L.RES_WAITING = "Воскрешение будет принято через %d сек."

	L.STATUS_LOOT = "Броски за лут: %s"
	L.STATUS_SUMMON = "Принимать призыв: %s"
	L.STATUS_RESURRECT = "Принимать воскрешение: %s"
	L.UNKNOWN_COMMAND = "Неизвестная команда \"%s\". Введи /afkpack help."
	L.HELP = {
		"/afkpack - открыть окно настроек",
		"/afkpack off | pass | need | greed - режим бросков за лут",
		"/afkpack summon - вкл/выкл принятие призыва",
		"/afkpack res - вкл/выкл принятие воскрешения",
		"/afkpack status - текущие настройки",
	}
end

ns.L = L
