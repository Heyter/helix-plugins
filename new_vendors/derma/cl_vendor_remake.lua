local PANEL = {}

AccessorFunc(PANEL, "money", "Money", FORCE_NUMBER)

function PANEL:Init()
	self:DockPadding(1, 1, 1, 1)
	self:SetTall(22)
	self:Dock(BOTTOM)

	self.moneyLabel = self:Add("DLabel")
	self.moneyLabel:Dock(TOP)
	self.moneyLabel:SetFont("ixGenericFont")
	self.moneyLabel:SetText("")
	self.moneyLabel:SetTextInset(2, 0)
	self.moneyLabel:SizeToContents()
	self.moneyLabel.Paint = function(panel, width, height)
		derma.SkinFunc("DrawImportantBackground", 0, 0, width, height, ix.config.Get("color"))
	end

	self.bNoBackgroundBlur = true
end

function PANEL:SetMoney(money)
	money = math.max(math.Round(tonumber(money) or 0), 0)
	self.moneyLabel:SetText(ix.currency.Get(money))
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintBaseFrame", self, width, height)
end

vgui.Register("ixVendorRemakeMoney", PANEL, "EditablePanel")

DEFINE_BASECLASS("Panel")
PANEL = {}

AccessorFunc(PANEL, "fadeTime", "FadeTime", FORCE_NUMBER)
AccessorFunc(PANEL, "frameMargin", "FrameMargin", FORCE_NUMBER)

function PANEL:Init()
	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetFadeTime(0.25)
	self:SetFrameMargin(4)
	
	self.vendorInventory = self:Add("ixInventory")
	self.vendorInventory.bNoBackgroundBlur = true
	self.vendorInventory:ShowCloseButton(true)
	self.vendorInventory:SetTitle("John Doe")
	self.vendorInventory.Close = function(this)
		net.Start("ixVendorRemakeClose")
		net.SendToServer()
		self:Remove()
	end
	
	self.vendorMoney = self.vendorInventory:Add("ixVendorRemakeMoney")
	self.vendorMoney:SetVisible(false)
	
	-- Player inventory
	ix.gui.inv1 = self:Add("ixInventory")
	ix.gui.inv1.bNoBackgroundBlur = true
	ix.gui.inv1:ShowCloseButton(true)
	ix.gui.inv1.Close = function(this)
		net.Start("ixVendorRemakeClose")
		net.SendToServer()
		self:Remove()
	end
	
	self.localMoney = ix.gui.inv1:Add("ixVendorRemakeMoney")
	self.localMoney:SetVisible(false)

	self:SetAlpha(0)
	self:AlphaTo(255, self:GetFadeTime())

	self.vendorInventory:MakePopup()
	ix.gui.inv1:MakePopup()
end

function PANEL:OnChildAdded(panel)
	panel:SetPaintedManually(true)
end

function PANEL:SetLocalInventory(inventory)
	if (IsValid(ix.gui.inv1) and !IsValid(ix.gui.menu)) then
		ix.gui.inv1:SetInventory(inventory)
		ix.gui.inv1:SetPos(self:GetWide() / 2 + self:GetFrameMargin() / 2, self:GetTall() / 2 - ix.gui.inv1:GetTall() / 2)
	end
end

function PANEL:SetLocalMoney(money)
	if (!self.localMoney:IsVisible()) then
		self.localMoney:SetVisible(true)
		ix.gui.inv1:SetTall(ix.gui.inv1:GetTall() + self.localMoney:GetTall() + 2)
	end

	self.localMoney:SetMoney(money)
end

function PANEL:SetVendorTitle(title)
	self.vendorInventory:SetTitle(title)
end

function PANEL:SetVendorInventory(inventory)
	self.vendorInventory:SetInventory(inventory)
	self.vendorInventory:SetPos(
		self:GetWide() / 2 - self.vendorInventory:GetWide() - 2,
		self:GetTall() / 2 - self.vendorInventory:GetTall() / 2
	)

	ix.gui["inv" .. inventory:GetID()] = self.vendorInventory
end

function PANEL:SetVendorMoney(money)
	if (!self.vendorMoney:IsVisible()) then
		self.vendorMoney:SetVisible(true)
		self.vendorInventory:SetTall(self.vendorInventory:GetTall() + self.vendorMoney:GetTall() + 2)
	end

	self.vendorMoney:SetMoney(money)
end

function PANEL:Paint(width, height)
	ix.util.DrawBlurAt(0, 0, width, height)

	for _, v in ipairs(self:GetChildren()) do
		v:PaintManual()
	end
end

function PANEL:Remove()
	self:SetAlpha(255)
	self:AlphaTo(0, self:GetFadeTime(), 0, function()
		BaseClass.Remove(self)
	end)
end

function PANEL:OnRemove()
	if (!IsValid(ix.gui.menu)) then
		-- net.Start("ixVendorRemakeClose")
		-- net.SendToServer()
		
		self.vendorInventory:Remove()
		ix.gui.inv1:Remove()

		if (IsValid(ix.gui.vendorRemakeEditor)) then
			ix.gui.vendorRemakeEditor:Remove()
		end
	end
end

function PANEL:Think()
	local entity = self.entity

	if (!IsValid(entity)) then
		self:Remove()
		return
	end

	if ((self.nextUpdate or 0) < CurTime()) then
		self:SetVendorTitle(entity:GetDisplayName())
		self.localMoney:SetMoney(LocalPlayer():GetCharacter():GetMoney())
		self.vendorMoney:SetMoney(entity.money)

		self.nextUpdate = CurTime() + 0.25
	end
end

vgui.Register("ixVendorRemakeView", PANEL, "DFrame")
