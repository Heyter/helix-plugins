PLUGIN.name = "Unload mags"
PLUGIN.author = "STEAM_0:1:29606990"
PLUGIN.desc = "Unload mags for weapons."

ix.lang.AddTable("russian", {
 	['Unload mags'] = "Разгрузить обойму"
})

local cache_ammo = {}

function PLUGIN:InitializedPlugins()
	for k, v in pairs(ix.item.list) do
		if v.ammo and v.ammoAmount then
			-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
			v.functions.use = { -- sorry, for name order.
				name = "Load",
				tip = "useTip",
				icon = "icon16/add.png",
				OnRun = function(item)
					local ammo = item:GetData('mags_ammo', item.ammoAmount)
					if ammo < 1 then
						return true
					end
					
					item.player:GiveAmmo(ammo, item.ammo)
					item.player:EmitSound("items/ammo_pickup.wav", 110)
					ammo = nil

					return true
				end,
			}
			
			function v:OnInstanced(invID, x, y, item)
				if item.data and item.data.mags_ammo then
					item:SetData('mags_ammo', item.data.mags_ammo)
				end
			end

			if CLIENT then
				function v:PaintOver(item, w, h)
					draw.SimpleText(item:GetData('mags_ammo', item.ammoAmount), "DermaDefault",w - 5, h - 5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black)
				end

				function v:GetDescription()
					return Format(self.description, self:GetData('mags_ammo', self.ammoAmount))
				end
			end
		elseif v.isWeapon and not v.isGrenade then
			v.functions.unloadAmmo = {
				name = "Unload mags",
				tip = "unloadAmmoTip",
				icon = "icon16/bullet_wrench.png",
				OnRun = function(item)
					local client = item.player
					client.carryWeapons = client.carryWeapons or {}
					
					local weapon = client.carryWeapons[item.weaponCategory]
					if (!IsValid(weapon)) then
						weapon = client:GetWeapon(item.class)
					end

					if (IsValid(weapon) and weapon:Clip1() > 0) then					
						local char = client:GetCharacter()
						if not char then return false end
						
						local itemID = item.AmmoID
						
						if not itemID then
							local ammoName = game.GetAmmoName(weapon:GetPrimaryAmmoType())
							if not ammoName or ammoName == "" then return false end
							
							itemID = cache_ammo[ammoName]
							
							if not itemID then
								for k, v in pairs(ix.item.list) do
									if not v.ammo then continue end
									if v.ammo:lower() == ammoName:lower() then
										itemID = k
										cache_ammo[ammoName] = itemID
										break
									end
								end
							end
							
							ammoName = nil
						end
						
						if itemID then
							item:SetData('ammo', nil)
							local ammo = weapon:Clip1()
							weapon:SetClip1(0)
							
							local tbl = {mags_ammo = ammo}
							if (!char:GetInventory():Add(itemID, nil, tbl)) then
								ix.item.Spawn(itemID, client, nil, nil, tbl)
							end
							
							tbl, ammo, itemID = nil, nil, nil
						end

						char = nil
					end
					
					weapon, client = nil, nil
					
					return false
				end,
				OnCanRun = function(item)
					local client = item.player
					client.carryWeapons = client.carryWeapons or {}
					
					local weapon = client.carryWeapons[item.weaponCategory]
					if (!IsValid(weapon)) then
						weapon = client:GetWeapon(item.class)
					end
					
					return not IsValid(item.entity) and IsValid(client) and item:GetData("equip") == true and item.invID == client:GetCharacter():GetInventory():GetID()
						and item.isWeapon and not item.isGrenade and IsValid(weapon) and weapon:Clip1() > 0
				end
			}
		end
	end
end
