local mod	= DBM:NewMod("HRTrash", "DBM-Party-BC", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2250 $"):sub(12, -3))

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

local timerDogs = mod:NewTimer(16, "Dogs", 53186)

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.yellDogs then
		timerDogs:Start()
	end
end
