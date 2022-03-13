local mod	= DBM:NewMod("MagicEater", "DBM-Tol'Garod", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("20210501000000"):sub(12, -3))
mod:SetCreatureID(84017)

mod:RegisterCombat("combat", 84017)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_SUMMON",
	"UNIT_HEALTH"
)

local warnlightningfilth 				= mod:NewCastAnnounce(3175494, 2) -- анонс каста молнии скверны
local warnhorror						= mod:NewCastAnnounce(317548, 1.5)  -- анонс каста Первобытного ужаса

local specWarnDispelFlame               = mod:NewSpecialWarningDispel(317540, "MagicDispeller", nil, nil, 1, 2)    -- оповещение - диспел

local ShadowArrow						= mod:NewCDTimer(2, 306150, nil, nil, nil, 3)  -- Стрела Тьмы(10)
local Blow						        = mod:NewCDTimer(13, 317564, nil, nil, nil, 3)  -- Омрачающий удар(10)
local strikingblow						= mod:NewCDTimer(8, 317543, nil, "Tank|Healer", nil, 4) -- разящий удар
local lightningfilth10                  = mod:NewCastTimer(14, 317549)   -- Молния скверны (10)
local lightningfilth25                  = mod:NewCastTimer(14, 317731)   -- Молния скверны (25)
local timerHorror                       = mod:NewCDTimer(30, 317548, nil, nil, nil, 3) -- Первобытный ужас
local crushingblow10                      = mod:NewCDTimer(35, 317541, nil, nil, nil, 3)   -- Сокрушающий удар(10)
local crushingblow25                      = mod:NewCDTimer(35, 317730, nil, nil, nil, 3)   -- Сокрушающий удар(25)

-- 0/10 PULL
-- 0/35 Дыхание Мрака  28 секунд с пула
-- 0/45 хуета портальная   38 секунд
-- 1/00 Дыхание Мрака 25 с 


function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 84017, "Gogonash")
    if mod:IsDifficulty("normal10") then
	    ShadowArrow:Start(3)
        Blow:Start(20)
        timerHorror:Start(25)
        crushingblow10:Start(65)
    elseif mod:IsDifficulty("normal25") then
        ShadowArrow:Start(3)
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
	if spellId == 306150 then   -- Стрела тьмы
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
    elseif spellId == 317731 then   -- Омрачающий удар(10)
		Blow:Start()
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

