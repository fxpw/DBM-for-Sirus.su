local mod = DBM:NewMod("Maulgar", "DBM-Gruul");
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 183 $"):sub(12, -3))
mod:SetCreatureID(18831)
mod:SetUsedIcons(8,7,6,5,4)

mod:RegisterCombat("combat", 18831)
mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED"
)

local isDispeller = select(2, UnitClass("player")) == "PRIEST" or select(2, UnitClass("player")) == "SHAMAN" or select(2, UnitClass("player")) == "MAGE"

--обычка
local timerWhirlCD                   = mod:NewCDTimer(55, 33238)	-- Вихрь короля
local timerWhirl                     = mod:NewTimer(15, "TimerWhirl", 33238)	-- Время действия вихря короля
local timerIntimidateCD              = mod:NewCDTimer(16, 16508)	-- устрашающий рев
local specWarnMelee                  = mod:NewSpecialWarningMove(33238, "Melee")	--анонс для миликов при вихре короля

--Героик
local timerMight                     = mod:NewTargetTimer(60, 305216, "timerActive")	-- время действия Переполняющая мощь
local timerMightCD                   = mod:NewCDTimer(60, 305216)	-- Переполняющая мощь
local specWarnShield                 = mod:NewSpecialWarningDispel(305247, isDispeller)	-- Анонс диспела Щит заклятий
local specWarnKickCleanse            = mod:NewSpecialWarning("KickNow", "-Melee")	-- Анонс кика каста
local warnMight                      = mod:NewAnnounce("WarnMight", 2)	-- Анонс активации(Переполняющая мощь)

mod:AddBoolOption("WarnMight",true)
mod:AddBoolOption("AnnounceToChat",false)
mod:AddBoolOption("RangeFireBomb",false)

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 18831, "High King Maulgar")
	if mod:IsDifficulty("heroic25") then
		timerMight:Start(5)
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 18831, "High King Maulgar", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305221) then	-- Пламенное очищение
		specWarnKickCleanse:Show(args.spellName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)	-- Устрашающий рев
	if args:IsSpellID(16508) then
		timerIntimidateCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305216) then	-- Активация
		local activeIcon
		for i = 1,40 do
			if UnitName("raid" .. i .. "target") == L.name then
				activeIcon = GetRaidTargetIndex("raid" .. i .. "targettarget")
			end
		end
		timerMightCD:Start()
		warnMight:Show(args.destName, activeIcon or "Interface\\Icons\\Inv_misc_questionmark")
		timerMight:Start(args.destName, activeIcon or "Interface\\Icons\\Inv_misc_questionmark")
		if self.Options.AnnounceToChat then
			SendChatMessage((activeIcon and ("{rt" .. activeIcon .. "} ") or "") .. args.destName .. " активен", "RAID")
		end
	elseif args:IsSpellID(305247) then	-- Щит заклятий(Гер)
		specWarnShield:Show()
	elseif args:IsSpellID(33054) then -- Щит заклятий(Об)
		specWarnShield:Show()
	elseif args:IsSpellID(33238) then	-- Вихрь
		timerWhirlCD:Start()
		timerWhirl:Start()
		specWarnMelee:Show()
	elseif args:IsSpellID(305236) and args:IsPlayer() then	-- рендж при появлении на тебе живой бомбы
		if self.Options.RangeFireBomb then
			DBM.RangeCheck:Show(7)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)	-- убрать рендж при исчезновении
	if args:IsSpellID(305236) and args:IsPlayer() then
		if self.Options.RangeFireBomb then
			DBM.RangeCheck:Hide()
		end
	end
end
