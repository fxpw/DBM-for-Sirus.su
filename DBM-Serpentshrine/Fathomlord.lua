local mod	= DBM:NewMod("Fathomlord", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20210130153000")

mod:SetCreatureID(21214)
mod:RegisterCombat("yell", L.YellPull)
mod:SetUsedIcons(4, 5, 6, 7, 8)

mod:RegisterEventsInCombat(
	"CHAT_MSG_MONSTER_EMOTE",
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)


local warnNovaSoon       = mod:NewSoonAnnounce(38445, 3)   -- Огненная звезда
local specWarnNova       = mod:NewSpecialWarningSpell(38445)  -- Огненная звезда

local timerNovaCD        = mod:NewCDTimer(26, 38445, nil, nil, nil, 2)
local timerSpitfireCD    = mod:NewCDTimer(60, 38236, nil, nil, nil, 2)

local berserkTimer          = mod:NewBerserkTimer(600)

------------------------ХМ-------------------------

local warnPhase2Soon		= mod:NewPrePhaseAnnounce(2)
local warnPhase2    		= mod:NewPhaseAnnounce(2)
local warnZeml          	= mod:NewSpellAnnounce(309289, 4)
local warnPhaseCast	        = mod:NewSpellAnnounce(309292, 4)
local warnOko	            = mod:NewSpellAnnounce(309258, 2, nil, "Melee")
local warnStrela            = mod:NewTargetAnnounce(309253, 3) -- Стрела катаклизма
local specWarnStrela	    = mod:NewSpecialWarningYou(309253, nil, nil, nil, 3, 2)
local specWarnHeal			= mod:NewSpecialWarningInterrupt(309256, "HasInterrupt", nil, 2, 1, 2)
local specWarnZeml			= mod:NewSpecialWarningMoveAway(309289, nil, nil, nil, 3, 5)

local timerPhaseCast        = mod:NewCastTimer(60, 309292, nil, nil, nil, 6) -- Скользящий натиск
local timerStrelaCast		= mod:NewCastTimer(6, 309253, nil, nil, nil, 3) -- Стрела катаклизма
local timerStrelaCD			= mod:NewCDTimer(43, 309253, nil, nil, nil, 3) -- Стрела катаклизма
local timerSvazCd			= mod:NewCDTimer(25, 309262, nil, nil, nil, 3)
local timerOkoCD	        = mod:NewCDTimer(16, 309258, nil, "Melee", nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerPhaseCastCD	    = mod:NewCDTimer(90, 309289, nil, nil, nil, 6)
local timerZemlyaCast		= mod:NewCastTimer(5, 309289, nil, nil, nil, 2)
local timerCastHeal	    	= mod:NewCDTimer(29, 309256, nil, "HasInterrupt", nil, 4)
local bers					= mod:NewBerserkTimer(360)
local yellStrela			= mod:NewYell(309253)
-----------Шарккис-----------
local warnSvaz              = mod:NewTargetAnnounce(309262, 3) -- Пламенная связь
local warnPust		        = mod:NewStackAnnounce(309277, 5, nil, "Tank") -- Опустошающее пламя

local specWarnSvaz          = mod:NewSpecialWarningMoveAway(309262, nil, nil, nil, 1, 3) -- Пламенная свзяь

mod:AddBoolOption("HealthFrameBoss", true)
mod:AddSetIconOption("SetIconOnSvazTargets", 309261, true, true, {5, 6, 7})
mod:AddSetIconOption("SetIconOnStrela", 309253, true, false, {8})
mod:AddBoolOption("AnnounceSvaz", false)

local SvazTargets = {}
local SvazIcons = 7

do
	local function sort_by_group(v1, v2)
		return DBM:GetRaidSubgroup(UnitName(v1)) < DBM:GetRaidSubgroup(UnitName(v2))
	end
	function mod:SetSvazIcons()
		table.sort(SvazTargets, sort_by_group)
		for i, v in ipairs(SvazTargets) do
			if mod.Options.AnnounceSvaz then
				if DBM:GetRaidRank() > 0 then
					SendChatMessage(L.SvazIcon:format(SvazIcons, UnitName(v)), "RAID_WARNING")
				else
					SendChatMessage(L.SvazIcon:format(SvazIcons, UnitName(v)), "RAID")
				end
			end
			if self.Options.SetIconOnSvazTargets then
				self:SetIcon(UnitName(v), SvazIcons, 10)
			end
			SvazIcons = SvazIcons - 1
		end
		if #SvazTargets >= 3 then
			warnSvaz:Show(table.concat(SvazTargets, "<, >"))
			table.wipe(SvazTargets)
			SvazIcons = 7
		end
	end
end

function mod:OnCombatStart()
	DBM:FireCustomEvent("DBM_EncounterStart", 21214, "Fathom-Lord Karathress")
	if mod:IsDifficulty("heroic25") then
		self:SetStage(1)
		berserkTimer:Start()
		timerOkoCD:Start()
		timerSvazCd:Start()
		timerCastHeal:Start()
		timerStrelaCD:Start()
		if self.Options.HealthFrameBoss and not self.Options.HealthFrame then
			DBM.BossHealth:Show(L.name)
		end
		if self.Options.HealthFrameBoss then
			DBM.BossHealth:AddBoss(21966, L.Shark)
			DBM.BossHealth:AddBoss(21965, L.Volni)
			DBM.BossHealth:AddBoss(21964, L.Karib)
			DBM.BossHealth:AddBoss(21214, L.Karat)
		end
	else -- Обычка
		berserkTimer:Start()
		timerNovaCD:Start()
		timerSpitfireCD:Start()
		warnNovaSoon:Show(23)
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 21214, "Fathom-Lord Karathress", wipe)
	DBM.BossHealth:Clear()
	DBM.RangeCheck:Hide()
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 38445 then -- Обычка
		warnNovaSoon:Show(23)
		specWarnNova:Show()
		timerNovaCD:Start()
	elseif spellId == 309253 then -- Стрела катаклизма
		local targetname = self:GetBossTarget(21214)
		if not targetname then return end
		if self.Options.SetIconOnStrela then
			self:SetIcon(targetname, 8, 6)
		end
		warnStrela:Show(targetname)
		if targetname == UnitName("player") then
			specWarnStrela:Show()
			yellStrela:Yell()
		end
		timerStrelaCD:Start()
		timerStrelaCast:Start()
	elseif spellId == 309256 then -- Хил
		specWarnHeal:Show()
		specWarnHeal:Play("kickcast")
		timerCastHeal:Start()
	elseif spellId == 309289 then -- Землетрясение
		warnZeml:Show()
		timerZemlyaCast:Start()
		specWarnZeml:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 38236 then -- Обычка
		timerSpitfireCD:Start()
	elseif spellId == 309258 then -- Око
		warnOko:Show()
		timerOkoCD:Start()
	elseif spellId == 309262 then -- Связь
		timerSvazCd:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 309292 then
	timerPhaseCast:Start()
	elseif spellId == 309262 then -- Пламенная связь
		SvazTargets[#SvazTargets + 1] = args.destName
		if args:IsPlayer() then
			specWarnSvaz:Show()
		end
		self:ScheduleMethod(0.1, "SetSvazIcons")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 309252 then --барьер
	    self:SetStage(2)
	    warnPhase2:Show()
		timerPhaseCastCD:Start(95)
		timerCastHeal:Cancel()
		timerOkoCD:Cancel()
		bers:Cancel()
		bers:Start()
	elseif spellId == 309292 then
		timerPhaseCastCD:Start()
	elseif spellId == 309262 and args:IsPlayer() then --Связь
		if self.Options.SetIconOnSvazTargets then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 21966 or cid == 21965 or cid == 21964 then
		if self.Options.HealthFrameBoss then
			DBM.BossHealth:RemoveBoss(cid)
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED