local mod	= DBM:NewMod("Skyriss", "DBM-Party-BC", 10)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2250 $"):sub(12, -3))
mod:SetCreatureID(20912)
mod:SetZone()

mod:RegisterCombat("combat", 20912)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_AURA_REMOVED",
	"SPELL_AURA_APPLIED",
	"UNIT_HEALTH"
)

local warnSplitSoon		= mod:NewAnnounce("WarnSplitSoon", 2)
local warnSplit			= mod:NewAnnounce("WarnSplit", 3)
local warnMindControl	= mod:NewTargetAnnounce(39019, 4)
local warnMindRend		= mod:NewTargetAnnounce(39017, 2)

local timerMindControl	= mod:NewTargetTimer(6, 39019)
local timerMindRend		= mod:NewTargetTimer(6, 39017)

local warnedSplit1 = false
local warnedSplit2 = false

function mod:OnCombatStart()
	warnedSplit1 = false
	warnedSplit2 = false
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(39019, 37162) then
		warnMindControl:Show(args.destName)
		timerMindControl:Start(args.destName)
	elseif args:IsSpellID(39017) then
		warnMindRend:Show(args.destName)
		timerMindRend:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(39019, 37162) then
		timerMindControl:Stop()
	elseif args:IsSpellID(39017) then
		timerMindRend:Stop()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Split then
		warnSplit:Show()
	end
end

function mod:UNIT_HEALTH(uId)
	if not warnedSplit1 and self:GetUnitCreatureId(uId) == 20912 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.70 then
		warnedSplit1 = true
		warnSplitSoon:Show()
	elseif not warnedSplit2 and self:IsDifficulty("heroic5") and self:GetUnitCreatureId(uId) == 20912 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.37 then
		warnedSplit2 = true
		warnSplitSoon:Show()
	end
end
