local mod = DBM:NewMod("Gruul", "DBM-Gruul");
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 183 $"):sub(12, -3))
mod:SetCreatureID(19044)

mod:RegisterCombat("combat", 19044)
mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED"
)

local timerEarthStrikeCD            = mod:NewCDTimer(133, 33525)
local timerEchoCD                   = mod:NewCDTimer(18, 36297)
local timerRockCD                   = mod:NewCDTimer(30, 36240)
local specWarnRock                  = mod:NewSpecialWarningMove(36240)

local timerHandCD                   = mod:NewCDTimer(29, 305188)
local timerHateStrike		    = mod:NewCDTimer(6, 305197)
local timerStunningBlow		    = mod:NewCDTimer(20, 305183)
local timerHandStrike               = mod:NewTimer(7,"Strike", 305188)
local timerFurnaceActive            = mod:NewTimer(8,"TimerFurnaceActive", 305201)
local timerFurnaceInactive          = mod:NewTimer(43,"TimerFurnaceInactive", 305201)
local timerBurnedFlesh              = mod:NewTimer(20,"TimerBurnedFlesh", 305204)

local rockCounter = 1

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 19044, "Gruul the Dragonkiller")
	if mod:IsDifficulty("heroic25") or mod:IsDifficulty("heroic10") then
		timerHandCD:Start(24)
		timerHateStrike:Start(20)
		timerStunningBlow:Start(15)
	elseif mod:IsDifficulty("normal25") or mod:IsDifficulty("normal10") then
		timerEarthStrikeCD:Start(35)
		timerRockCD:Start(28)
		rockCounter = 1
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 19044, "Gruul the Dragonkiller", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(33525) then
		 timerEarthStrikeCD:Start()
		 timerEchoCD:Start(25)
		 timerRockCD:Start(30 - rockCounter*2 + 4)
		 if rockCounter <= 11 then rockCounter = rockCounter + 1 end
		elseif args:IsSpellID(305197) then
			timerHateStrike:Start()
		elseif args:IsSpellID(305183) then
			timerStunningBlow:Start()
		end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(305188) then
		timerHandCD:Start()
		timerHandStrike:Start()
	elseif args:IsSpellID(36240) then
		timerRockCD:Start(30 - rockCounter*2)
		if rockCounter <= 11 then rockCounter = rockCounter + 1 end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305201) then
		timerFurnaceActive:Start()
	elseif args:IsSpellID(305204) then
		timerBurnedFlesh:Start()
	elseif args:IsSpellID(36297) then
		timerEchoCD:Start()
	elseif args:IsSpellID(36240) and args:IsPlayer() then
		specWarnRock:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(305201) then
		timerFurnaceInactive:Start()
	end
end
