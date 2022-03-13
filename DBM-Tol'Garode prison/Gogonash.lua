local mod	= DBM:NewMod("Gogonash", "DBM-Tol'Garod", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("20210501000000"):sub(12, -3))
mod:SetCreatureID(84000)

mod:RegisterCombat("combat", 84000)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_SUMMON",
	"UNIT_HEALTH"
)
-- сделал разные таймера для 10 и 25 потому что видел только 10-ку --
local warnlightningfilth 				= mod:NewCastAnnounce(317549, 2) -- анонс каста молнии скверны
local warnhorror						= mod:NewCastAnnounce(317548, 1.5)  -- анонс каста Первобытного ужаса

local specWarnDispelFlame               = mod:NewSpecialWarningDispel(317540, "MagicDispeller", nil, nil, 1, 2)    -- оповещение - диспел

local flameFilth10						= mod:NewCDTimer(13, 317540, nil, nil, nil, 3)  -- Нескончаемое пламя Скверны(10)
local flameFilth25						= mod:NewCDTimer(13, 317729, nil, nil, nil, 3)  -- Нескончаемое пламя Скверны(25)
local strikingblow						= mod:NewCDTimer(8, 317543, nil, "Tank|Healer", nil, 4) -- разящий удар
local lightningfilth10                  = mod:NewCastTimer(14, 317549)   -- Молния скверны (10)
local lightningfilth25                  = mod:NewCastTimer(14, 317731)   -- Молния скверны (25)
local timerHorror                       = mod:NewCDTimer(30, 317548, nil, nil, nil, 3) -- Первобытный ужас
local crushingblow10                      = mod:NewCDTimer(35, 317541, nil, nil, nil, 3)   -- Сокрушающий удар(10)
local crushingblow25                      = mod:NewCDTimer(35, 317730, nil, nil, nil, 3)   -- Сокрушающий удар(25)



function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 84000, "Gogonash")
    if mod:IsDifficulty("normal10") then
	    strikingblow:Start(5)
        lightningfilth10:Start(8)
        timerHorror:Start(25)
        crushingblow10:Start(65)
    elseif mod:IsDifficulty("normal25") then
        strikingblow:Start(5)
        lightningfilth25:Start(8)
        timerHorror:Start(25)
        crushingblow25:Start(65)
    end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 84000, "Gogonash", wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 317549 then   -- Молния скверны (10)
		warnlightningfilth:Show()
		lightningfilth10:Start()
	elseif spellId == 317548 then   -- Первобытный ужас
		warnhorror:Show()
		timerHorror:Start(33)
        if strikingblow:GetRemaining() then -- динамическое обновление таймера разящий удар
            local elapsed, total = strikingblow:GetTime()
            local extend = total-elapsed
            strikingblow:Stop()
            strikingblow:Update(0, 2.5+extend)
            end
    elseif spellId == 317731 then   -- Молния скверны (25)
		warnlightningfilth:Show()
		lightningfilth25:Start()
    elseif spellId == 317541 then   -- Сокрушающий удар(10)
        crushingblow10:Start()
    elseif spellId == 317730 then   -- Сокрушающий удар(10)
        crushingblow25:Start()
    end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 317543 then   -- разящий удар
		if args:IsPlayer() then
			strikingblow:Start()
		end
    elseif spellId == 317540 and args:IsPlayer() then ---- Нескончаемое пламя Скверны(25)
        specWarnDispelFlame:Show()
        flameFilth10:Start()
    elseif spellId == 317729 and args:IsPlayer() then ---- Нескончаемое пламя Скверны(25)
        specWarnDispelFlame:Show()
        flameFilth25:Start()
    end
end

