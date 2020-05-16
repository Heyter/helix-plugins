PLUGIN.name = "Durability - helix"
PLUGIN.author = "AleXXX_007 ; Hikka"
PLUGIN.desc = "Adds durability for all weapons."

PLUGIN.maxValue_durability = 100

ix.lang.AddTable("russian", {
 	['Repair'] = "Починить",
	['RepairKitWrong'] = 'У вас нет профессионального набора для ремонта оружия',
	['DurabilityUnusableTip'] = 'Оружие пришло в негодность!',
	['DurabilityCondition'] = 'Состояние',
})

ix.lang.AddTable("english", {
	['RepairKitWrong'] = 'You do not have a professional weapon repair kit',
	['DurabilityUnusableTip'] = 'Weapons become unusable!',
	['DurabilityCondition'] = 'Condition',
})

if (SERVER) then
	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()
		
			if (weapon) then
				local inventory = entity:GetCharacter():GetInventory():GetItems()
				for k, v in pairs(inventory) do
					if v.class == weapon:GetClass() and v:GetData("equip", false) == true then
						local durability = v:GetData("durability", self.maxValue_durability)
					
						if math.random(1, 16) == 1 and durability > 0 then
							v:SetData("durability", durability - 1)
						end
						
						if durability < 1 then
							entity:Notify(L('DurabilityUnusableTip'))
							v:SetData("equip", nil)
							entity.carryWeapons = entity.carryWeapons or {}

							local weapon = entity.carryWeapons[v.weaponCategory]
							if (!IsValid(weapon)) then
								weapon = entity:GetWeapon(v.class)
							end
		
							if (IsValid(weapon)) then
								v:SetData("ammo", weapon:Clip1())

								entity:StripWeapon(v.class)
								entity.carryWeapons[v.weaponCategory] = nil
								entity:EmitSound("items/ammo_pickup.wav", 80)
								
								v:RemovePAC(entity)
							end
						end
						
						bullet.Damage = (bullet.Damage / 100) * durability
						bullet.Spread = bullet.Spread * (1 + (1 - ((1 / 100) * durability)))
						
						durability = nil
					end
				end
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	local max = self.maxValue_durability
	
	for k, v in pairs(ix.item.list) do
		if not v.isWeapon then continue end
	
		if CLIENT then
			function v:PaintOver(item, w, h)
				if (item:GetData("equip")) then
					surface.SetDrawColor(110, 255, 110, 100)
					surface.DrawRect(w - 14, h - 14, 8, 8)
				end
				
				local durability = math.Clamp(item:GetData("durability", max) / max, 0, max)
				
				if durability > 0 then
					surface.SetDrawColor(255, 150, 50, 255)
					surface.DrawRect(0, h - 2, w * durability, 2)
				end
			end
			
			function v:GetDescription()
				local desc = L(self.description or "noDesc")
				desc = desc .. "\n[*] "..L("DurabilityCondition")..": " .. self:GetData("durability", max) .. "/" .. max
				return desc
			end
		end
		
		v.functions.Repair = {
			name = "Repair",
			tip = "equipTip",
			icon = "icon16/bullet_wrench.png",
			OnRun = function(item)
				local client = item.player
				local has_remnabor = client:GetCharacter():GetInventory():HasItem("remnabor_weapon")
				
				if has_remnabor then
					has_remnabor:Remove()
					item:SetData("durability", math.Clamp(item:GetData("durability", max) + 25, 0, max))
					client:EmitSound("interface/inv_repair_kit.ogg", 80)
				else
					client:Notify(L("RepairKitWrong"))
				end	

				has_remnabor = nil
				
				return false
			end,
			
			OnCanRun = function(item)
				if item:GetData("durability", max) >= max then return false end
				
				if not item.player:GetCharacter():GetInventory():HasItem("remnabor_weapon") then
					return false
				end
				
				return true
			end
		}
	end
end

function PLUGIN:CanPlayerEquipItem(client, item)
	return item:GetData("durability", self.maxValue_durability) > 0
end