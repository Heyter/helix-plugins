PLUGIN.name = "CanTool"
PLUGIN.author = "STEAM_0:1:29606990"
PLUGIN.description = "Overwrite CanTool method"

local NO_DUPLICATE_ENTS = {}
NO_DUPLICATE_ENTS['ix_money'] = true
NO_DUPLICATE_ENTS['ix_item'] = true
NO_DUPLICATE_ENTS['ix_shipment'] = true

do
	local TOOL_DANGEROUS = {}
	TOOL_DANGEROUS["dynamite"] = true
	TOOL_DANGEROUS["duplicator"] = true
	
	function GAMEMODE:CanTool(client, trace, tool_name)
		if (tool_name == "duplicator" and IsValid(trace.Entity) and (trace.Entity.NoDuplicate or NO_DUPLICATE_ENTS[trace.Entity:GetClass()])) then
			return false
		end
		
		if (client:IsAdmin()) then
			return true
		end

		if (TOOL_DANGEROUS[tool_name]) then
			return false
		end
		
		return self.BaseClass:CanTool(client, trace, tool_name)
	end
end
