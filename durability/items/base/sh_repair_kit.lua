ITEM.name = "Repair Kit Base"
ITEM.category = "RepairKit"
ITEM.description = "The repair kit repairs %s%% of the durability."
ITEM.model = "models/props_lab/box01a.mdl"
ITEM.useSound = "interface/inv_repair_kit.ogg"
ITEM.width = 1
ITEM.height = 1

-- Percentage of the difference between maximum and current durability. See in ITEM:UseRepair
ITEM.durability = 25

-- How many times can an item be used before it is removed?
ITEM.quantity = 1

-- Only allowed for weapons.
ITEM.isWeaponKit = true

if (SERVER) then
	-- You can override this method in your item.
	-- item: The current used item.
	function ITEM:UseRepair(item, client)
		local maxDurability = item.maxDurability or ix.config.Get("maxValueDurability", 100)
		local durability = item:GetData("durability", maxDurability)
		local amount = math.max(0, (self.durability / 100) * (maxDurability - durability))

		item:SetData("durability", math.Clamp(math.floor(durability + amount), 0, maxDurability))
	end
end

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		local quantity = item:GetData("quantity", item.quantity or 1)

		if (quantity > 0) then
			draw.SimpleText(quantity, "DermaDefault", w - 5, h - 5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black)
		end
	end

	function ITEM:GetDescription()
		return Format(self.description, self.durability)
	end
end

function ITEM:OnInstanced(invID, x, y, item)
	item:SetData("quantity", item.quantity or 1)
end
