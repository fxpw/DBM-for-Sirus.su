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
-- Обычка
local timerEarthStrikeCD            = mod:NewCDTimer(133, 33525)	-- Удар Земли
local timerEchoCD                   = mod:NewCDTimer(18, 36297)		-- Отзвук
local timerRockCD                   = mod:NewCDTimer(30, 36240)		-- Завал
local specWarnRock                  = mod:NewSpecialWarningMove(36240)	-- анонс Завала

-- Героик
local specWarnHands					= mod:NewSpecialWarningMoveAway(305188, "Hands")	-- Анонс рук(Зов камня)
local timerHandCD                   = mod:NewCDTimer(29, 305188)	-- Руки(Зов камня)
local timerHateStrike		    	= mod:NewCDTimer(6, 305197)			-- Удар ненависти
local timerStunningBlow		    	= mod:NewCDTimer(16, 305183)		-- Ошеломляющий удар
local timerHandStrike               = mod:NewTimer(7,"Strike", 305188)	-- руки закроются через/Хлопок
local timerFurnaceActive            = mod:NewTimer(8,"TimerFurnaceActive", 305201)	-- время активности печи
local timerFurnaceInactive          = mod:NewTimer(43,"TimerFurnaceInactive", 305201)	-- время неактивности печи
local timerBurnedFlesh              = mod:NewTimer(20,"TimerBurnedFlesh", 305204)	-- Обожженная плоть

local rockCounter = 1

mod:AddBoolOption("HandsOption",false)

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 19044, "Gruul the Dragonkiller")
	if mod:IsDifficulty("heroic25") or mod:IsDifficulty("heroic10") then
		timerHandCD:Start(24)
		timerHateStrike:Start(20)
		timerStunningBlow:Start(15)
	elseif mod:IsDifficulty("normal25") or mod:IsDifficulty("normal10") then
		timerEarthStrikeCD:Start(30)
		timerRockCD:Start(28)
		rockCounter = 1
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 19044, "Gruul the Dragonkiller", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(33525) then	-- Удар Земли
		 timerEarthStrikeCD:Start()
		 timerEchoCD:Start(25)
		 timerRockCD:Start(30 - rockCounter*2 + 4)
		 if rockCounter <= 11 then rockCounter = rockCounter + 1 end
		elseif args:IsSpellID(305197) then	-- Удар ненависти
			timerHateStrike:Start()
		elseif args:IsSpellID(305183) then	-- Ошеломляющий удар
			timerStunningBlow:Start()
		end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(305188) then	-- Анонс появления рук и следующий таймер рук
		if self.Options.HandsOption then
			specWarnHands:Show()
		end
		timerHandCD:Start()
		timerHandStrike:Start()
	elseif args:IsSpellID(36240) then	-- Завал
		timerRockCD:Start(30 - rockCounter*2)
		if rockCounter <= 11 then rockCounter = rockCounter + 1 end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305201) then	-- время активности печи
		timerFurnaceActive:Start()
	elseif args:IsSpellID(305204) then	-- Обожженная плоть
		timerBurnedFlesh:Start()
	elseif args:IsSpellID(36297) then	-- Отзвук
		timerEchoCD:Start()
	elseif args:IsSpellID(36240) and args:IsPlayer() then	-- Анонс Завала - отбеги
		specWarnRock:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)	-- печь неактивна
	if args:IsSpellID(305201) then
		timerFurnaceInactive:Start()
	end
end

