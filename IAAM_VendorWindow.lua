local _, IAAM = ...

--============================================================
--============================================================
--
--             Variables
--

IAAM.VW                         = {}
IAAM.VW.ITEMS_PER_PAGE          = 12
IAAM.VW.UPDATE_INTERVAL         = 1.0
IAAM.VW.MAX_MONEY_DISPLAY_WIDTH = 120

IAAM.VW.ItemButton        = {}
IAAM.VW.NextPageButton    = {}
IAAM.VW.PrevPageButton    = {}
IAAM.VW.AddItemPopup      = {}
IAAM.VW.AddItemPopup.Link = nil

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.VW.IsOwnShop()
--
--  True if the window shows the items of this character
--
function IAAM.VW.IsOwnShop()
    return IAAM_VW.Name ~= nil and IAAM_VW.Name == IAAM.CORE.GetName("player")
end

--============================================================
--
--             IAAM.VW.GetItemsForSaleTable()
--
function IAAM.VW.GetItemsForSaleTable()
    local Table
    if IAAM.VW.IsOwnShop() then
        Table = IAAM_Character.ItemsForSale
    else
        Table = IAAM.Merchant.ItemsForSale
    end
    return Table
end

--============================================================
--
--             IAAM.VW.GetNumPages()
--
--  An empty list still has one (empty) page.
--
function IAAM.VW.GetNumPages()
    local NumItems = IAAM.CORE.GetNumItems(IAAM.VW.GetItemsForSaleTable())
    return math.max(1, math.ceil(NumItems / IAAM.VW.ITEMS_PER_PAGE))
end

--============================================================
--
--             IAAM.VW.GetPageString()
--
function IAAM.VW.GetPageString(Merchant)
    return "Page "..IAAM_VW.Page.." of "..IAAM.VW.GetNumPages()
end

--============================================================
--
--             IAAM.VW.NextPageButton.OnClick()
--
function IAAM.VW.NextPageButton.OnClick(self)
    IAAM.DEBUG.Print(false, "IAAM_VW.NextPageButton.OnClick()")
    if IAAM_VW.Page < (IAAM.CORE.GetNumItems(IAAM.VW.GetItemsForSaleTable()) / IAAM.VW.ITEMS_PER_PAGE) then
        IAAM_VW.Page = IAAM_VW.Page + 1
        IAAM_VW.FontStringPage:SetText(IAAM.VW.GetPageString())
        IAAM.VW.Update()
    end
end

--============================================================
--
--             IAAM.VW.PrevPageButton.OnClick()
--
function IAAM.VW.PrevPageButton.OnClick(self)
    IAAM.DEBUG.Print(false, "IAAM_VW.PrevPageButton.OnClick()")
    if IAAM_VW.Page > 1 then
        IAAM_VW.Page = IAAM_VW.Page - 1
        IAAM_VW.FontStringPage:SetText(IAAM.VW.GetPageString())
        IAAM.VW.Update()
    end
end

--============================================================
--
--             IAAM.VW.ItemButton.OnClick()
--
function IAAM.VW.ItemButton.OnClick(self, button, down)
    IAAM.DEBUG.Print(false, "IAAM.VW.ItemButton.OnClick()")
    if button == "RightButton" then
        if IAAM_VW.Name == IAAM.CORE.GetName("player") then
            --
            -- Remove item from your list
            --
            IAAM_Character.ItemsForSale[""..self.link] = nil
            IAAM.VW.Update()
        end
    elseif IsShiftKeyDown() and button == "LeftButton" then
        DEFAULT_CHAT_FRAME.editBox:Insert(self.link)
    end
end

--============================================================
--
--             IAAM.VW.AddItemPopup.OnAccept()
--
function IAAM.VW.AddItemPopup.OnAccept(self)
    local StackSize = tonumber(IAAM_PopupExtension.EditBox1:GetText())
    local StackPrice = tonumber(IAAM_PopupExtension.EditBox2:GetText())
    if StackPrice == nil then
        StackPrice = 0
    end
IAAM.CORE.AddItem(IAAM_Character.ItemsForSale, IAAM.VW.AddItemPopup.Link, StackSize, StackPrice, C_Item.GetItemCount(IAAM.VW.AddItemPopup.Link, true, true))
    IAAM.VW.Update()
end

--============================================================
--
--             IAAM.VW.AddItemPopup.OnShow()
--
function IAAM.VW.AddItemPopup.OnShow(self)
    IAAM.VW.AddItemPopup.Frame = self
    IAAM_PopupExtension.EditBox1:SetText("1")
    IAAM_PopupExtension.EditBox2:SetScript("OnEnterPressed", IAAM.VW.AddItemPopup.OnEnterPressed)
    IAAM_PopupExtension.EditBox2:SetScript("OnEscapePressed", IAAM.VW.AddItemPopup.OnEscapePressed)
    IAAM_PopupExtension.EditBox1:SetScript("OnTabPressed", function ()
        IAAM_PopupExtension.EditBox2:SetFocus()
    end)
    IAAM_PopupExtension.EditBox2:SetScript("OnTabPressed", function ()
        IAAM_PopupExtension.EditBox1:SetFocus()
    end)
    IAAM_PopupExtension.EditBox2:SetScript("OnTextChanged", function ()
        local Money = tonumber(IAAM_PopupExtension.EditBox2:GetText()) or 0
        MoneyFrame_Update(IAAM.VW.AddItemPopup.Frame.moneyFrame, Money)
    end)
    IAAM_PopupExtension.EditBox2:SetFocus()
end

--============================================================
--
--             IAAM.VW.AddItemPopup.OnEnterPressed()
--
function IAAM.VW.AddItemPopup.OnEnterPressed(self)
    IAAM.VW.AddItemPopup.OnAccept(IAAM.VW.AddItemPopup.Frame)
    IAAM.VW.AddItemPopup.Frame:Hide()
end

--============================================================
--
--             IAAM.VW.AddItemPopup.OnEscapePressed()
--
function IAAM.VW.AddItemPopup.OnEscapePressed(self)
    IAAM.VW.AddItemPopup.Frame:Hide()
end

--============================================================
--
--             IAAM.VW.OnReceiveDrag()
--
function IAAM.VW.OnReceiveDrag(self)
    local Type, ItemID, ItemLink = GetCursorInfo()
    ClearCursor()
    if IAAM.VW.IsOwnShop() then
        if Type == "item" then
            IAAM.VW.AddItemPopup.Link = ItemLink
            local ItemName, _, ItemQuality = C_Item.GetItemInfo(ItemLink)
            local r, g, b = C_Item.GetItemQualityColor(ItemQuality)
            local ItemTexture = select(10, C_Item.GetItemInfo(ItemLink))
            local Data = {
                texture = ItemTexture,
                name    = ItemName,
                color   = {r, g, b, 1},
                link    = ItemLink,
                index   = ItemID
            }
            StaticPopup_Show("IAAM.VW.AddItemPopup", nil, nil, Data, IAAM_PopupExtension)
        end
    end
end

--============================================================
--
--             IAAM.VW.OnMouseDown()
--
function IAAM.VW.OnMouseDown(self, button)
    if button == "LeftButton" then
        IAAM.VW.OnReceiveDrag(nil)
    end
end

--============================================================
--
--             IAAM.VW.OnHide()
--
function IAAM.VW.OnHide(self)
    IAAM.DEBUG.Print(false, "IAAM.VW.OnHide()")
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
end

--============================================================
--
--             IAAM.VW.OnLoad()
--
function IAAM.VW.OnLoad(self)
    IAAM.DEBUG.Print(false, "IAAM.VW.OnLoad()")
    IAAM_VW.Page = 1
    --
    -- Make window movable
    --
    self:RegisterForDrag("LeftButton")
    --
    -- Set up item buttons
    --
    for i = 1, IAAM.VW.ITEMS_PER_PAGE do
        local ItemButton = IAAM_VW["FrameItem"..i].ItemButton
        ItemButton:SetScript("OnClick", IAAM.VW.ItemButton.OnClick)
        ItemButton:SetScript("OnEnter", IAAM.VW.ItemButton.OnEnter)
        ItemButton:SetScript("OnLeave", IAAM.VW.ItemButton.OnLeave)
        ItemButton.UpdateTooltip = IAAM.VW.ItemButton.OnEnter
    end
    --
    -- Set scripts
    --
    IAAM_VW:SetScript("OnHide", IAAM.VW.OnHide)
    IAAM_VW:SetScript("OnShow", IAAM.VW.OnShow)
    IAAM_VW:SetScript("OnMouseDown", IAAM.VW.OnMouseDown)
    IAAM_VW:SetScript("OnMouseWheel", IAAM.VW.OnMouseWheel)
    IAAM_VW:SetScript("OnReceiveDrag", IAAM.VW.OnReceiveDrag)
    --
    -- Redraw when the game has loaded the data of an item, e.g. of items
    -- received from another player. Several items usually arrive at
    -- once, so the redraws are combined.
    --
    IAAM_VW:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    IAAM_VW:SetScript("OnEvent", function(self, Event)
        if Event == "GET_ITEM_INFO_RECEIVED" and self:IsShown() and not self.UpdatePending then
            self.UpdatePending = true
            C_Timer.After(0.1, function()
                self.UpdatePending = false
                if self:IsShown() then
                    IAAM.VW.Update()
                end
            end)
        end
    end)
    IAAM_VW.NextPageButton:SetScript("OnClick", IAAM.VW.NextPageButton.OnClick)
    IAAM_VW.PrevPageButton:SetScript("OnClick", IAAM.VW.PrevPageButton.OnClick)
end

--============================================================
--
--             IAAM.VW.HideItems()
--
function IAAM.VW.HideItems()
    IAAM.DEBUG.Print(false, "IAAM.VW.HideItems()")
    for i = 1, IAAM.VW.ITEMS_PER_PAGE do
        IAAM_VW["FrameItem"..i]:Hide()
    end
end

--============================================================
--
--             IAAM.VW.OnShow()
--
function IAAM.VW.OnShow(self)
    IAAM.DEBUG.Print(false, "IAAM.VW.OnShow()")
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    local Name = self.Name
    if Name == nil then
        self:Hide()
    else
        IAAM_VW:SetTitle(Name)
        if Name == IAAM.CORE.GetName("player") then
            SetPortraitTexture(IAAM_VWPortrait, "player")
        else
            SetPortraitTexture(IAAM_VWPortrait, Name)
        end
        local _, TextureType = GetTextureInfo(IAAM_VWPortrait)
        if TextureType == "Unknown" then
            ButtonFrameTemplate_HidePortrait(IAAM_VW)
        else
            ButtonFrameTemplate_ShowPortrait(IAAM_VW)
        end
    end
    IAAM_VW.FontStringPage:SetText(IAAM.VW.GetPageString())
    IAAM.VW.Update()
end

--============================================================
--
--             IAAM.VW.OnMouseWheel()
--
function IAAM.VW.OnMouseWheel(self, value)
    IAAM.DEBUG.Print(false, "IAAM.VW.OnMouseWheel()")
  if value > 0 then
    if IAAM_VW.PrevPageButton:IsShown() and IAAM_VW.PrevPageButton:IsEnabled() then
      IAAM.VW.PrevPageButton.OnClick(IAAM_VW.PrevPageButton)
    end
  else
    if IAAM_VW.NextPageButton:IsShown() and IAAM_VW.NextPageButton:IsEnabled() then
        IAAM.VW.NextPageButton.OnClick(IAAM_VW.NextPageButton)
    end
  end
end

--============================================================
--
--             IAAM.VW.ItemButton.OnEnter()
--
function IAAM.VW.ItemButton.OnEnter(self)
    IAAM.DEBUG.Print(false, "IAAM.VW.ItemButton.OnEnter()")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.link)
    GameTooltip_ShowCompareItem(GameTooltip)
end

--============================================================
--
--             IAAM.VW.ItemButton.OnLeave()
--
function IAAM.VW.ItemButton.OnLeave(self)
    IAAM.DEBUG.Print(false, "IAAM.VW.ItemButton.OnLeave()")
    GameTooltip:Hide()
end

--============================================================
--
--             IAAM.VW.Open()
--
function IAAM.VW.Open(Name)
    IAAM.DEBUG.Print(false, "IAAM.VW.Open()")
    -- Close merchant window if open
    if IAAM_VW:IsShown() == true then
        IAAM_VW:Hide()
    end
    -- If name valid, open new merchant window, no matter if it's the same player
    if not IAAM.CORE.IsValidName(Name) then
        return
    end
    --
    -- Request the item list. The window opens when the whole list has
    -- arrived. Only the most recent request opens it.
    --
    local RequestID
    RequestID = IAAM.NET.RequestList(Name, function(Items)
        if RequestID == nil or IAAM.VW.PendingRequest ~= RequestID then
            return
        end
        IAAM.VW.PendingRequest = nil
        if Items == nil then
            print("IAmAMerchant: "..Name.." didn't answer. On WoW Forever, addon messages between players on different internal realms usually don't arrive.")
            return
        end
        IAAM.Merchant.ItemsForSale = {}
        for _, Item in ipairs(Items) do
            IAAM.CORE.AddItem(IAAM.Merchant.ItemsForSale, Item.Link, Item.StackSize, Item.Price, Item.Quantity)
        end
        IAAM_VW.Name = Name
        IAAM_VW.Page = 1
        IAAM_VW:Show()
        IAAM.VW.Update()
    end)
    if RequestID == nil then
        print("IAmAMerchant: Can't send addon messages right now.")
    end
    IAAM.VW.PendingRequest = RequestID
end

--============================================================
--
--             IAAM.VW.Toggle()
--
function IAAM.VW.Toggle(Name)
    IAAM.DEBUG.Print(false, "IAAM.VW.Toggle()")
    if IAAM_VW:IsShown() and IAAM.VW.IsOwnShop() then
        IAAM_VW:Hide()
    else
        IAAM_VW:Hide()
        IAAM.CORE.UpdateList()
        IAAM_VW.Name = Name
        IAAM_VW:Show()
    end
end

--============================================================
--
--             IAAM.VW.Update()
--
function IAAM.VW.Update()
    local ItemsForSale = IAAM.VW.GetItemsForSaleTable()
    IAAM.DEBUG.Print(false, "IAAM.VW.Update()")

    local NumItems = IAAM.CORE.GetNumItems(ItemsForSale)
    --
    -- Stay within the existing pages, e.g. after the last item of the
    -- last page was removed.
    --
    IAAM_VW.Page = math.min(IAAM_VW.Page, IAAM.VW.GetNumPages())

    IAAM_VW.FontStringPage:SetText(IAAM.VW.GetPageString())

    IAAM.VW.HideItems()
    for i = 1, IAAM.VW.ITEMS_PER_PAGE do
        local Index = (((IAAM_VW.Page - 1) * IAAM.VW.ITEMS_PER_PAGE) + i)
        if Index <= NumItems then
            local Item            = IAAM.CORE.GetItemAt(ItemsForSale, Index)
            local ItemFrame       = IAAM_VW["FrameItem"..i]
            local ItemFrameButton = IAAM_VW["FrameItem"..i].ItemButton
            local ItemFrameMoney  = _G["IAAM_VWFrameItem"..i.."MoneyFrame"] -- We need to access a global name, since Blizzard isn't specifying parentKey as they did for ItemButton and other.
            local ItemFrameName   = IAAM_VW["FrameItem"..i].Name
            IAAM.CORE.QueryItemInfo(Item)
            ItemFrameName:SetText(Item.Name or IAAM.CORE.GetNameFromLink(Item.Link))
            SetItemButtonCount(ItemFrameButton, Item.StackSize)
            SetItemButtonStock(ItemFrameButton, Item.Quantity)
            SetItemButtonTexture(ItemFrameButton, Item.Texture)
            ItemFrameButton.price        = Item.Price
            ItemFrameButton.extendedCost = nil
            ItemFrameButton.name         = Item.Name or IAAM.CORE.GetNameFromLink(Item.Link)
            ItemFrameButton.link         = Item.Link
            ItemFrameButton.ItemID       = Item.ID
            ItemFrameButton.texture      = Item.Texture
            MoneyFrame_SetMaxDisplayWidth(ItemFrameMoney, IAAM.VW.MAX_MONEY_DISPLAY_WIDTH)
            MoneyFrame_Update(ItemFrameMoney, Item.Price)
            SetMoneyFrameColor(ItemFrameMoney:GetName(), nil)
            MerchantFrameItem_UpdateQuality(ItemFrame, Item.Link)
            ItemFrameButton.showNonrefundablePrompt = false
            ItemFrameButton.hasItem = true
            ItemFrameButton:SetID(Index)
            ItemFrame:Show()
        end
    end
end

StaticPopupDialogs["IAAM.VW.AddItemPopup"] = {
    text           = "Specify the stack size and stack price:",
    button1        = "Add Item",
    button2        = "Cancel",
    OnAccept       = IAAM.VW.AddItemPopup.OnAccept,
    OnShow         = IAAM.VW.AddItemPopup.OnShow,
    timeout        = 0,
    whileDead      = true,
    hideOnEscape   = true,
  --preferredIndex = 3,
    hasEditBox     = false,
    hasItemFrame   = true,
    hasMoneyFrame  = true,
    height         = 200
}