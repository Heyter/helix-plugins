ITEM.base = "base_weapons"

ITEM.name = "ArcCW Grenade"
ITEM.category = "ArcCW Grenades"
ITEM.weaponCategory = "grenade"

ITEM.isArcCW = true
ITEM.isArcCWGrenade = true
ITEM.isGrenade = true
ITEM.isWeapon = true

if (CLIENT) then
	function ITEM:PaintOver(itemObj, w, h)
		local x, y = w - 14, h - 14

		if (itemObj:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(x, y, 8, 8)

			x = x - 8 * 1.6
		end
	end

	function ITEM:PopulateTooltip(tooltip)
		if (self:GetData("equip")) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end
	end
end