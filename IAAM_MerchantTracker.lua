local _, IAAM = ...

--============================================================
--============================================================
--
--             Variables
--

local backdropInfo = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 8,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

--============================================================
--============================================================
--
--             IAAM_MT_Mixin
--

IAAM_MT_Mixin = {}

function IAAM_MT_Mixin:OnLoad()
    --
    -- Remove protrait and replace by corner and expanded borders.
    --
    ButtonFrameTemplate_HidePortrait(self)
    --
    -- Initialize title bar
    --
    self.TitleBar:Init(self)
    self:SetTitle("Merchant Tracker")
    --
    -- Make required initialization to make window resizable
    --
	self.ResizeButton:Init(self, 0, 0)  -- Frame, MinPanelWidth, MinPanelHeight
    --
    -- Initialize refresh button
    --
    self.TitleBar.RefreshButton.Label:SetText("Refresh")
    --
    -- Initialize scroll list
    --
    self.ScrollView = CreateScrollBoxListLinearView(0, 0, 0, 0, 2)
    self.ScrollView:SetElementInitializer("IAAM_MT_ScrollListButtonTemplate", IAAM_MT_Mixin.ElementInitializer)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollList.ScrollBox, self.ScrollList.ScrollBar, self.ScrollView)
    -- currently disabled:
    -- Alternating background coloring for scroll list items
    --local function OnDataRangeChanged(SortPending)
    --    local Index = self.ScrollList.ScrollBox:GetDataIndexBegin()
    --    self.ScrollList.ScrollBox:ForEachFrame(function(Button)
    --        --Button.Alternate:SetShown(Index % 2 == 1)
    --        --if (Index % 2 == 0) then
    --        --    Button:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    --        --else
    --        --    Button:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
    --        --end
    --        --Index = Index + 1
    --    end)
    --end
    --self.ScrollList.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnDataRangeChanged, OnDataRangeChanged, self)
    --
    -- Keep the list up to date while the window is shown
    --
    IAAM.NET.OnPeersChanged = function()
        if self:IsShown() then
            self:UpdateList()
        end
    end
    self:HookScript("OnShow", self.OnShowList)
    self:HookScript("OnHide", self.OnHideList)
end

--
-- While the window is shown, other addon users are asked every minute
-- whether they can be reached (see IAAM.NET.Refresh).
--
function IAAM_MT_Mixin:OnShowList()
    IAAM.NET.AutoPing = true
    self:UpdateList()
    IAAM.NET.Refresh(false)
    self.RefreshTicker = C_Timer.NewTicker(60, function()
        IAAM.NET.Refresh(false)
    end)
end

function IAAM_MT_Mixin:OnHideList()
    IAAM.NET.AutoPing = false
    if self.RefreshTicker then
        self.RefreshTicker:Cancel()
        self.RefreshTicker = nil
    end
end

--
-- Shows reachable merchants (with items, or all if ShowAll is on), and
-- greyed out the addon users that couldn't be reached yet.
--
function IAAM_MT_Mixin:UpdateList()
    local DataProvider = CreateDataProvider()
    for _, Peer in ipairs(IAAM.NET.GetSortedPeers()) do
        if Peer.Reachable ~= true or IAAM_Character.ShowAll == true or (Peer.NumItems or 0) > 0 then
            DataProvider:Insert({ Player = Peer.Name, NumItems = Peer.NumItems, Reachable = Peer.Reachable })
        end
    end
    self.ScrollList.ScrollBox:SetDataProvider(DataProvider, ScrollBoxConstants.RetainScrollPosition)
end

function IAAM_MT_Mixin.ElementInitializer(Frame, Data)
    Frame.Data = Data
    Frame.LeftLabel:SetText(Data.Player)
    if Data.Reachable == true then
        Frame.RightLabel:SetText("Item Count: "..(Data.NumItems or 0))
        Frame.LeftLabel:SetTextColor(1, 1, 1)
        Frame.RightLabel:SetTextColor(1, 1, 1)
    elseif Data.Reachable == nil then
        Frame.RightLabel:SetText("Checking...")
        Frame.LeftLabel:SetTextColor(0.6, 0.6, 0.6)
        Frame.RightLabel:SetTextColor(0.6, 0.6, 0.6)
    else
        Frame.RightLabel:SetText("No connection")
        Frame.LeftLabel:SetTextColor(0.5, 0.5, 0.5)
        Frame.RightLabel:SetTextColor(0.5, 0.5, 0.5)
    end
    Frame:SetBackdrop(backdropInfo)
    if Data.Reachable == true then
        Frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
        Frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1.0)
    else
        Frame:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
        Frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    end
end

--============================================================
--============================================================
--
--             IAAM_MT_ScrollListButtonMixin
--

IAAM_MT_ScrollListButtonMixin = {}

function IAAM_MT_ScrollListButtonMixin:OnClick()
    if self.Data.Reachable == true then
        IAAM.VW.Open(self.Data.Player)
    end
end

function IAAM_MT_ScrollListButtonMixin:OnEnter()
    local r, g, b, _ = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 1)
    if self.Data.Reachable == true then
        SetCursor("BUY_CURSOR")
        return
    end
    --
    -- Explain why the player is greyed out
    --
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self.Data.Player)
    if self.Data.Reachable == nil then
        GameTooltip_AddNormalLine(GameTooltip, "Uses IAmAMerchant. Checking whether this player can be reached...", true)
    else
        GameTooltip_AddNormalLine(GameTooltip, "Uses IAmAMerchant, but didn't answer.", true)
        GameTooltip_AddDisabledLine(GameTooltip, "On WoW Forever, addon messages between players on different internal realms usually don't arrive. The addon keeps trying. You can still whisper this player to trade.", true)
    end
    GameTooltip:Show()
end

function IAAM_MT_ScrollListButtonMixin:OnLeave()
    local r, g, b, _ = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.5)
    SetCursor(nil)
    GameTooltip:Hide()
end

--============================================================
--============================================================
--
--             IAAM_MT_RefreshButtonMixin
--
--  Asks all addon users again whether they can be reached. Disabled
--  for 10 seconds after a click.
--

IAAM_MT_RefreshButtonMixin = {}

function IAAM_MT_RefreshButtonMixin:OnClick(Button, Down)
    if self.Enabled ~= false then
        IAAM.NET.Refresh(true)
        self:SetEnabled(false)
        self.Label:SetAlpha(0.2)
        self.Enabled = false
        C_Timer.After(10, function()
            self:SetEnabled(true)
            self.Enabled = true
            self.Label:SetAlpha(1)
        end)
    end
end

--============================================================
--============================================================
--
--             IAAM_MT_MenuButtonMixin
--

IAAM_MT_MenuButtonMixin = {}

function IAAM_MT_MenuButtonMixin:OnEnter()
	self.MouseoverOverlay:Show()
end

function IAAM_MT_MenuButtonMixin:OnLeave()
	self.MouseoverOverlay:Hide()
end

function IAAM_MT_MenuButtonMixin:OnMouseDown()
    self:AdjustPointsOffset(1, -1)
end

function IAAM_MT_MenuButtonMixin:OnMouseUp()
    self:AdjustPointsOffset(-1, 1)
end