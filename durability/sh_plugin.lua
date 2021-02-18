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
	['DurabilityUnusableTip'] = 'Ваше оружие теперь полностью сломано!',
	['DurabilityCondition'] = 'Прочность',
	['DurabilityArmorTitle'] = "Защита от",
})

ix.lang.AddTable("english", {
	['RepairKitWrong'] = 'You do not have a repair kit!',
	['DurabilityUnusableTip'] = 'Your weapon is now completely broken!',
	['DurabilityCondition'] = 'Condition',
	['DurabilityArmorTitle'] = "Defence from",
})

if (SERVER) then
	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()
		
			if (IsValid(weapon)) then
				for _, v in pairs(entity:GetCharacter():GetInventory():GetItems()) do
					if (v.class == weapon:GetClass() and v:GetData("equip", false)) then
						local durability = v:GetData("durability", v.maxDurability or ix.config.Get("maxValueDurability", 100))
					
						if (math.random(1, 16) == 2 and durability > 0) then
							durability = math.max(durability - ix.config.Get("decDurability", 1), 0)
							v:SetData("durability", durability)
						end
						
						if (durability < 1 and v.Unequip) then
							v:Unequip(entity, false, true)
							entity:Notify(L('DurabilityUnusableTip'))
						end
						
						bullet.Damage = (bullet.Damage / 100) * durability
						bullet.Spread = bullet.Spread * (1 + (1 - (0.01 * durability)))
						
						durability = nil
						
						break
					end
				end
			end
		end
	end
end

function PLUGIN:PopulateItemTooltip(tooltip, item)
	if (!item.isWeapon) then
		return
	end
	
	local panel = tooltip:AddRowAfter("description", "durabilityPnl")
	local maxDurability = item.maxDurability or ix.config.Get("maxValueDurability", 100)
	local value = math.Clamp(item:GetData("durability", maxDurability), 0, maxDurability)
	
	panel:SetText(Format("%s: %s%% / %s%%", L("DurabilityCondition"), value, maxDurability))
	panel:SetBackgroundColor(Color(219, 52, 52))
	panel:SizeToContents()
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
				
				local durability = math.Clamp(item:GetData("durability", maxDurability) / maxDurability, 0, maxDurability)
				
				if (durability > 0) then
					surface.SetDrawColor(255, 150, 50, 255)
					surface.DrawRect(0, h - 2, w * durability, 2)
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
