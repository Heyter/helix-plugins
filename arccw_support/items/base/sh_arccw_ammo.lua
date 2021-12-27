ITEM.name = "Ammo Base"
ITEM.model = "models/Items/BoxSRounds.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.ammo = "pistol" -- type of the ammo
ITEM.ammoAmount = 30 -- amount of the ammo
ITEM.description = "A Box that contains %s of Pistol Ammo"
ITEM.category = "Ammunition"
ITEM.useSound = "items/ammo_pickup.wav"

ITEM.maxRounds = 90 -- макс. патронов помещаемых в одну коробку

function ITEM:GetDescription()
	local rounds = self:GetData("rounds", self.ammoAmount)
	return Format(self.description, rounds)
end

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		draw.SimpleTextOutlined(item:GetData("rounds", item.ammoAmount), "DermaDefault", 1, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
	end
end