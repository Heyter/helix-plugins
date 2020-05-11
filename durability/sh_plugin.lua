PLUGIN.name = "Durability - helix"
PLUGIN.author = "AleXXX_007"
PLUGIN.desc = "Adds durability for all weapons."

if (SERVER) then
	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()
		
			if (weapon) then
				local inventory = entity:GetCharacter():GetInventory():GetItems()
				for k, v in pairs(inventory) do
					if v.class == weapon:GetClass() and v:GetData("equip", false) == true then
						local durability = v:GetData("durability", 100)
					
						local chance = math.random(1, 16)
						if chance == 1 and durability > 0 then
							v:SetData("durability", durability - 1)
						elseif chance == 1 and durability == 0 then
							entity:Notify("Оружие пришло в негодность!")
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
						
						chance = nil
						
						bullet.Damage = (bullet.Damage / 100) * durability
						bullet.Spread = bullet.Spread * (1 + (1 - ((1 / 100) * durability)))
						
						durability = nil
					end
				end
			end
		end
	end
end