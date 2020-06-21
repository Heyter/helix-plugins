local PANEL = {}

function PANEL:Init()
	self:SetSize(256, 132)
	self:Center()
	self:MakePopup()
	self:SetTitle(L"vendorTitleInvSize")
end

function PANEL:Setup()
	self.inventories = self.entity:GetInventory()

	self.invW = self:Add("DNumSlider")
	self.invW:Dock(TOP)
	self.invW:DockMargin(0, 4, 0, 0)
	self.invW:SetText(L"vendorSlideWInvSize")
	self.invW.Label:SetTextColor(color_white)
	self.invW.TextArea:SetTextColor(color_white)
	self.invW:SetDecimals(0)
	self.invW:SetValue(self.inventories.w)
	self.invW:SetMinMax(1, 32)
	
	self.invH = self:Add("DNumSlider")
	self.invH:Dock(TOP)
	self.invH:DockMargin(0, 4, 0, 0)
	self.invH:SetText(L"vendorSlideHInvSize")
	self.invH.Label:SetTextColor(color_white)
	self.invH.TextArea:SetTextColor(color_white)
	self.invH:SetDecimals(0)
	self.invH:SetValue(self.inventories.h)
	self.invH:SetMinMax(1, 32)
	
	self.send = self:Add("DButton")
	self.send:SetText(L"vendorResizeBtnInvSize")
	self.send:Dock(TOP)
	self.send:SetTextColor(color_white)
	self.send:DockMargin(0, 4, 0, 0)
	self.send.DoClick = function(this)
		self:Remove()
		
		self:updateVendor("inventory_size", {self.invW:GetValue(), self.invH:GetValue()})
	end
end

vgui.Register("ixVendorInventoryEditor", PANEL, "DFrame")
