local mod	= DBM:NewMod("TheMaker", "DBM-Party-BC", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2250 $"):sub(12, -3))
mod:SetCreatureID(17381)
mod:SetZone()

mod:RegisterCombat("combat", 17381)

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS"
)

local timerBomb		= mod:NewCDTimer(10, 30925)
local timerSpray	= mod:NewCDTimer(20, 38153)
local timerMight	= mod:NewCDTimer(26, 30923)
local warnMight		= mod:NewTargetAnnounce(30923, 4)

local dominateMindTargets	= {}
local dominateMindIcon = 6

mod:AddSetIconOption("SetIconOnDominateMind", 30923, true, true, {6})
mod:AddBoolOption("RemoveWeaponOnMindControl", true)


function mod:OnCombatStart(delay)
	timerBomb:Start(5)
	timerSpray:Start(25)
	timerMight:Start(22)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(30923) then
		if args:IsPlayer() and self.Options.RemoveWeaponOnMindControl then
			if self:IsWeaponDependent("player") then
				PickupInventoryItem(16)
				PutItemInBackpack()
				PickupInventoryItem(17)
				PutItemInBackpack()
			elseif select(2, UnitClass("player")) == "HUNTER" then
				PickupInventoryItem(18)
				PutItemInBackpack()
			end
		end
		dominateMindTargets[#dominateMindTargets + 1] = args.destName
		if self.Options.SetIconOnDominateMind then
			self:SetIcon(args.destName, dominateMindIcon, 12)
			dominateMindIcon = dominateMindIcon - 1
		end
	end
		if args:IsSpellID(30925) then
			timerBomb:Start()
		elseif args:IsSpellID(38153) and args.sourceName == L.name then
			timerBomb:Start()
			timerSpray:Start()
		elseif args:IsSpellID(30923) and args.sourceName == L.name then
			timerMight:Start()
			warnMight:Show(args.destName)
		end
end