local _, IAAM = ...

_G.IAAM = IAAM

--============================================================
--============================================================
--
--             Variables
--

IAAM.ITEMS_PER_PAGE        = 12
IAAM.FRAME_UPDATE_INTERVAL = 1.0

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.FRAME_GetItemsForSaleTable()
--
function IAAM.FRAME_GetItemsForSaleTable()
    local Table
    if IAAM_Frame_Title:GetText() == IAAM.CORE_GetName("player") then
        Table = IAAM_Character.ItemsForSale
    else
        Table = IAAM.Merchant.ItemsForSale
    end
    return Table
end

--============================================================
--
--             IAAM.FRAME_GetPageString()
--
function IAAM.FRAME_GetPageString(Merchant)
    return "Page "..IAAM_Frame.Page.." of "..math.ceil(IAAM.CORE_GetNumItems(IAAM.FRAME_GetItemsForSaleTable()) / IAAM.ITEMS_PER_PAGE)
end

--============================================================
--
--             IAAM_FRAME_NextPageButton_OnClick()
--
function IAAM_FRAME_NextPageButton_OnClick(self)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_NextPageButton_OnClick()")
    if IAAM_Frame.Page < (IAAM.CORE_GetNumItems(IAAM.FRAME_GetItemsForSaleTable()) / IAAM.ITEMS_PER_PAGE) then
        IAAM_Frame.Page = IAAM_Frame.Page + 1
        IAAM_Frame_Page:SetText(IAAM.FRAME_GetPageString())
        IAAM.FRAME_Update()
    end
end

--============================================================
--
--             IAAM_FRAME_PrevPageButton_OnClick()
--
function IAAM_FRAME_PrevPageButton_OnClick(self)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_PrevPageButton_OnClick()")
    if IAAM_Frame.Page > 1 then
        IAAM_Frame.Page = IAAM_Frame.Page - 1
        IAAM_Frame_Page:SetText(IAAM.FRAME_GetPageString())
        IAAM.FRAME_Update()
    end
end

--============================================================
--
--             IAAM.FRAME_ItemButton_OnClick()
--
function IAAM.FRAME_ItemButton_OnClick(self, button, down)
    IAAM.DEBUG_Print(false, "IAAM.FRAME_ItemButton_OnClick()")
    if button == "RightButton" then
        if IAAM_Frame.Name == IAAM.CORE_GetName("player") then
            --
            -- Remove item from your list
            --
            IAAM_Character.ItemsForSale[""..self.link] = nil
            IAAM.FRAME_Update()
        end
    elseif IsShiftKeyDown() and button == "LeftButton" then
        DEFAULT_CHAT_FRAME.editBox:Insert(self.link)
    end
end

--============================================================
--
--             IAAM.FRAME_AddItem_OnAccept()
--
function IAAM.FRAME_AddItem_OnAccept(self)
    local Price = tonumber(self.editBox:GetText())
    if Price == nil then
        Price = 0
    end
    IAAM.CORE_AddItem(IAAM_Character.ItemsForSale, IAAM.Popup_ItemLink, 0, Price, GetItemCount(IAAM.Popup_ItemLink, true, true))
    IAAM.FRAME_Update()
end

--============================================================
--
--             IAAM.FRAME_AddItem_OnShow()
--
function IAAM.FRAME_AddItem_OnShow(self)
    self.editBox:SetNumeric(true)
    self.editBox.Popup = self
    self.editBox:SetScript("OnEnterPressed", IAAM.FRAME_AddItem_OnEnterPressed)
    self.editBox:SetScript("OnEscapePressed", IAAM.FRAME_AddItem_OnEscapePressed)
end

--============================================================
--
--             IAAM.FRAME_AddItem_OnEnterPressed()
--
function IAAM.FRAME_AddItem_OnEnterPressed(self)
    IAAM.FRAME_AddItem_OnAccept(self.Popup)
    self.Popup:Hide()
end

--============================================================
--
--             IAAM.FRAME_AddItem_OnEscapePressed()
--
function IAAM.FRAME_AddItem_OnEscapePressed(self)
    self.Popup:Hide()
end

StaticPopupDialogs["IAAM.Popup_AddItem"] = {
    text           = "Price per Unit:",
    button1        = "Add Item",
    button2        = "Cancel",
    OnAccept       = IAAM.FRAME_AddItem_OnAccept,
    OnShow         = IAAM.FRAME_AddItem_OnShow,
    timeout        = 0,
    whileDead      = true,
    hideOnEscape   = 1,
    preferredIndex = 3,
    hasEditBox     = true
}

--============================================================
--
--             IAAM_FRAME_OnReceiveDrag()
--
function IAAM_FRAME_OnReceiveDrag(self)
    local Type, _, ItemLink = GetCursorInfo()
    ClearCursor()
    if IAAM.CORE_GetName("player") == IAAM_Frame_Title:GetText() then
        if Type == "item" then
            IAAM.Popup_ItemLink = ItemLink
            StaticPopup_Show("IAAM.Popup_AddItem")
        end
    end
end

--============================================================
--
--             IAAM_FRAME_OnMouseDown()
--
function IAAM_FRAME_OnMouseDown(self, button)
    if button == "LeftButton" then
        local Type, _, ItemLink = GetCursorInfo()
        ClearCursor()
        if IAAM.CORE_GetName("player") == IAAM_Frame_Title:GetText() then
            if Type == "item" then
                IAAM.Popup_ItemLink = ItemLink
                StaticPopup_Show("IAAM.Popup_AddItem")
            end
        end
    end
end

--============================================================
--
--             IAAM_FRAME_OnHide()
--
function IAAM_FRAME_OnHide(self)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_OnHide()")
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

--============================================================
--
--             IAAM_FRAME_OnLoad()
--
--  Main entry point of this --addon
--
function IAAM_FRAME_OnLoad(self)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_OnLoad()")
    IAAM_Frame.Page = 1
    --
    -- Get toc version for this build
    --
    _, _, _, IAAM.TocVersion = GetBuildInfo()
    --
    -- Make window movable
    --
    self:RegisterForDrag("LeftButton")
    --
    -- Set up item buttons
    --
    for i = 1, IAAM.ITEMS_PER_PAGE do
        local ItemButton = _G["IAAM_Frame_Item"..i.."ItemButton"]
        ItemButton:SetScript("OnClick", IAAM.FRAME_ItemButton_OnClick)
        ItemButton:SetScript("OnEnter", IAAM.FRAME_Item_OnEnter)
        ItemButton:SetScript("OnLeave", IAAM.FRAME_Item_OnLeave)
        ItemButton.UpdateTooltip = IAAM.FRAME_Item_OnEnter
    end
    --
    -- Set core event handlers
    --
    for Key in pairs(IAAM.EVENT_Handlers) do
        _G[self:GetName()][Key] = IAAM.EVENT_Handlers[Key]
        _G[self:GetName()]:RegisterEvent(Key)
        IAAM.DEBUG_Print(false, "Core: Registered event: " .. Key)
    end
end

--============================================================
--
--             IAAM.FRAME_HideItems()
--
function IAAM.FRAME_HideItems()
    IAAM.DEBUG_Print(false, "IAAM.FRAME_HideItems()")
    for i = 1, IAAM.ITEMS_PER_PAGE do
        _G["IAAM_Frame_Item"..i]:Hide()
    end
end

--============================================================
--
--             IAAM_FRAME_OnShow()
--
function IAAM_FRAME_OnShow(self)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_OnShow()")
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    local Name = self.Name
    if Name == nil then
        self:Hide()
    else
        IAAM_Frame_Title:SetText(Name)
        if Name == IAAM.CORE_GetName("player") then
            SetPortraitTexture(IAAM_FramePortrait, "player")
        else
            SetPortraitTexture(IAAM_FramePortrait, "target")
        end
    end
    IAAM_Frame_Page:SetText(IAAM.FRAME_GetPageString())
    IAAM.FRAME_Update()
end

--============================================================
--
--             IAAM_FRAME_OnMouseWheel()
--
function IAAM_FRAME_OnMouseWheel(self, value)
    IAAM.DEBUG_Print(false, "IAAM_FRAME_OnMouseWheel()")
  if value > 0 then
    if IAAM.PrevPageButton:IsShown() and IAAM.PrevPageButton:IsEnabled() then
      IAAM.FRAME_PrevPageButton_OnClick(self);
    end
  else
    if IAAM.NextPageButton:IsShown() and IAAM.NextPageButton:IsEnabled() then
      IAAM.FRAME_NextPageButton_OnClick(self);
    end
  end
end

--============================================================
--
--             IAAM.FRAME_Item_OnEnter()
--
function IAAM.FRAME_Item_OnEnter(self)
    IAAM.DEBUG_Print(false, "IAAM.FRAME_Item_OnEnter()")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetMerchantItem(self:GetID())
    GameTooltip_ShowCompareItem(GameTooltip)
    GameTooltip:SetHyperlink(self.link)
end

--============================================================
--
--             IAAM.FRAME_Item_OnLeave()
--
function IAAM.FRAME_Item_OnLeave(self)
    IAAM.DEBUG_Print(false, "IAAM.FRAME_Item_OnLeave()")
    GameTooltip:Hide()
end

--============================================================
--
--             IAAM.FRAME_OpenPlayer()
--
function IAAM.FRAME_OpenPlayer(Name)
    IAAM.DEBUG_Print(false, "IAAM.FRAME_OpenPlayer()")
    -- Close merchant window if open
    if IAAM_Frame:IsShown() == true then
        IAAM_Frame:Hide()
    end
    -- If name valid, open new merchant window, no matter if it's the same player
    if IAAM.CORE_IsValidName(Name) then
        IAAM.Merchant.ItemsForSale = {}
        IAAM_Frame.Name = Name
        IAAM.COM_SendRequestItems(Name)
    end
end

--============================================================
--
--             IAAM.FRAME_OpenTarget()
--
function IAAM.FRAME_OpenTarget()
    IAAM.DEBUG_Print(false, "IAAM.FRAME_OpenTarget()")
    -- Close merchant window if open
    local MerchantWindowIsShown = IAAM_Frame:IsShown()
    if MerchantWindowIsShown == true then
        IAAM_Frame:Hide()
    end
    -- Open merchant only if it's not the same target again => Toggle
    local Name = IAAM.CORE_GetName("target")
    if IAAM.CORE_IsValidName(Name) then
        if not (MerchantWindowIsShown == true and Name == IAAM_Frame.Name) then
            IAAM.Merchant.ItemsForSale = {}
            if Name ~= nil then
                IAAM_Frame.Name = Name
                IAAM.COM_SendRequestItems(Name)
            end
        end
    end
end

--============================================================
--
--             IAAM.FRAME_OpenCharacter()
--
function IAAM_FRAME_OpenCharacter()
    IAAM.DEBUG_Print(false, "IAAM_FRAME_OpenCharacter()")
    if IAAM_Frame:IsShown() and IAAM_Frame_Title:GetText() == IAAM.CORE_GetName("player") then
        IAAM_Frame:Hide()
    else
        IAAM_Frame:Hide()
        IAAM.CORE_UpdateList()
        IAAM_Frame.Name = IAAM.CORE_GetName("player")
        IAAM_Frame:Show()
    end
end

--============================================================
--
--             IAAM.FRAME_Update()
--
function IAAM.FRAME_Update()
    ItemsForSale = IAAM.FRAME_GetItemsForSaleTable()
    IAAM.DEBUG_Print(false, "IAAM.FRAME_Update()")

    local NumItems = IAAM.CORE_GetNumItems(ItemsForSale)

    IAAM_Frame_Page:SetText(IAAM.FRAME_GetPageString())

    IAAM.FRAME_HideItems()
    for i = 1, IAAM.ITEMS_PER_PAGE do
        local Index = (((IAAM_Frame.Page - 1) * IAAM.ITEMS_PER_PAGE) + i)
        if Index <= NumItems then
            local Item            = IAAM.CORE_GetItemAt(ItemsForSale, Index)
            local ItemFrame       = _G["IAAM_Frame_Item"..i]
            local ItemFrameButton = _G["IAAM_Frame_Item"..i.."ItemButton"]
            local ItemFrameMoney  = _G["IAAM_Frame_Item"..i.."MoneyFrame"]
            local ItemFrameName   = _G["IAAM_Frame_Item"..i.."Name"]
            IAAM.CORE_QueryItemInfo(Item)
            ItemFrameName:SetText(Item.Name)
            SetItemButtonCount(ItemFrameButton, Item.StackSize)
            SetItemButtonStock(ItemFrameButton, Item.Quantity)
            SetItemButtonTexture(ItemFrameButton, Item.Texture)
            ItemFrameButton.price        = Item.Price
            ItemFrameButton.extendedCost = nil
            ItemFrameButton.name         = Item.Name
            ItemFrameButton.link         = Item.Link
            ItemFrameButton.ItemID       = Item.ID
            ItemFrameButton.texture      = Item.Texture
            MoneyFrame_SetMaxDisplayWidth(ItemFrameMoney, IAAM.MAX_MONEY_DISPLAY_WIDTH)
            MoneyFrame_Update(ItemFrameMoney:GetName(), Item.Price)
            SetMoneyFrameColor(ItemFrameMoney:GetName(), nil)
            MerchantFrameItem_UpdateQuality(ItemFrame, Item.Link);
            ItemFrameButton.showNonrefundablePrompt = false
            ItemFrameButton.hasItem = true;
            ItemFrameButton:SetID(Index);
            ItemFrame:Show()
        end
    end
end