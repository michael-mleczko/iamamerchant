local _, IAAM = ...

--============================================================
--============================================================
--
--             Merchant Tracker
--
--  Lists the other IAmAMerchant users known to IAAM.NET:
--
--  * Merchants that answered (same internal realm): clickable, with
--    the number of items for sale. Merchants without items are only
--    shown with /iaam toggleshowall.
--  * Below a header, all other addon users, greyed out: still being
--    checked, or without connection (usually another internal realm).
--
--  While the window is shown, players are asked again every minute
--  (see IAAM.NET.Refresh for the intervals).
--

IAAM_MT_Mixin = {}

IAAM_MT_Mixin.REFRESH_INTERVAL = 60    -- Seconds between automatic refreshes
IAAM_MT_Mixin.REFRESH_COOLDOWN = 10    -- Seconds the refresh button stays disabled

IAAM_MT_Mixin.COLOR_MERCHANT = { 0.2, 0.8, 0.3 }
IAAM_MT_Mixin.COLOR_OTHER    = { 0.4, 0.4, 0.4 }

function IAAM_MT_Mixin:OnLoad()
    self:SetTitle("Merchants")
    --
    -- Search box: filter the list by name
    --
    self.SearchBox.Instructions:SetText("Search names")
    self.SearchBox:HookScript("OnTextChanged", function()
        self:UpdateList()
    end)
    --
    -- Refresh button: ask all players again
    --
    self.RefreshButton:SetScript("OnClick", function(Button)
        IAAM.NET.Refresh(true)
        Button:Disable()
        Button.Icon:SetDesaturated(true)
        C_Timer.After(self.REFRESH_COOLDOWN, function()
            Button:Enable()
            Button.Icon:SetDesaturated(false)
        end)
    end)
    self.RefreshButton:SetScript("OnEnter", function(Button)
        GameTooltip:SetOwner(Button, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, "Refresh")
        GameTooltip_AddNormalLine(GameTooltip, "Ask all IAmAMerchant users again whether they can be reached.", true)
        GameTooltip:Show()
    end)
    self.RefreshButton:SetScript("OnLeave", GameTooltip_Hide)
    --
    -- Resize grip: only the height can be changed
    --
    self.ResizeButton:SetScript("OnMouseDown", function()
        local AlwaysStartFromMouse = true
        self:StartSizing("BOTTOM", AlwaysStartFromMouse)
    end)
    self.ResizeButton:SetScript("OnMouseUp", function()
        self:StopMovingOrSizing()
    end)
    --
    -- List
    --
    local View = CreateScrollBoxListLinearView(0, 0, 0, 0, 1)
    View:SetElementInitializer("IAAM_MT_RowTemplate", function(Row, Data)
        Row:Init(Data)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, View)
    --
    -- Keep the list up to date while the window is shown
    --
    IAAM.NET.OnPeersChanged = function()
        if self:IsShown() then
            self:UpdateList()
        end
    end
end

function IAAM_MT_Mixin:OnShow()
    IAAM.NET.AutoPing = true
    self:UpdateList()
    IAAM.NET.Refresh(false)
    self.RefreshTicker = C_Timer.NewTicker(self.REFRESH_INTERVAL, function()
        IAAM.NET.Refresh(false)
    end)
end

function IAAM_MT_Mixin:OnHide()
    IAAM.NET.AutoPing = false
    if self.RefreshTicker then
        self.RefreshTicker:Cancel()
        self.RefreshTicker = nil
    end
end

function IAAM_MT_Mixin:OnDragStart()
    self:StartMoving()
end

function IAAM_MT_Mixin:OnDragStop()
    self:StopMovingOrSizing()
end

--
-- Builds the list: reachable merchants, then a header and all other
-- addon users. Applies the search text.
--
function IAAM_MT_Mixin:UpdateList()
    local Search = string.lower(self.SearchBox:GetText() or "")
    local Merchants, Others = {}, {}
    for _, Peer in ipairs(IAAM.NET.GetSortedPeers()) do
        if Search == "" or string.find(string.lower(Peer.Name), Search, 1, true) then
            if Peer.Reachable == true then
                if IAAM_Character.ShowAll == true or (Peer.NumItems or 0) > 0 then
                    table.insert(Merchants, Peer)
                end
            else
                table.insert(Others, Peer)
            end
        end
    end

    local DataProvider = CreateDataProvider()
    local Index = 0
    for _, Peer in ipairs(Merchants) do
        Index = Index + 1
        DataProvider:Insert({ Type = "Merchant", Name = Peer.Name, NumItems = Peer.NumItems or 0, Index = Index })
    end
    if #Others > 0 then
        DataProvider:Insert({ Type = "Header", Name = "Not reachable" })
        for _, Peer in ipairs(Others) do
            Index = Index + 1
            DataProvider:Insert({ Type = "Other", Name = Peer.Name, Checking = Peer.Reachable == nil, Index = Index })
        end
    end
    self.ScrollBox:SetDataProvider(DataProvider, ScrollBoxConstants.RetainScrollPosition)

    --
    -- Empty list and summary
    --
    local IsEmpty = #Merchants == 0 and #Others == 0
    self.EmptyText:SetShown(IsEmpty)
    if Search ~= "" then
        self.EmptyText.Text:SetText("No player matches your search.")
    else
        self.EmptyText.Text:SetText("No other IAmAMerchant users online.")
    end
    local Status = #Merchants == 1 and "1 merchant" or (#Merchants.." merchants")
    if #Others > 0 then
        Status = Status..", "..#Others.." not reachable"
    end
    self.Status:SetText(Status)
end

--============================================================
--============================================================
--
--             IAAM_MT_RowMixin
--

IAAM_MT_RowMixin = {}

function IAAM_MT_RowMixin:Init(Data)
    self.Data = Data
    local IsHeader = Data.Type == "Header"
    self.Stripe:SetShown(not IsHeader)
    self.StatusBar:SetShown(not IsHeader)
    self:SetEnabled(not IsHeader)
    self.LeftLabel:SetText(Data.Name)

    if IsHeader then
        self.LeftLabel:SetFontObject(GameFontNormalSmall)
        self.LeftLabel:SetPoint("LEFT", 4, -2)
        self.RightLabel:SetText("")
        return
    end

    self.LeftLabel:SetFontObject(GameFontHighlightSmall)
    self.LeftLabel:SetPoint("LEFT", 10, 0)
    self.Stripe:SetAtlas(Data.Index % 2 == 1 and "auctionhouse-rowstripe-1" or "auctionhouse-rowstripe-2")
    if Data.Type == "Merchant" then
        self.StatusBar:SetColorTexture(unpack(IAAM_MT_Mixin.COLOR_MERCHANT))
        self.RightLabel:SetText(Data.NumItems == 1 and "1 item" or (Data.NumItems.." items"))
        self.LeftLabel:SetTextColor(1, 1, 1)
        self.RightLabel:SetTextColor(1, 0.82, 0)
    else
        self.StatusBar:SetColorTexture(unpack(IAAM_MT_Mixin.COLOR_OTHER))
        self.RightLabel:SetText(Data.Checking and "checking..." or "no connection")
        self.LeftLabel:SetTextColor(0.5, 0.5, 0.5)
        self.RightLabel:SetTextColor(0.5, 0.5, 0.5)
    end
end

function IAAM_MT_RowMixin:OnClick()
    if self.Data.Type == "Merchant" then
        IAAM.VW.Open(self.Data.Name)
    end
end

function IAAM_MT_RowMixin:OnEnter()
    local Data = self.Data
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, Data.Name)
    if Data.Type == "Merchant" then
        GameTooltip_AddNormalLine(GameTooltip, "Click to see the items for sale.", true)
        SetCursor("BUY_CURSOR")
    elseif Data.Checking then
        GameTooltip_AddNormalLine(GameTooltip, "Uses IAmAMerchant. Checking whether this player can be reached...", true)
    else
        GameTooltip_AddNormalLine(GameTooltip, "Uses IAmAMerchant, but didn't answer.", true)
        GameTooltip_AddDisabledLine(GameTooltip, "On WoW Forever, addon messages between players on different internal realms usually don't arrive. The addon keeps trying. You can still whisper this player to trade.", true)
    end
    GameTooltip:Show()
end

function IAAM_MT_RowMixin:OnLeave()
    GameTooltip:Hide()
    SetCursor(nil)
end
