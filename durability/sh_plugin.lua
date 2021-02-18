PLUGIN.name = "Durability"
PLUGIN.author = "AleXXX_007 ; Hikka"
PLUGIN.description = "Adds durability for all weapons."

ix.config.Add("maxValueDurability", 100, "Maximum value of the durability.", nil, {
	data = {min = 1, max = 9999},
	category = PLUGIN.name
})

ix.config.Add("decDurability", 1, "By how many units do reduce the durability with each shot?", nil, {
	data = {min = 0.0001, max = 100},
	category = PLUGIN.name
})

ix.lang.AddTable("russian", {
 	['Repair'] = "Починить",
	['RepairKitWrong'] = 'У вас нет ремкомплекта!',
	['DurabilityUnusableTip'] = 'Оружие теперь полностью сломано!',
	['DurabilityText'] = 'Прочность',
})

ix.lang.AddTable("english", {
	['RepairKitWrong'] = 'You do not have a repair kit!',
	['DurabilityUnusableTip'] = 'Your weapon is now completely broken!',
	['DurabilityText'] = 'Durability',
})

if (SERVER) then
	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()
		
			if (IsValid(weapon) and weapon.ixItem) then
				local item = weapon.ixItem
				
				if (item.class == weapon:GetClass() and item:GetData("equip", false)) then
					local durability = item:GetData("durability", item.maxDurability or ix.config.Get("maxValueDurability", 100))
					
					bullet.Damage = (bullet.Damage / 100) * durability
					bullet.Spread = bullet.Spread * (1 + (1 - (0.01 * durability)))
				
					durability = math.max(durability - ix.config.Get("decDurability", 1), 0)
					item:SetData("durability", durability)
					
					if (durability < 1 and item.Unequip) then
						item:Unequip(entity)
						entity:Notify(L('DurabilityUnusableTip'))
					end
				end
			end
		end
	end
else
	function PLUGIN:PopulateItemTooltip(tooltip, item)
		if (!item.isWeapon) then
			return
		end

		local panel = tooltip:AddRowAfter("description", "durability")
		local maxDurability = item.maxDurability or ix.config.Get("maxValueDurability", 100)
		local durability = math.Clamp(math.floor(item:GetData("durability", maxDurability)), 0, maxDurability)

		panel:SetText(Format("%s: %s%% / %s%%", L("DurabilityText"), durability, maxDurability))
		panel:SetBackgroundColor(Color(219, 52, 52))
		panel:SizeToContents()
	end
end

function PLUGIN:InitializedPlugins()
	local maxDurability = ix.config.Get("maxValueDurability", 100)

	for _, v in pairs(ix.item.list) do
		if (!v.isWeapon) then continue end
		
		maxDurability = v.maxDurability or maxDurability
	
		if CLIENT then
			function v:PaintOver(item, w, h)
				if (item:GetData("equip")) then
					surface.SetDrawColor(110, 255, 110, 100)
					surface.DrawRect(w - 14, h - 14, 8, 8)
				end
				
				local durability = item:GetData("durability", maxDurability)
				local durabilityDecimal = math.Clamp(durability / maxDurability, 0, maxDurability)
				
				if (durabilityDecimal > 0) then
					-- 2.55 = (255 / 100)
					local durabilityColor = Color(2.55 * (100 - durability), 2.55 * durability, 0, 255)
					
					surface.SetDrawColor(durabilityColor)
					surface.DrawRect(0, h - 2, w * durabilityDecimal, 2)
				end
			end
		end
		
		v.functions.Repair = {
			name = "Repair",
			tip = "equipTip",
			icon = "icon16/bullet_wrench.png",
			OnRun = function(item)
				local client = item.player
				local itemKit = client:GetCharacter():GetInventory():HasItemOfBase("base_repair_kit")
				
				if (itemKit and itemKit.isWeaponKit) then
					local quantity = itemKit:GetData("quantity", itemKit.quantity or 1) - 1
					
					if (quantity < 1) then
						itemKit:Remove()
					else
						itemKit:SetData("quantity", quantity)
					end
					
					item:SetData("durability", math.Clamp(item:GetData("durability", maxDurability) + itemKit.durability, 0, maxDurability))
					client:EmitSound(itemKit.useSound, 110)
					
					itemKit = nil
				else
					client:Notify(L("RepairKitWrong"))
				end	
				
				return false
			end,
			
			OnCanRun = function(item)
				if (item:GetData("durability", maxDurability) >= maxDurability) then
					return false
				end
				
				if (!item.player:GetCharacter():GetInventory():HasItemOfBase("base_repair_kit")) then
					return false
				end
				
				return true
			end
		}
	end
end

function PLUGIN:CanPlayerEquipItem(_, itemObj)
	return itemObj:GetData("durability", ix.config.Get("maxValueDurability", 100)) > 0
end