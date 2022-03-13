local mod	= DBM:NewMod("Exarh", "DBM-Party-BC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2250 $"):sub(12, -3))
mod:SetCreatureID(18373)
mod:SetZone()

mod:RegisterCombat("combat", 18373)

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_CAST_START",
	"SPELL_SUMMON",
	"SPELL_AURA_APPLIED"
)

local timerScreamCD		= mod:NewCDTimer(33, 32421)
local timerSoulCD		= mod:NewCDTimer(25, 32346)
local timerMortalCD		= mod:NewCDTimer(30, 16856)
local timerMortal		= mod:NewTargetTimer(5, 16856, nil, "Tank|Healer")
local specWarnSoul      = mod:NewSpecialWarningYou(32346)
local warnSoul          = mod:NewAnnounce("WarnSoul", 32346)
local avatar = 0

function mod:OnCombatStart(delay)
	timerScreamCD:Start()
	timerSoulCD:Start()
end

function mod:SPELL_SUMMON(args)
	if args:IsSpellID(32424) then
		avatar = args.destGUID
		timerMortalCD:Start(10)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(32346) then
		timerSoulCD:Start()
		warnSoul:Show(args.destName)
		if args:IsPlayer() then
			specWarnSoul:Show()
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(32421) then
		timerScreamCD:Start()
	elseif args:IsSpellID(16856) and args.sourceGUID == avatar then
		timerMortalCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(16856) and args.sourceGUID == avatar then
		timerMortal:Start(args.destName)
	end
end
