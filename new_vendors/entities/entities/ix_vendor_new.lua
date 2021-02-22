local PLUGIN = PLUGIN
ENT.Type = "anim"
ENT.PrintName = "Vendor Remake"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ID")
	self:NetworkVar("Bool", 0, "NoBubble")
	self:NetworkVar("String", 0, "DisplayName")
	self:NetworkVar("String", 1, "Description")
end

function ENT:Initialize()
	if (SERVER) then
		self:SetModel("models/mossman.mdl")
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
		self:DrawShadow(true)
		self:SetSolid(SOLID_BBOX)
		self:PhysicsInit(SOLID_BBOX)

		self.items = {}
		self.messages = {}
		self.factions = {}
		self.classes = {}
		self.inventory_size = {w = 1, h = 1}

		self:SetDisplayName("John Doe")
		self:SetDescription("")

		self.receivers = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	timer.Simple(1, function()
		if (IsValid(self)) then
			self:SetAnim()
		end
	end)
end

if (SERVER) then
	local PLUGIN = PLUGIN
	
	function ENT:SpawnFunction(client, trace)
		local angles = (trace.HitPos - client:GetPos()):Angle()
		angles.r = 0
		angles.p = 0
		angles.y = angles.y + 180

		local entity = ents.Create("ix_vendor_new")
		entity:SetPos(trace.HitPos)
		entity:SetAngles(angles)
		entity:Spawn()
		entity:BuildInventory()
		
		PLUGIN:SaveData()

		return entity
	end
	
	function ENT:BuildInventory(callback, w, h)
		local invID = os.time() + self:EntIndex()
		
		if self:GetID() ~= 0 then
			invID = self:GetID()
		end
		
		local inventory = ix.inventory.Create(w or 1, h or 1, invID)
		
		inventory.vars.isNewVendor = true
		inventory.noSave = true
		
		if (callback) then
			callback(inventory)
		end

		self:SetInventory(inventory)
	end
	
	function ENT:SetInventory(inventory)
		if (inventory) then
			self:SetID(inventory:GetID())
			inventory.OnAuthorizeTransfer = function(inventory, client, oldInventory, item)
				if (IsValid(client) and IsValid(self) and inventory.vars and inventory.vars.isNewVendor) then
					return false
				end
			end
		end
	end
	
	function ENT:OnRemoveInventory()
		local index = self:GetID()
		
		if (!ix.shuttingDown and !self.ixIsSafe and ix.entityDataLoaded and index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				ix.item.inventories[index] = nil
				self.items = {}

				hook.Run("VendorRemakeRemoved", self, inventory)
			end
		end
	end

	function ENT:OnRemove()
		self:OnRemoveInventory()
	end

	function ENT:Use(activator)		
		local inventory = self:GetInventory()

		if (inventory and (activator.ixNextOpen or 0) < CurTime()) then
			if (!self:CanAccess(activator) or hook.Run("CanPlayerUseVendor", activator) == false) then
				if (self.messages[VENDOR.NOTRADE]) then
					activator:ChatPrint(self:GetDisplayName()..": "..self.messages[VENDOR.NOTRADE])
				else
					activator:NotifyLocalized("vendorNoTrade")
				end

				return
			end
		
			if (self.messages[VENDOR.WELCOME]) then
				activator:ChatPrint(self:GetDisplayName()..": "..self.messages[VENDOR.WELCOME])
			end
			
			local items = {}

			-- Only send what is needed.
			for k, v in pairs(self.items) do
				if (!table.IsEmpty(v) and (CAMI.PlayerHasAccess(activator, "Helix - Manage Vendors", nil) or v[VENDOR.MODE])) then
					items[k] = v
				end
			end
			
			self.scale = self.scale or 0.5
			
			-- Open Inventory
			local character = activator:GetCharacter()
			if (character) then
				character:GetInventory():Sync(activator, true)
			end

			inventory:AddReceiver(activator)
			self.receivers[#self.receivers + 1] = activator
			activator.ixOpenVendorRemake = self
			inventory:Sync(activator)
			
			net.Start('ixVendorRemakeOpen')
				net.WriteEntity(self)
				net.WriteUInt(self.money or 0, 16)
				net.WriteTable(items)
			net.Send(activator)
			
			ix.log.Add(activator, "vendorRemakeUse", self:GetDisplayName())

			activator.ixNextOpen = CurTime() + 1
		end
	end
	
	function ENT:SetMoney(value)
		self.money = value

		net.Start("ixVendorRemakeMoney")
			net.WriteUInt(value and value or -1, 16)
		net.Send(self.receivers)
	end

	function ENT:GiveMoney(value)
		if (self.money) then
			self:SetMoney(self:GetMoney() + value)
		end
	end

	function ENT:TakeMoney(value)
		if (self.money) then
			self:GiveMoney(-value)
		end
	end

	function ENT:SetStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR.MAXSTOCK]) then
			return
		end

		self.items[uniqueID] = self.items[uniqueID] or {}
		self.items[uniqueID][VENDOR.STOCK] = math.min(value, self.items[uniqueID][VENDOR.MAXSTOCK])

		net.Start("ixVendorRemakeStock")
			net.WriteString(uniqueID)
			net.WriteUInt(value, 16)
		net.Send(self.receivers)
	end

	function ENT:AddStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR.MAXSTOCK]) then
			return
		end

		self:SetStock(uniqueID, self:GetStock(uniqueID) + (value or 1))
	end

	function ENT:TakeStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR.MAXSTOCK]) then
			return
		end

		self:AddStock(uniqueID, -(value or 1))
	end
else
	function ENT:CreateBubble()
		self.bubble = ClientsideModel("models/extras/info_speech.mdl", RENDERGROUP_OPAQUE)
		self.bubble:SetPos(self:GetPos() + Vector(0, 0, 84))
		self.bubble:SetModelScale(0.6, 0)
	end

	function ENT:Draw()
		local bubble = self.bubble

		if (IsValid(bubble)) then
			local realTime = RealTime()

			bubble:SetRenderOrigin(self:GetPos() + Vector(0, 0, 84 + math.sin(realTime * 3) * 0.05))
			bubble:SetRenderAngles(Angle(0, realTime * 100, 0))
		end

		self:DrawModel()
	end

	function ENT:Think()
		local noBubble = self:GetNoBubble()

		if (IsValid(self.bubble) and noBubble) then
			self.bubble:Remove()
		elseif (!IsValid(self.bubble) and !noBubble) then
			self:CreateBubble()
		end

		if ((self.nextAnimCheck or 0) < CurTime()) then
			self:SetAnim()
			self.nextAnimCheck = CurTime() + 60
		end

		self:SetNextClientThink(CurTime() + 0.25)

		return true
	end

	function ENT:OnRemove()
		if (IsValid(self.bubble)) then
			self.bubble:Remove()
		end
	end

	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(self:GetDisplayName())
		name:SizeToContents()

		local descriptionText = self:GetDescription()

		if (descriptionText != "") then
			local description = container:AddRow("description")
			description:SetText(self:GetDescription())
			description:SizeToContents()
		end
	end
end

function ENT:GetInventory()
	return ix.item.inventories[self:GetID()]
end

function ENT:GetMoney()
	return self.money
end

function ENT:CanAccess(client)
	local bAccess = false
	local uniqueID = ix.faction.indices[client:Team()].uniqueID

	if (self.factions and !table.IsEmpty(self.factions)) then
		if (self.factions[uniqueID]) then
			bAccess = true
		else
			return false
		end
	end

	if (bAccess and self.classes and !table.IsEmpty(self.classes)) then
		local class = ix.class.list[client:GetCharacter():GetClass()]
		local classID = class and class.uniqueID

		if (classID and !self.classes[classID]) then
			return false
		end
	end

	return true
end

function ENT:GetStock(uniqueID)
	if (self.items[uniqueID] and self.items[uniqueID][VENDOR.MAXSTOCK]) then
		return self.items[uniqueID][VENDOR.STOCK] or 0, self.items[uniqueID][VENDOR.MAXSTOCK]
	end
end

function ENT:GetPrice(uniqueID, selling)
	local price = ix.item.list[uniqueID] and self.items[uniqueID] and
		self.items[uniqueID][VENDOR.PRICE] or ix.item.list[uniqueID].price or 0

	if (selling) then
		price = math.floor(price * (self.scale or 0.5))
	end

	return price
end

function ENT:HasMoney(amount)
	-- Vendor not using money system so they can always afford it.
	if (!self.money) then
		return true
	end

	return self.money >= amount
end

function ENT:SetAnim()
	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v != "idlenoise") then
			return self:ResetSequence(k)
		end
	end

	if (self:GetSequenceCount() > 1) then
		self:ResetSequence(4)
	end
end
