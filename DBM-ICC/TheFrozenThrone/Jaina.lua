local mod	= DBM:NewMod("Jaina", "DBM-Icecrown", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20201020220000")
mod:SetCreatureID(200000)
mod:RegisterCombat("yell", L.YellPull)
mod:SetUsedIcons(2, 3, 4, 5, 6, 7, 8)
mod:SetMinSyncRevision(3392)
--mod:SetModelID(3392)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_MONSTER_YELL"
)


local timerCombatStart		= mod:NewTimer(54, "TimerCombatStart", 2457, nil, nil, 6)
local timerSummonElemenCD	= mod:NewCDTimer(46, 306454, nil, nil, nil, 1, nil, DBM_CORE_TANK_ICON) --1я фаза элементали
local timerArcaneStormCD	= mod:NewCDTimer(72, 306464, nil, nil, nil, 2, nil, DBM_CORE_MAGIC_ICON) --шторм кд
local timerArcaneStorm 		= mod:NewCastTimer(10, 306464, nil, nil, nil, 2, nil, DBM_CORE_MAGIC_ICON) --шторм каст
local timerUnstableMagicCD	= mod:NewCDTimer(22, 306468, nil, nil, nil, 4, nil, DBM_CORE_DISEASE_ICON)--нестабилка коректить
local timerRaysCD	        = mod:NewCDTimer(28, 306485, nil, nil, nil, 2, nil, DBM_CORE_INTERRUPT_ICON) --лучи
local timerMeteorCD	        = mod:NewCDTimer(35, 306491, nil, nil, nil, 2, nil, DBM_CORE_MAGIC_ICON)--метеор
local timerFirewhirlCD	    = mod:NewCDTimer(65, 306495, nil, nil, nil, 3, nil)
local timerCollapse 		= mod:NewCastTimer(20, 306500, nil, nil, nil, 2, nil) --коллапс
local timerPhase2 		    = mod:NewCastTimer(10, 306483, nil, nil, nil, 6, nil) --фаза 2
local timerIceWrathCD       = mod:NewCDTimer(180, 306545, nil, nil, nil, 6, nil, DBM_CORE_MAGIC_ICON) --купол
local timerFreezing 		= mod:NewTimer(6, "TimerFreezing", 306523, nil, nil, 3)
local timerFire  	     	= mod:NewTargetTimer(10, 306504, nil, "Tank", nil, 4, nil, DBM_CORE_TANK_ICON)

local warnNextPhase         = mod:NewAnnounce("WarnNextPhase", 1)
local warnUnstableMagicSoon = mod:NewSoonAnnounce(306468, 2)
local warnArcaneStormSoon   = mod:NewSoonAnnounce(306464, 2)
local warnIceWrath          = mod:NewSoonAnnounce(306549, 4)
local warnFirewhirl         = mod:NewSpellAnnounce(306495, 2)
local warnExplosiveFlame	= mod:NewTargetAnnounce(306487, 4)
local warnWildFlame         = mod:NewTargetAnnounce(306502, 4)
local warnVengefulIce       = mod:NewTargetAnnounce(306535, 4)
local warnIceMark           = mod:NewTargetAnnounce(306523, 4)
local warnStak              = mod:NewStackAnnounce(306455, 4)
local warnFire              = mod:NewStackAnnounce(306504, 3, nil, "Tank")

local specWarnArcaneStorm   = mod:NewSpecialWarningMoveAway(306464, nil, nil, nil, 3, 5) --шторм разбегитесь
local specWarnUnstableMagic = mod:NewSpecialWarningYou(306468, nil, nil, nil, 2, 2) --нестабильная магия
local specWarnRays          = mod:NewSpecialWarningSpell(306485, nil, nil, nil, 2, 2)
local specWarnExplosive     = mod:NewSpecialWarningRun(306487, nil, nil, nil, 4, 5)-- взрывоопасный пламень
local specWarnWildFlame     = mod:NewSpecialWarningMove(306502, nil, nil, nil, 4, 5)--Дикое пламя
local specWarnWildFlameNear = mod:NewSpecialWarning("SpecWarnWildFlameNear", 306545, nil, nil, 1, 2)
local specWarnVengefulIce   = mod:NewSpecialWarningMove(306535, nil, nil, nil, 1, 2)
local specWarnIceWrath      = mod:NewSpecialWarning("SpecWarnIceWrath", nil, nil, nil, 1, 2)
local specWarnIceMark       = mod:NewSpecialWarningRun(306523, nil, nil, nil, 1, 2)
local specWarnIceRush       = mod:NewSpecialWarningMove(306531, "Melee", nil, nil, 1, 2)
local specWarnIceSpears     = mod:NewSpecialWarningSpell(306537, "Ranged", nil, nil, 1, 2)

local berserkTimer			= mod:NewBerserkTimer(1802)

mod:AddSetIconOption("SetIconOnExplosiveTargets", 306487, true, true, {3, 4, 5, 6, 7, 8})
mod:AddBoolOption("AnnounceExplosive", false)
mod:AddBoolOption("RangeFrame")
--mod:AddBoolOption("Knop")

mod.vb.phase = 1
local ExplosiveTargets = {}
local ExplosiveIcons = 8
local wildFlameTargets = {}
local vengerfulIceTargets = {}
local iceMarkTargets = {}

function mod:OnCombat()
	self.vb.phase = 1
	ExplosiveIcons = 8
	berserkTimer:Start()
	timerSummonElemenCD:Start(27)
	timerArcaneStormCD:Start(74)
	timerUnstableMagicCD:Start(26)
	warnArcaneStormSoon:Schedule(71)
	warnUnstableMagicSoon:Schedule(23)
end

function mod:WildFlame()
	warnWildFlame:Show(table.concat(wildFlameTargets, "<, >"))
	table.wipe(wildFlameTargets)
end

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetExplosiveIcons()
		table.sort(ExplosiveTargets, sort_by_group)
		for i, v in ipairs(ExplosiveTargets) do
			if mod.Options.AnnounceExplosive then
				if DBM:GetRaidRank() > 0 then
					SendChatMessage(L.ExplosiveIcon:format(ExplosiveIcons, UnitName(v)), "RAID_WARNING")
				else
					SendChatMessage(L.ExplosiveIcon:format(ExplosiveIcons, UnitName(v)), "RAID")
				end
			end
			if self.Options.SetIconOnExplosiveTargets then
				self:SetIcon(UnitName(v), ExplosiveIcons, 6)
			end
			ExplosiveIcons = ExplosiveIcons - 1
		end
		if #ExplosiveTargets >= 6 then
			warnExplosiveFlame:Show(table.concat(ExplosiveTargets, "<, >"))
			table.wipe(ExplosiveTargets)
			ExplosiveIcons = 8
		end
	end
end


function mod:SPELL_CAST_START(args)
	if args:IsSpellID(306464) then
		specWarnArcaneStorm:Show() -- Шторм
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(10)
			self:ScheduleMethod(11, "Range")
		end
	elseif args:IsSpellID(306468) then
		specWarnUnstableMagic:Show()
		timerUnstableMagicCD:Start()
		warnUnstableMagicSoon:Schedule(21)
	elseif args:IsSpellID(306454) then
		timerSummonElemenCD:Start()
	elseif args:IsSpellID(306483) then  -- Phase 2
		warnNextPhase:Show(2 .. ": " .. args.spellName)
		self.vb.phase = 2
		timerArcaneStormCD:Cancel()
		timerUnstableMagicCD:Cancel()
		warnArcaneStormSoon:Cancel()
		warnUnstableMagicSoon:Cancel()
		timerRaysCD:Start(17)
		timerMeteorCD:Start(29)
		timerFirewhirlCD:Start(60)
		timerPhase2:Start()
		--[[if self.Options.Knop then
			self:ScheduleMethod(1, "Timer")
		end]]
	elseif args:IsSpellID(306485) then
		timerRaysCD:Start()
		specWarnRays:Show()
	elseif args:IsSpellID(306491) then
		timerMeteorCD:Start() -- Метеор
	elseif args:IsSpellID(306531) then
		specWarnIceRush:Show() -- Натиск
	elseif args:IsSpellID(306545) then  -- Dome phase
		specWarnIceWrath:Show()
	end
end

function mod:Range()
	DBM.RangeCheck:Hide()
end

--[[function mod:Timer()
	SendChatMessage(L.Knop, "SAY")
end]]

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(306464) then
		timerArcaneStorm:Start()
		timerSummonElemenCD:Start(11)
	elseif args:IsSpellID(306495) then
		timerFirewhirlCD:Schedule(20)
		timerCollapse:Start()
		warnFirewhirl:Show()
		if timerRaysCD:GetTime() > 0 then
			timerRaysCD:Update(select(1, timerRaysCD:GetTime()), select(2, timerRaysCD:GetTime()) + 20)
		else
			timerRaysCD:Start(20)
		end
		if timerMeteorCD:GetTime() > 0 then
			timerMeteorCD:Update(select(1, timerMeteorCD:GetTime()), select(2, timerMeteorCD:GetTime()) + 20)
		else
			timerMeteorCD:Start(20)
		end
	elseif args:IsSpellID(306487) then
		ExplosiveTargets[#ExplosiveTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnExplosive:Show()
		end
		self:ScheduleMethod(0.1, "SetExplosiveIcons")
	elseif args:IsSpellID(306502) then -- дикое пламя
		if args:IsPlayer() then
			specWarnWildFlame:Show()
		else
			local uId = DBM:GetRaidUnitId(args.destName)
			if uId then
				local inRange = CheckInteractDistance(uId, 3)
				local x, y = GetPlayerMapPosition(uId)
				if x == 0 and y == 0 then
					SetMapToCurrentZone()
					x, y = GetPlayerMapPosition(uId)
				end
				if inRange then
					specWarnWildFlameNear:Show()
				end
			end
		end
		wildFlameTargets[#wildFlameTargets + 1] = args.destName
		self:UnscheduleMethod("WildFlame")
		self:ScheduleMethod(0.1, "WildFlame")
	elseif args:IsSpellID(306535) then
		vengerfulIceTargets[#vengerfulIceTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnVengefulIce:Show()
		end
		if #vengerfulIceTargets >= 2 then
			warnVengefulIce:Show(table.concat(vengerfulIceTargets, "<, >"))
			table.wipe(vengerfulIceTargets)
		end
	elseif args:IsSpellID(306523, 306524) then
		iceMarkTargets[#iceMarkTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnIceMark:Show()
		end
		if #iceMarkTargets >= 6 then
			warnIceMark:Show(table.concat(iceMarkTargets, "<, >"))
			table.wipe(iceMarkTargets)
		end
		timerFreezing:Start()
	elseif args:IsSpellID(306455) then -- Стаки на 1 фазе
		warnStak:Show(args.destName, args.amount or 1)
	elseif args:IsSpellID(306504) then -- Стаки на танке
		warnFire:Show(args.destName, args.amount or 1)
		timerFire:Start(args.destName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(306516) then  -- Phase 3
		warnNextPhase:Show(3 .. ": " .. L.blackIce)
		self.vb.phase = 3
		timerRaysCD:Cancel()
		timerMeteorCD:Cancel()
		timerFirewhirlCD:Cancel()
		timerIceWrathCD:Start(135)
		self:NewCDTimer(120, 306545)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(306464) then
		timerArcaneStormCD:Start()
		warnArcaneStormSoon:Schedule(68)
	elseif args:IsSpellID(306549) then
		timerIceWrathCD:Start()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellStart then
		self:ScheduleMethod(54, "OnCombat")
		timerCombatStart:Start()
	end
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 3392, "Lady Jaina Proudmoore")
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 3392, "Lady Jaina Proudmoore", wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED