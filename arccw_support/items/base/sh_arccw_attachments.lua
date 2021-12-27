ITEM.name = "ArcCW Attachment"
ITEM.description = ""
ITEM.category = "ArcCW Attachments"
ITEM.model = "models/Items/BoxMRounds.mdl"
ITEM.width = 1
ITEM.height = 1

ITEM.isAttachment = true
ITEM.isArcCW = true

ITEM.functions.Attach = {
	name = "Attach",
	icon = "icon16/wrench.png",
	isMulti = true,
	multiOptions = function(item, client)
		local targets = {}
		local items = client:GetItems()

		if (items) then
			local name = ""
			local slot
			local mods = {}

			for _, v in pairs(items) do
				if (v.isWeapon and v.isArcCW and v.attachments) then
					slot = v.attachments[item.uniqueID]
					if (!slot) then goto SKIP end

					mods = v:GetData("mods", {})

					if (mods[slot]) then
						slot = ix.arccw_support.FindAttachSlot(v, item.uniqueID)
						if (!slot) then goto SKIP end
					end

					if (mods[slot]) then
						goto SKIP
					end

					name = v:GetName()

					if (v:GetData("equip")) then
						name = "> " .. name
					end

					targets[#targets + 1] = {
						name = name,
						data = { v.id },
					}

					::SKIP::
				end
			end
		end

		return targets
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity) and IsValid(item.player) and item.invID == item.player:GetCharacter():GetInventory():GetID())
	end,
	OnRun = function(item, data)
		if (!item) then return false end
		if (!istable(data) or !data[1]) then return false end

		return ix.arccw_support.Attach(ix.item.instances[data[1]], item.uniqueID)
	end,
}