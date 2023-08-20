
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
    self.TitleBar.QueryYellButton.Label:SetText("Query Surrounding")
    self.TitleBar.QueryZoneButton.Label:SetText("Query Guild")
    --
    -- Initialize scroll list
    --
    self.ScrollView = CreateScrollBoxListLinearView(0, 0, 0, 0, 2)
    self.ScrollView:SetElementInitializer("IAAM_MT_ScrollListButtonTemplate", IAAM_MT_Mixin.ElementInitializer)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollList.ScrollBox, self.ScrollList.ScrollBar, self.ScrollView)
    -- Alternating background coloring for scroll list items
    local function OnDataRangeChanged(SortPending)
        local Index = self.ScrollList.ScrollBox:GetDataIndexBegin()
        self.ScrollList.ScrollBox:ForEachFrame(function(Button)
            Button.Alternate:SetShown(Index % 2 == 1)
            Index = Index + 1
        end)
    end
    self.ScrollList.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnDataRangeChanged, OnDataRangeChanged, self)
end

function IAAM_MT_Mixin.ElementInitializer(Frame, Data)
    Frame.Data = Data
    Frame.LeftLabel:SetText(Data.Player)
    Frame.RightLabel:SetText("Item Count: "..Data.NumItems)
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
	self.MouseoverOverlay:Show()
    SetCursor("BUY_CURSOR");
end

function IAAM_MT_ScrollListButtonMixin:OnLeave()
	self.MouseoverOverlay:Hide()
    SetCursor(nil);
end

--============================================================
--============================================================
--
--             QueryYellMixin
--

QueryYellMixin = {}

function QueryYellMixin:OnClick(Button, Down)
    self:GetParent():GetParent().DataTable = CreateDataProvider()
    IAAM_MT.ScrollList.ScrollBox:SetDataProvider(self:GetParent():GetParent().DataTable)
    IAAM_COM_QueryBroadcastYell()
end

--============================================================
--============================================================
--
--             QueryZoneMixin
--

QueryZoneMixin = {}

function QueryZoneMixin:OnClick(Button, Down)
    self:GetParent():GetParent().DataTable = CreateDataProvider()
    IAAM_MT.ScrollList.ScrollBox:SetDataProvider(self:GetParent():GetParent().DataTable)
    IAAM_COM_QueryBroadcastGuild()
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