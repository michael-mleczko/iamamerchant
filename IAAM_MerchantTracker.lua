
--============================================================
--============================================================
--
--             local variables
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
	self.ResizeButton:Init(self, 0, 0);  -- Frame, MinPanelWidth, MinPanelHeight
    --
    -- Initialize QueryYellButton
    --
    self.TitleBar.QueryYellButton.Label:SetText("Query Surroundings")
    self.TitleBar.QueryGuildButton.Label:SetText("Query Guild")
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
end

function IAAM_MT_Mixin.ElementInitializer(Frame, Data)
    Frame.Data = Data
    Frame.LeftLabel:SetText(Data.Player)
    Frame.RightLabel:SetText("Item Count: "..Data.NumItems)
    Frame:SetBackdrop(backdropInfo)
    Frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
    Frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1.0)
end

--============================================================
--============================================================
--
--             IAAM_MT_ScrollListButtonMixin
--

IAAM_MT_ScrollListButtonMixin = {}

function IAAM_MT_ScrollListButtonMixin:OnClick()
    IAAM_FRAME_OpenPlayer(self.Data.Player)
end

function IAAM_MT_ScrollListButtonMixin:OnEnter()
    local r, g, b, _ = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 1)
    SetCursor("BUY_CURSOR")
end

function IAAM_MT_ScrollListButtonMixin:OnLeave()
    local r, g, b, _ = self:GetBackdropColor()
    self:SetBackdropColor(r, g, b, 0.5)
    SetCursor(nil);
end

--============================================================
--============================================================
--
--             QueryYellMixin
--

QueryYellMixin = {}

function QueryYellMixin:OnClick(Button, Down)
    if self.Enabled ~= false then
        self:GetParent():GetParent().DataTable = CreateDataProvider()
        IAAM_MT.ScrollList.ScrollBox:SetDataProvider(self:GetParent():GetParent().DataTable)
        IAAM_COM_QueryBroadcastYell()
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
--             QueryGuildMixin
--

QueryGuildMixin = {}

function QueryGuildMixin:OnClick(Button, Down)
    if self.Enabled ~= false then
        self:GetParent():GetParent().DataTable = CreateDataProvider()
        IAAM_MT.ScrollList.ScrollBox:SetDataProvider(self:GetParent():GetParent().DataTable)
        IAAM_COM_QueryBroadcastGuild()
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

IAAM_MT_MenuButtonMixin = {};

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