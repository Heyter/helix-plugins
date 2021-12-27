ITEM.base = "base_weapons"

ITEM.name = "ArcCW Weapon"
ITEM.category = "ArcCW Weapons"
ITEM.weaponCategory = "primary"
ITEM.attachments = {}
ITEM.isArcCW = true
ITEM.ammo = nil -- type of the ammo

if (CLIENT) then
	function ITEM:PaintOver(itemObj, w, h)
		local x, y = w - 14, h - 14

		if (itemObj:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(x, y, 8, 8)

			x = x - 8 * 1.6
		end

		if (!table.IsEmpty(itemObj:GetData("mods", {}))) then
			surface.SetDrawColor(255, 255, 110, 100)
			surface.DrawRect(x, y, 8, 8)
		end

		draw.SimpleTextOutlined(itemObj:GetData("ammo", 0), "DermaDefault", 1, 5, Color(252, 177, 3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
	end

	function ITEM:PopulateTooltip(tooltip)
		if (self:GetData("equip")) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end

		if (self.attachments and !table.IsEmpty(self.attachments)) then
			local mods = self:GetData("mods", {})

			if (!table.IsEmpty(mods)) then
				local text = {}
				local item

				for _, itemID in pairs(mods) do
					item = ix.item.list[itemID]

					text[#text + 1] = (item and item.name) or itemID
				end

				text = table.concat(text, " + ")

				if (isstring(text)) then
					local row = tooltip:AddRowAfter("description", "ArcCWMods")
					row:SetText(text)
					row:SetBackgroundColor(derma.GetColor("Warning", tooltip))
					row:SizeToContents()
				end
			end
		end
	end
else
	function ITEM:Equip(client, bNoSelect, bNoSound)
		local items = client:GetCharacter():GetInventory():GetItems(true)

		client.carryWeapons = client.carryWeapons or {}

		local equippedItem
		for _, v in pairs(items) do
			if (v.id != self.id and v.isWeapon and client.carryWeapons[self.weaponCategory] and v:GetData("equip")) then
				equippedItem = v
				break
			end
		end

		if (equippedItem) then
			equippedItem:Unequip(client)

			if (equippedItem:GetData("equip")) then
				client:NotifyLocalized("weaponSlotFilled", self.weaponCategory)
				return false
			end
		end

		if (client:HasWeapon(self.class)) then
			client:StripWeapon(self.class)
		end

		local weapon = client:Give(self.class, !self.isGrenade)

		if (IsValid(weapon)) then
			local ammoType = weapon:GetPrimaryAmmoType()

			client.carryWeapons[self.weaponCategory] = weapon

			if (!bNoSelect) then
				client:SelectWeapon(weapon:GetClass())
			end

			if (!bNoSound) then
				client:EmitSound(self.useSound, 80)
			end

			-- Remove default given ammo.
			if (client:GetAmmoCount(ammoType) == weapon:Clip1() and self:GetData("ammo", 0) == 0) then
				client:RemoveAmmo(weapon:Clip1(), ammoType)
			end

			-- assume that a weapon with -1 clip1 and clip2 would be a throwable (i.e hl2 grenade)
			-- TODO: figure out if this interferes with any other weapons
			if (weapon:GetMaxClip1() == -1 and weapon:GetMaxClip2() == -1 and client:GetAmmoCount(ammoType) == 0) then
				client:SetAmmo(1, ammoType)
			end

			self:SetData("equip", true)

			if (self.isGrenade) then
				weapon:SetClip1(1)
				client:SetAmmo(0, ammoType)
			else
				weapon:SetClip1(self:GetData("ammo", 0))
			end

			weapon.ixItem = self

			if (self.OnEquipWeapon) then
				self:OnEquipWeapon(client, weapon)
			end
		else
			print(Format("[Helix] Cannot equip weapon - %s does not exist!", self.class))
		end
	end
end

ITEM.functions.Detach = {
	name = "Detach",
	icon = "icon16/wrench.png",
	isMulti = true,
	multiOptions = function(item)
		local targets = {}
		local targetItem

		for _, attItemID in pairs(item:GetData("mods", {})) do
			targetItem = ix.item.list[attItemID]

			targets[#targets + 1] = {
				name = (targetItem and targetItem.name) or attItemID,
				data = { attItemID }
			}
		end

		return targets
	end,

	OnCanRun = function(item)
		return (
			!IsValid(item.entity) and
			IsValid(item.player) and
			item.invID == item.player:GetCharacter():GetInventory():GetID() and
			!table.IsEmpty(item:GetData("mods", {}))
		)
	end,

	OnRun = function(item, data)
		if (!istable(data) or !data[1]) then return false end
		if (!ix.item.list[data[1]]) then return false end

		ix.arccw_support.Detach(item, data[1])
		return false
	end
}

hook.Add("PlayerDeath", "ixStripClip", function(client)
	client.carryWeapons = {}
	local weapon

	for _, v in pairs(client:GetCharacter():GetInventory():GetItems()) do
		if (v.isWeapon and v:GetData("equip")) then
			weapon = client:GetWeapon(v.class)

			if (IsValid(weapon) and weapon:Clip1() > 0) then
				v:SetData("ammo", weapon:Clip1(), false)
			else
				v:SetData("ammo", nil, false)
			end

			v:SetData("equip", nil, false)

			if (v.pacData) then
				v:RemovePAC(client)
			end
		end
	end
end)