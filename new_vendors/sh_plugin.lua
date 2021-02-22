local PLUGIN = PLUGIN

PLUGIN.name = "RE:Vendors"
PLUGIN.author = "STEAM_0:1:29606990" -- Chessnut original code
PLUGIN.description = "Adds NPC vendors that can sell things."

ix.lang.AddTable("russian", {
 	['vendorTitleInvSize'] = "Размер инвентаря",
	['vendorSlideWInvSize'] = "Ширина",
	['vendorSlideHInvSize'] = "Высота",
	['vendorResizeBtnInvSize'] = "Изменить размер",
	['vendorRemoveItemEditor'] = "Удалить",
	['vendorMaxStock'] = "У данного продавца полный запас этого товара!"
})

ix.lang.AddTable("english", {
 	['vendorTitleInvSize'] = "Inventory size",
	['vendorSlideWInvSize'] = "Width",
	['vendorSlideHInvSize'] = "Height",
	['vendorResizeBtnInvSize'] = "Resize",
	['vendorRemoveItemEditor'] = "Remove item",
	['vendorMaxStock'] = "This vendor has full stock of that item!"
})

CAMI.RegisterPrivilege({
	Name = "Helix - Manage Vendors",
	MinAccess = "admin"
})

VENDOR = {
	SELLANDBUY = 1, -- Sell and buy the item.
	SELLONLY = 2, -- Only sell the item to the player.
	BUYONLY = 3, -- Only buy the item from the player.
	PRICE = 1,
	STOCK = 2,
	MODE = 3,
	MAXSTOCK = 4,
	NOTRADE = 3,
	WELCOME = 1
}

if CLIENT then
	local stockPnl, pricePnl = nil, nil
	local intPriceVendor = 0
	function PLUGIN:PopulateItemTooltip( tooltip, item )
		if not item.invID then
			return
		end
		
		local panel = ix.gui.vendorRemake
		if (IsValid(panel)) then
			local entity = panel.entity
			if IsValid(entity) and entity.items[item.uniqueID] then
				local info = entity.items[item.uniqueID]
				if not info then
					return
				end
				
				local inventory = ix.inventory.Get(item.invID)
				
				if inventory and inventory.slots and inventory.vars then
					intPriceVendor = entity:GetPrice(item.uniqueID, not inventory.vars.isNewVendor)
					intPriceVendor = ix.currency.Get(intPriceVendor)
					
					pricePnl = tooltip:AddRowAfter("name", "priceVendor")
					
					if inventory.vars.isNewVendor then
						pricePnl:SetText(L"purchase".." ("..intPriceVendor..")")
					else
					-- elseif not inventory.vars.isNewVendor and IsValid(ix.gui.inv1) and not IsValid(ix.gui.menu) then
						pricePnl:SetText(L"sell".." ("..intPriceVendor..")")
					end
					pricePnl:SetBackgroundColor(derma.GetColor("Warning", panel))
					pricePnl:SizeToContents()
					
					if (inventory.vars.isNewVendor and info[VENDOR.MAXSTOCK]) then
						if IsValid(pricePnl) then
							stockPnl = tooltip:AddRowAfter("priceVendor", "stockVendor")
						else
							stockPnl = tooltip:AddRowAfter("name", "stockVendor")
						end
						
						stockPnl:SetText(string.format("%s: %d/%d", L'stock', info[VENDOR.STOCK], info[VENDOR.MAXSTOCK]))
						stockPnl:SetBackgroundColor(derma.GetColor("Error", panel))
						stockPnl:SizeToContents()
					end
				end
			end
		end
	end
	
	function PLUGIN:SendTradeToVendor(itemObject, isSellingToVendor)
		if (not IsValid(ix.gui.vendorRemake) or not itemObject.id) then
			return
		end
		
		local entity = ix.gui.vendorRemake.entity
		
		if (not entity.items[itemObject.uniqueID]) then
			return
		end
		
		net.Start("ixVendorRemakeTrade")
			net.WriteUInt(itemObject.id, 32)
			net.WriteBool(isSellingToVendor)
		net.SendToServer()
	end
	
	function PLUGIN:InventoryItemOnDrop(itemObject, curInv, newInventory)
		if curInv and newInventory then
			if (newInventory.vars and newInventory.vars.isNewVendor and curInv.slots) or (curInv.vars and curInv.vars.isNewVendor and newInventory.slots) then
				if (newInventory == curInv) then
					return
				end
				
				if IsValid(ix.gui.vendorRemake) and not IsValid(ix.gui.vendorRemakeEditor) then -- sell / purchase that item
					local entity = ix.gui.vendorRemake.entity
					if (not entity.items[itemObject.uniqueID]) then
						return
					end
					
					if curInv.vars.isNewVendor then -- purchase item to vendor
						self:SendTradeToVendor(itemObject, false)
					elseif newInventory.vars.isNewVendor then -- sell item to vendor
						self:SendTradeToVendor(itemObject, true)
					end
				end
			end
		end
	end
end

function PLUGIN:CanTransferItem(itemObject, curInv, newInventory)
	if curInv and newInventory then
		if (newInventory.vars and newInventory.vars.isNewVendor) or (curInv.vars and curInv.vars.isNewVendor) then
			if curInv:GetID() == 0 then
				return true -- META:Add()
			end

			return false
		end
	end
end

if (SERVER) then	
	util.AddNetworkString("ixVendorRemakeOpen")
	util.AddNetworkString("ixVendorRemakeClose")
	util.AddNetworkString("ixVendorRemakeEditor")
	util.AddNetworkString("ixVendorRemakeEditFinish")
	util.AddNetworkString("ixVendorRemakeEdit")
	util.AddNetworkString("ixVendorRemakeTrade")
	util.AddNetworkString("ixVendorRemakeStock")
	util.AddNetworkString("ixVendorRemakeMoney")
	
	ix.log.AddType("vendorCharacterTraded", function(client, ...)
		local arg = {...}
		return string.format("%s %s '%s' to the vendor '%s'.", client:Name(), arg[3] == true and "selling" or "purchased", arg[2], arg[1])
	end)
	
	ix.log.AddType("vendorRemakeUse", function(client, ...)
		local arg = {...}
		return string.format("%s used the '%s' vendor.", client:Name(), arg[1])
	end)

	function PLUGIN:SaveData()
		local data = {}

		for _, entity in ipairs(ents.FindByClass("ix_vendor_new")) do
			local inventory = entity:GetInventory()

			if (inventory) then
				local bodygroups = {}

				for _, v in ipairs(entity:GetBodyGroups() or {}) do
					bodygroups[v.id] = entity:GetBodygroup(v.id)
				end
			
				data[#data + 1] = {
					name = entity:GetDisplayName(),
					description = entity:GetDescription(),
					pos = entity:GetPos(),
					angles = entity:GetAngles(),
					model = entity:GetModel(),
					skin = entity:GetSkin(),
					bodygroups = bodygroups,
					bubble = entity:GetNoBubble(),
					inventory_id = inventory:GetID(),
					items = entity.items,
					factions = entity.factions,
					classes = entity.classes,
					money = entity.money,
					scale = entity.scale,
					inventory_size = {w = entity.inventory_size.w or 1, h = entity.inventory_size.h or 1},
				}
			end
		end
		
		self:SetData(data)
	end
	
	function PLUGIN:CharacterVendorTraded(client, vendor, uniqueID, isSellingToVendor)		
		ix.log.Add(client, "vendorCharacterTraded", vendor:GetDisplayName(), uniqueID, isSellingToVendor)
	end

	function PLUGIN:VendorRemakeRemoved(entity, inventory)
		self:SaveData()
	end

	function PLUGIN:LoadData()
		for _, v in ipairs(self:GetData() or {}) do
			local inventoryID = tonumber(v.inventory_id)

			if (!inventoryID or inventoryID < 1) then
				ErrorNoHalt(string.format("[Helix] Attempted to restore container inventory with invalid inventory ID '%s'\n", tostring(inventoryID)))
				continue
			end

			local entity = ents.Create("ix_vendor_new")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()
			
			entity:SetModel(v.model)
			entity:SetSkin(v.skin or 0)
			entity:SetSolid(SOLID_BBOX)
			entity:PhysicsInit(SOLID_BBOX)
			
			local physObj = entity:GetPhysicsObject()

			if (IsValid(physObj)) then
				physObj:EnableMotion(false)
				physObj:Sleep()
			end

			entity:SetNoBubble(v.bubble)
			entity:SetDisplayName(v.name or "John Doe")
			entity:SetDescription(v.description)
			
			for id, bodygroup in pairs(v.bodygroups or {}) do
				entity:SetBodygroup(id, bodygroup)
			end
			
			entity.inventory_size = {w = v.inventory_size.w or 1, h = v.inventory_size.h or 1}
			entity:BuildInventory(function(inventory)
				for uniqueID, data in pairs(v.items) do
					if (not data or not ix.item.Get(tostring(uniqueID))) then continue end
					inventory:Add(tostring(uniqueID), 1, nil, nil, nil, true)
				end
			end, entity.inventory_size.w, entity.inventory_size.h)
		

			local items = {}

			for uniqueID, data in pairs(v.items) do
				if (not data or not ix.item.Get(tostring(uniqueID))) then continue end
				items[tostring(uniqueID)] = data
			end

			entity.items = items
			entity.factions = v.factions or {}
			entity.classes = v.classes or {}
			entity.money = v.money
			entity.scale = v.scale or 0.5
			
			items = nil
		end
	end
	
	net.Receive("ixVendorRemakeClose", function(len, client)
		local entity = client.ixOpenVendorRemake
		if (IsValid(entity)) then
			local inventory = entity:GetInventory()
			if (inventory) then
				inventory:RemoveReceiver(client)
			end
			
			for k, v in ipairs(entity.receivers) do
				if (v == client) then
					table.remove(entity.receivers, k)
					break
				end
			end
			
			client.ixOpenVendorRemake = nil
		end
	end)
	
	local function UpdateEditReceivers(receivers, key, value)
		net.Start("ixVendorRemakeEdit")
			net.WriteString(key)
			net.WriteType(value)
		net.Send(receivers)
	end
	-- SERVER
	net.Receive("ixVendorRemakeEdit", function(len, client)
		if (!CAMI.PlayerHasAccess(client, "Helix - Manage Vendors", nil)) then
			return
		end
		
		local entity = client.ixOpenVendorRemake
		if (!IsValid(entity)) then
			return
		end
		
		local key = net.ReadString()
		local data = net.ReadType()
		local feedback = true
		
		if (key == "name") then
			entity:SetDisplayName(data)
		elseif (key == 'inventory_size') then
			entity:OnRemoveInventory()
			
			local invW, invH = math.floor(data[1]), math.floor(data[2])
			
			timer.Create("ixVendorRemakeRestoreInvSize", 1, 1, function()
				entity:BuildInventory(function(inventory)
					entity.inventory_size = {w = inventory.w, h = inventory.h}
					
					for k, v in ipairs(entity.receivers) do
						inventory:AddReceiver(v)
						inventory:Sync(v)
					end
					
					UpdateEditReceivers(entity.receivers, key, value)
				end, invW, invH)
			end)
			
			feedback = false
		elseif (key == "remove_inv_item") then
			if (IsValid(entity)) then
				entity:GetInventory():Remove(data[1], nil, true, true)
				entity.items[data[2]] = nil
			end
		elseif (key == "description") then
			entity:SetDescription(data)
		elseif (key == "bubble") then
			entity:SetNoBubble(data)
		elseif (key == "mode") then
			local uniqueID = data[1]
			local mode = data[2]
			local inventory = entity:GetInventory()
			local items = inventory:GetItemsByUniqueID(uniqueID, true)
			
			if (mode and #items == 0 and !inventory:Add(uniqueID)) then
				feedback = false
			else
				if (not mode and #items > 0) then
					for _, v in ipairs(items) do
						if (v.uniqueID == uniqueID) then
							inventory:Remove(v.id, nil, true, true)
							break
						end
					end
				end
				
				entity.items[uniqueID] = entity.items[uniqueID] or {}
				entity.items[uniqueID][VENDOR.MODE] = mode
			end

			UpdateEditReceivers(entity.receivers, key, data)
		elseif (key == "price") then
			local uniqueID = data[1]
			data[2] = tonumber(data[2])

			if (data[2]) then
				data[2] = math.Round(data[2])
			end

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR.PRICE] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "stockDisable") then
			local uniqueID = data[1]

			entity.items[data] = entity.items[uniqueID] or {}
			entity.items[data][VENDOR.MAXSTOCK] = nil

			UpdateEditReceivers(entity.receivers, key, data)
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			data[2] = math.max(math.Round(tonumber(data[2]) or 1), 1)

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR.MAXSTOCK] = data[2]
			entity.items[uniqueID][VENDOR.STOCK] = math.Clamp(entity.items[uniqueID][VENDOR.STOCK] or data[2], 1, data[2])

			data[3] = entity.items[uniqueID][VENDOR.STOCK]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "stock") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}

			if (!entity.items[uniqueID][VENDOR.MAXSTOCK]) then
				data[2] = math.max(math.Round(tonumber(data[2]) or 0), 0)
				entity.items[uniqueID][VENDOR.MAXSTOCK] = data[2]
			end

			data[2] = math.Clamp(math.Round(tonumber(data[2]) or 0), 0, entity.items[uniqueID][VENDOR.MAXSTOCK])
			entity.items[uniqueID][VENDOR.STOCK] = data[2]

			UpdateEditReceivers(entity.receivers, key, data)

			data = uniqueID
		elseif (key == "faction") then
			local faction = ix.faction.teams[data]

			if (faction) then
				entity.factions[data] = !entity.factions[data]

				if (!entity.factions[data]) then
					entity.factions[data] = nil
				end
			end

			local uniqueID = data
			data = {uniqueID, entity.factions[uniqueID]}
		elseif (key == "class") then
			local class

			for _, v in ipairs(ix.class.list) do
				if (v.uniqueID == data) then
					class = v

					break
				end
			end

			if (class) then
				entity.classes[data] = !entity.classes[data]

				if (!entity.classes[data]) then
					entity.classes[data] = nil
				end
			end

			local uniqueID = data
			data = {uniqueID, entity.classes[uniqueID]}
		elseif (key == "model") then
			entity:SetModel(data)
			entity:SetSolid(SOLID_BBOX)
			entity:PhysicsInit(SOLID_BBOX)
			entity:SetAnim()
			
			timer.Create("ixVendorRemakeUpdateInvType", 1, 1, function()
				local strModel = tostring(entity:GetModel()):lower()
				local query = mysql:Update("ix_inventories")
					query:Update("inventory_type", "vendor_new:"..strModel)
					query:Where("inventory_id", entity:GetID())
				query:Execute()
				query, strModel = nil, nil
			end)
		
		elseif (key == "useMoney") then
			if (entity.money) then
				entity:SetMoney()
			else
				entity:SetMoney(0)
			end
		elseif (key == "money") then
			data = math.Round(math.abs(tonumber(data) or 0))

			entity:SetMoney(data)
			feedback = false
		elseif (key == "scale") then
			data = tonumber(data) or 0.5

			entity.scale = data

			UpdateEditReceivers(entity.receivers, key, data)
		end

		PLUGIN:SaveData()

		if (feedback) then
			local receivers = {}

			for _, v in ipairs(entity.receivers) do
				if (CAMI.PlayerHasAccess(v, "Helix - Manage Vendors", nil)) then
					receivers[#receivers + 1] = v
				end
			end

			net.Start("ixVendorRemakeEditFinish")
				net.WriteString(key)
				net.WriteType(data)
			net.Send(receivers)
			receivers = nil
		end
	end)
	
	net.Receive("ixVendorRemakeTrade", function(length, client)
		if ((client.ixVendorTry or 0) < CurTime()) then
			client.ixVendorTry = CurTime() + 0.33
		else
			return
		end

		local entity = client.ixOpenVendorRemake

		if (!IsValid(entity) or client:GetPos():Distance(entity:GetPos()) > 192) then
			return
		end

		local itemID = net.ReadUInt(32)
		local isSellingToVendor = net.ReadBool()
		
		local itemData = ix.item.instances[itemID]
		local uniqueID = itemData.uniqueID
		local data = entity.items[uniqueID]
		
		if (data and
			hook.Run("CanPlayerTradeWithVendor", client, entity, uniqueID, isSellingToVendor) != false) then
			local price = entity:GetPrice(uniqueID, isSellingToVendor)

			if (isSellingToVendor) then
				if (data[VENDOR.MODE] ~= VENDOR.SELLANDBUY and data[VENDOR.MODE] ~= VENDOR.BUYONLY) then
					return false
				end
				
				local found = false
				local name

				if (!entity:HasMoney(price)) then
					return client:NotifyLocalized("vendorNoMoney")
				end
				
				local stock, max = entity:GetStock(uniqueID)
				if (stock and stock >= max) then
					return client:NotifyLocalized("vendorMaxStock")
				end

				local invOkay = true

				for _, v in pairs(client:GetCharacter():GetInventory():GetItems()) do
					if (v.id == itemID and v:GetID() != 0 and ix.item.instances[v:GetID()] and v:GetData("equip", false) == false) then
						invOkay = v:Remove()
						found = true
						name = L(v.name, client)

						break
					end
				end

				if (!found) then
					return
				end

				if (!invOkay) then
					client:GetCharacter():GetInventory():Sync(client, true)
					return client:NotifyLocalized("tellAdmin", "trd!iid")
				end

				client:GetCharacter():GiveMoney(price)
				client:NotifyLocalized("businessSell", name, ix.currency.Get(price))
				entity:TakeMoney(price)
				entity:AddStock(uniqueID)

				PLUGIN:SaveData()
				hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
			else
				if (data[VENDOR.MODE] ~= VENDOR.SELLANDBUY and data[VENDOR.MODE] ~= VENDOR.SELLONLY) then
					return false
				end
				
				local stock = entity:GetStock(uniqueID)

				if (stock and stock < 1) then
					return client:NotifyLocalized("vendorNoStock")
				end

				if (!client:GetCharacter():HasMoney(price)) then
					return client:NotifyLocalized("canNotAfford")
				end

				local name = L(ix.item.list[uniqueID].name, client)

				client:GetCharacter():TakeMoney(price)
				client:NotifyLocalized("businessPurchase", name, ix.currency.Get(price))

				entity:GiveMoney(price)

				if (!client:GetCharacter():GetInventory():Add(uniqueID)) then
					ix.item.Spawn(uniqueID, client)
				end

				entity:TakeStock(uniqueID)

				PLUGIN:SaveData()
				hook.Run("CharacterVendorTraded", client, entity, uniqueID, isSellingToVendor)
			end
		else
			client:NotifyLocalized("vendorNoTrade")
		end
	end)
else
	VENDOR_TEXT = {}
	VENDOR_TEXT[VENDOR.SELLANDBUY] = "vendorBoth"
	VENDOR_TEXT[VENDOR.BUYONLY] = "vendorBuy"
	VENDOR_TEXT[VENDOR.SELLONLY] = "vendorSell"
	
	function PLUGIN:CreateItemInteractionMenu(item_panel, menu, itemTable)
		if not IsValid(ix.gui.vendorRemake) then
			return
		end

		local entity = ix.gui.vendorRemake.entity
		local inventory = ix.item.inventories[item_panel.inventoryID]
		local data = entity.items[itemTable.uniqueID] and entity.items[itemTable.uniqueID][VENDOR.MODE] or 0
		
		menu = DermaMenu()
		
		if inventory.vars.isNewVendor then
			if (data == VENDOR.SELLANDBUY or data == VENDOR.SELLONLY) then
				menu:AddOption(L"purchase", function()
					self:SendTradeToVendor(itemTable, false)
				end):SetImage("icon16/basket_put.png")
			end
			
			if IsValid(ix.gui.vendorRemakeEditor) then
				menu:AddOption(L"vendorRemoveItemEditor", function()
					ix.gui.vendorRemakeEditor:updateVendor("remove_inv_item", {itemTable.id, itemTable.uniqueID})
				end):SetImage("icon16/basket_delete.png")
			end
		else -- client inventory
			if (data == VENDOR.SELLANDBUY or data == VENDOR.BUYONLY) then
				menu:AddOption(L"sell", function()
					self:SendTradeToVendor(itemTable, true)
				end):SetImage("icon16/basket_remove.png")
			end
		end
		
		menu:Open()
		
		return true
	end
	
	net.Receive("ixVendorRemakeEdit", function()
		local panel = ix.gui.vendorRemake

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

		if (key == "mode") then
			local uniqueID = data[1]
			
			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR.MODE] = data[2]
		elseif (key == 'inventory_size') then
			if (!IsValid(ix.gui.menu) and IsValid(ix.gui.vendorRemake)) then
				ix.gui.vendorRemake:SetLocalInventory(LocalPlayer():GetCharacter():GetInventory())
				ix.gui.vendorRemake:SetVendorInventory(entity:GetInventory())
			end
		elseif (key == "price") then
			local uniqueID = data[1]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR.PRICE] = tonumber(data[2])
		elseif (key == "stockDisable") then
			if (entity.items[data]) then
				entity.items[data][VENDOR.MAXSTOCK] = nil
			end
		elseif (key == "stockMax") then
			local uniqueID = data[1]
			local value = data[2]
			local current = data[3]

			entity.items[uniqueID] = entity.items[uniqueID] or {}
			entity.items[uniqueID][VENDOR.MAXSTOCK] = value
			entity.items[uniqueID][VENDOR.STOCK] = current
		elseif (key == "stock") then
			local uniqueID = data[1]
			local value = data[2]

			entity.items[uniqueID] = entity.items[uniqueID] or {}

			if (!entity.items[uniqueID][VENDOR.MAXSTOCK]) then
				entity.items[uniqueID][VENDOR.MAXSTOCK] = value
			end

			entity.items[uniqueID][VENDOR.STOCK] = value
		elseif (key == "scale") then
			entity.scale = data
		elseif (key == "remove_inv_item") then
			entity.items[data[2]] = nil
		end
	end)

	net.Receive("ixVendorRemakeEditFinish", function()
		local panel = ix.gui.vendorRemake
		local editor = ix.gui.vendorRemakeEditor

		if (!IsValid(panel) or !IsValid(editor)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local key = net.ReadString()
		local data = net.ReadType()

		if (key == "name") then
			editor.name:SetText(data)
		elseif (key == "description") then
			editor.description:SetText(data)
		elseif (key == "bubble") then
			editor.bubble.noSend = true
			editor.bubble:SetValue(data and 1 or 0)
		elseif (key == "mode") then
			if (data[2] == nil) then
				editor.lines[data[1]]:SetValue(2, L"none")
			else
				editor.lines[data[1]]:SetValue(2, L(VENDOR_TEXT[data[2]]))
			end
		elseif (key == "price") then
			editor.lines[data]:SetValue(3, entity:GetPrice(data))
		elseif (key == "stockDisable") then
			editor.lines[data]:SetValue(4, "-")
		elseif (key == "stockMax" or key == "stock") then
			local current, max = entity:GetStock(data)

			editor.lines[data]:SetValue(4, current.."/"..max)
		elseif (key == "faction") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ix.gui.editorFaction

			entity.factions[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.factions[uniqueID])) then
				editPanel.factions[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "class") then
			local uniqueID = data[1]
			local state = data[2]
			local editPanel = ix.gui.editorFaction

			entity.classes[uniqueID] = state

			if (IsValid(editPanel) and IsValid(editPanel.classes[uniqueID])) then
				editPanel.classes[uniqueID]:SetChecked(state == true)
			end
		elseif (key == "model") then
			editor.model:SetText(entity:GetModel())
		elseif (key == "scale") then
			editor.sellScale.noSend = true
			editor.sellScale:SetValue(data)
		elseif (key == "remove_inv_item") then
			editor.lines[data[2]]:SetValue(2, L"none")
		end

		surface.PlaySound("buttons/button14.wav")
	end)

	net.Receive("ixVendorRemakeOpen", function()
		if (IsValid(ix.gui.menu)) then
			net.Start("ixVendorRemakeClose")
			net.SendToServer()
			return
		end
		
		local entity = net.ReadEntity()
		
		if (!IsValid(entity)) then
			return
		end
		
		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()

		local inventory = entity:GetInventory()
		if (inventory and inventory.slots) then
			if IsValid(ix.gui.vendorRemake) then
				ix.gui.vendorRemake:Remove()
			end
			
			local localInventory = LocalPlayer():GetCharacter():GetInventory()
			ix.gui.vendorRemake = vgui.Create("ixVendorRemakeView")
			ix.gui.vendorRemake.entity = entity
			
			if (localInventory) then
				ix.gui.vendorRemake:SetLocalInventory(localInventory)
			end
			
			ix.gui.vendorRemake:SetVendorTitle(entity:GetDisplayName())
			ix.gui.vendorRemake:SetVendorInventory(entity:GetInventory())
			
			if (entity.money) then
				if (localInventory) then
					ix.gui.vendorRemake:SetLocalMoney(LocalPlayer():GetCharacter():GetMoney())
				end
				ix.gui.vendorRemake:SetVendorMoney(entity.money)
			end
		end
	end)
	
	net.Receive("ixVendorRemakeEditor", function()
		local entity = net.ReadEntity()

		if (!IsValid(entity) or !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Manage Vendors", nil)) then
			return
		end

		entity.money = net.ReadUInt(16)
		entity.items = net.ReadTable()
		entity.scale = net.ReadFloat()
		entity.messages = net.ReadTable()
		entity.factions = net.ReadTable()
		entity.classes = net.ReadTable()
		
		local inventory = entity:GetInventory()
		if (inventory and inventory.slots) then
			if IsValid(ix.gui.vendorRemake) then
				ix.gui.vendorRemake:Remove()
			end
			
			local localInventory = LocalPlayer():GetCharacter():GetInventory()
			ix.gui.vendorRemake = vgui.Create("ixVendorRemakeView")
			ix.gui.vendorRemake.entity = entity
			
			if (localInventory) then
				ix.gui.vendorRemake:SetLocalInventory(localInventory)
			end
			
			ix.gui.vendorRemake:SetVendorTitle(entity:GetDisplayName())
			ix.gui.vendorRemake:SetVendorInventory(entity:GetInventory())
			
			if (entity.money) then
				if (localInventory) then
					ix.gui.vendorRemake:SetLocalMoney(LocalPlayer():GetCharacter():GetMoney())
				end
				ix.gui.vendorRemake:SetVendorMoney(entity.money)
			end
			
			ix.gui.vendorRemakeEditor = vgui.Create("ixVendorRemakeEditor")
		end
	end)
	
	net.Receive("ixVendorRemakeMoney", function()
		local panel = ix.gui.vendorRemake

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local value = net.ReadUInt(16)
		value = value != -1 and value or nil
		entity.money = value

		local editor = ix.gui.vendorRemakeEditor

		if (IsValid(editor)) then
			local useMoney = tonumber(value) != nil

			editor.money:SetDisabled(!useMoney)
			editor.money:SetEnabled(useMoney)
			editor.money:SetText(useMoney and value or "∞")
		end
	end)

	net.Receive("ixVendorRemakeStock", function()
		local panel = ix.gui.vendorRemake

		if (!IsValid(panel)) then
			return
		end

		local entity = panel.entity

		if (!IsValid(entity)) then
			return
		end

		local uniqueID = net.ReadString()
		local amount = net.ReadUInt(16)

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR.STOCK] = amount

		local editor = ix.gui.vendorRemakeEditor

		if (IsValid(editor)) then
			local _, max = entity:GetStock(uniqueID)

			editor.lines[uniqueID]:SetValue(4, amount .. "/" .. max)
		end
	end)
end

properties.Add("vendor_remake_edit", {
	MenuLabel = "Edit Vendor",
	Order = 999,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		if (!IsValid(entity)) then return false end
		if (entity:GetClass() ~= "ix_vendor_new") then return false end
		if (!gamemode.Call( "CanProperty", client, "vendor_remake_edit", entity)) then return false end

		return CAMI.PlayerHasAccess(client, "Helix - Manage Vendors", nil)
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!IsValid(entity)) then return end
		if (!self:Filter(entity, client)) then return end

		local itemsTable = {}

		for k, v in pairs(entity.items) do
			if (!table.IsEmpty(v)) then
				itemsTable[k] = v
			end
		end

		-- Open Inventory
		local character = client:GetCharacter()
		if (character) then
			character:GetInventory():Sync(client, true)
		end
			
		entity:GetInventory():AddReceiver(client)
		entity.receivers[#entity.receivers + 1] = client
		client.ixOpenVendorRemake = entity
		entity:GetInventory():Sync(client)

		net.Start("ixVendorRemakeEditor")
			net.WriteEntity(entity)
			net.WriteUInt(entity.money or 0, 16)
			net.WriteTable(itemsTable)
			net.WriteFloat(entity.scale or 0.5)
			net.WriteTable(entity.messages)
			net.WriteTable(entity.factions)
			net.WriteTable(entity.classes)
		net.Send(client)
	end
})
