
--[[
SLASH_RELOADUI1       = "/rl"
SlashCmdList.RELOADUI = ReloadUI

SLASH_FRAMESTK1       = "/fs"
SlashCmdList.FRAMESTK = function()
    LoadAddOn("Blizzard_DebugTools")
    FrameStackTooltip_Toggle()
end

for i = 1, NUM_CHAT_WINDOWS do
    _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
end
--]]

--=============================================
--=============================================
--
--        Global variables
--
IAAM_DEBUG   = false
IAAM_VERSION = "0.1.0"

IAAM_Target_ItemsForSale       = {}
IAAM_Channel                   = "IAAM_channel"

--=============================================
--=============================================
--
--        Local variables
--
local IAAM_EventHandlers = {}

local IAAM_ITEMS_PER_PAGE          = 12
local IAAM_MAX_MONEY_DISPLAY_WIDTH = 120

local IAAM_COMMAND_IsVendor   = "IV"
local IAAM_COMMAND_AckVendor  = "AV"
local IAAM_COMMAND_QueryItems = "QI"
local IAAM_COMMAND_Item       = "I"

--=============================================

SLASH_IAAMSlashCommand1 = "/iaam"

--=============================================
--
--        IAAMSlashCommand()
--
function SlashCmdList.IAAMSlashCommand(Message, EditBox)
    IAAM_DebugPrint("Core: Slash command")
    local Table = IAAM_DataToTable(Message)
    if IAAM_GetNumItems(Table) == 0 then
        print("IAmAMerchant: Wrong command!")
        IAAM_PrintCommands()
        return
    end
    if Table[1] == "add" then
        if IAAM_GetNumItems(Table) < 4 then
            print("IAmAMerchant: Wrong command!")
            IAAM_PrintCommands()
            return
        end
        local ItemID = GetItemInfoInstant(Table[2])
        if ItemID == nil then
            print("IAmAMerchant: Couldn't find item!")
            IAAM_PrintCommands()
            return
        end
        if tonumber(Table[3]) == nil or tonumber(Table[4]) == nil then
            print("IAmAMerchant: Wrong parameters!")
            IAAM_PrintCommands()
            return
        end
        IAAM_AddItem(IAAM_Character.ItemsForSale, ItemID, Table[3], Table[4], GetItemCount(ItemID, true, true))
        if UnitIsUnit("player","target") and IAAM_MerchantFrame:IsShown() then
            IAAM_AddItem(IAAM_Target_ItemsForSale, ItemID, Table[3], Table[4], GetItemCount(ItemID, true, true))
            IAAM_MerchantFrame_Update()
        end
        print("IAmAMerchant: Item "..Table[2].." added.")
    elseif Table[1] == "on" then
        IAAM_Character.IsEnabled = true
    elseif Table[1] == "off" then
        IAAM_Character.IsEnabled = false
    elseif Table[1] == "clear" then
        IAAM_Character.ItemsForSale       = {}
    elseif Table[1] == "help" then
        print(" ")
        print("IAmAMerchant (v"..IAAM_VERSION..")")
        print("This is a beta version of the addon IAmAMerchant!")
        print(" ")
        print("Slash command list:")
        IAAM_PrintCommands()
        print(" ")
        print("In order to remove items from you sale list, target yourself and right click the item in the merchant window that you want to remove.")
    else
        print("IAmAMerchant: Wrong command!")
        IAAM_PrintCommands()
    end
end

--=============================================
--=============================================
--
--        Events
--

--=============================================
--
--        IAAM_MerchantFrame_EventHandler()
--
function IAAM_MerchantFrame_EventHandler(self, event, ...)
    IAAM_DebugPrint("Core: Event "..event)
    IAAM_EventHandlers[event](event, ...)
end

--=============================================
--
--        CHAT_MSG_ADDON()
--
function IAAM_EventHandlers.CHAT_MSG_ADDON(event, ...)
    local Prefix, Data, Channel, Sender, Target, _, _, Name, _  = ...;
    local Table = IAAM_DataToTable(Data)
    if Table[1] == IAAM_COMMAND_QueryItems then
        for Key, ItemForSale in pairs(IAAM_Character.ItemsForSale) do
            local ItemString = IAAM_COMMAND_Item.." "..ItemForSale.ID.." "..ItemForSale.Count.." "..ItemForSale.Price.." "..GetItemCount(ItemForSale.ID, true, true)
            C_ChatInfo.SendAddonMessage(IAAM_Channel, ItemString, "WHISPER", Sender)
        end
    elseif Table[1] == IAAM_COMMAND_IsVendor then
        C_ChatInfo.SendAddonMessage(IAAM_Channel, IAAM_COMMAND_AckVendor, "WHISPER", Sender)
    elseif Table[1] == IAAM_COMMAND_AckVendor then
        C_ChatInfo.SendAddonMessage(IAAM_Channel, IAAM_COMMAND_QueryItems, "WHISPER", Sender)
        IAAM_Target_ItemsForSale = {}
        IAAM_MerchantFrame:Show()
    elseif Table[1] == IAAM_COMMAND_Item then
        --                                     ID        Count     Price     CountAvailable
        IAAM_AddItem(IAAM_Target_ItemsForSale, Table[2], Table[3], Table[4], Table[5])
        IAAM_MerchantFrame_Update()
    end
end

--==============================================
--
--        PLAYER_TARGET_CHANGED()
--
function IAAM_EventHandlers.PLAYER_TARGET_CHANGED(event, ...)
    if IAAM_Character.IsEnabled == true and UnitIsPlayer("target") == true then
        IAAM_MerchantFrame:Hide()
        C_ChatInfo.SendAddonMessage(IAAM_Channel, IAAM_COMMAND_IsVendor, "WHISPER", IAAM_GetName("target"))
    else
        IAAM_MerchantFrame:Hide()
    end
end

--==============================================
--
--        GET_ITEM_INFO_RECEIVED()
--
function IAAM_EventHandlers.GET_ITEM_INFO_RECEIVED(event, ...)
    if IAAM_MerchantFrame:IsShown() then
        IAAM_MerchantFrame_Update()
    end
end

--==============================================
--
--        VARIABLES_LOADED()
--
function IAAM_EventHandlers.VARIABLES_LOADED(event, ...)
    IAAM_DebugPrint("Core: Variables loaded")
    if IAAM_Character == nil then
        IAAM_Character = {}
    end
    if IAAM_Character.ItemsForSale == nil then
        IAAM_Character.ItemsForSale       = {}
    end
    if IAAM_Character.IsEnabled == nil then
        IAAM_Character.IsEnabled = true
    end
    print("IAmAMerchant (v"..IAAM_VERSION..")")
end

--=============================================
--=============================================
--
--        Global functions
--

--=============================================
--
--        IAAM_AddItem()
--
function IAAM_AddItem(Table, ItemID, Count, Price, CountAvailable)
    IAAM_DebugPrint("IAAM_AddItem()")
    Table[""..ItemID]                = {}
    Table[""..ItemID].ID             = ItemID
    Table[""..ItemID].Count          = Count
    Table[""..ItemID].Price          = Price
    Table[""..ItemID].CountAvailable = CountAvailable
    IAAM_Target_QueryItemInfo(Table[""..ItemID])
end

--=============================================
--
--        IAAM_GetName()
--
function IAAM_GetName(Unit)
    Name, Realm = UnitFullName(Unit)
    if Realm ==  nil then
        return Name
    else
        return Name.."-"..Realm
    end
end

--=============================================
--
--        IAAM_GetNumItems()
--
function IAAM_GetNumItems(Table)
    local Num = 0
    for _, _ in pairs(Table) do
        Num = Num + 1
    end
    return Num
end

--=============================================
--
--        IAAM_DataToTable()
--
function IAAM_DataToTable(Data)
    IAAM_DebugPrint("IAAM_DataToTable()")
    local Index = 1
    local Table = {}
    --
    -- Get the first word, as this is used as a protocol command
    --
    local TokenIndex = string.find(Data, " ")
    if TokenIndex ~= nil then
        table.insert(Table, string.sub(Data, 1, TokenIndex - 1))
        Data = Data:sub(TokenIndex + 1)
    end
    --
    -- Try to extract item links
    --
    for Word in string.gmatch(Data, "[^%s]+%[.+][^%s]+") do
        local Number = tonumber(Word)
        if Number ~= nil then
            table.insert(Table, Number)
        else
            table.insert(Table, Word)
        end
    end
    --
    -- Remove the extracted item links
    --
    Data = Data:gsub("[^%s]+%[.+][^%s]+", "")
    --
    -- Get the remaining arguments
    --
    for Word in string.gmatch(Data, "%w+") do
        local Number = tonumber(Word)
        if Number ~= nil then
            table.insert(Table, Number)
        else
            table.insert(Table, Word)
        end
    end
    --
    -- Print each element of the table if debug mode is on
    --
    IAAM_DebugPrint("Table:")
    for i in ipairs(Table) do
        IAAM_DebugPrint("    "..Table[i])
    end
    return Table
end

--=============================================
--
--        IAAM_DebugPrint()
--
function IAAM_DebugPrint(...)
    if IAAM_DEBUG == true then
        print("IAAM >> ", ...)
    end
end

--=============================================
--
--        IAAM_Target_QueryItemInfo()
--
function IAAM_Target_QueryItemInfo(Item)
    IAAM_DebugPrint("IAAM_Target_QueryItemInfo()")
    
    local Name, Link, _, _, _, _, _, _, _, Texture = GetItemInfo(Item.ID)
    Item.Name    = Name
    Item.Texture = Texture
    Item.Link    = Link
end

--=============================================
--
--        IAAM_GetItemAt()
--
function IAAM_GetItemAt(Table, Index)
    IAAM_DebugPrint("IAAM_GetItemAt()")
    --
    -- Iterate throgh all elements in the table and return
    -- the element at the position of Index in Item
    --
    for Key, Value in pairs(Table) do
        if Index == 1 then
            return Value
        end
        Index = Index - 1
    end
    return nil
end

--=============================================
--
--        IAAM_PrintCommands()
--
function IAAM_PrintCommands(index)
    print("/iaam add <item_link> <item_count> <price>")
    print("/iaam on")
    print("/iaam off")
    print("/iaam clear")
end

--=============================================
--
--        IAAM_PrintCommands()
--
function IAAM_GetPageString()
    return "Page "..IAAM_MerchantFrame.page.." of "..math.ceil(IAAM_GetNumItems(IAAM_Target_ItemsForSale) / IAAM_ITEMS_PER_PAGE)
end

--=============================================
--
--        IAAM_MerchantFrame_NextPageButton_OnClick()
--
function IAAM_MerchantFrame_NextPageButton_OnClick(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_NextPageButton_OnClick()")
    if IAAM_MerchantFrame.page < ((IAAM_GetNumItems(IAAM_Target_ItemsForSale) / IAAM_ITEMS_PER_PAGE)) then
        IAAM_MerchantFrame.page = IAAM_MerchantFrame.page + 1
        IAAM_MerchantFrame_Page:SetText(IAAM_GetPageString())
        IAAM_MerchantFrame_Update()
    end
end

--=============================================
--
--        IAAM_MerchantFrame_PrevPageButton_OnClick()
--
function IAAM_MerchantFrame_PrevPageButton_OnClick(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_PrevPageButton_OnClick()")
    if IAAM_MerchantFrame.page > 1 then
        IAAM_MerchantFrame.page = IAAM_MerchantFrame.page - 1
        IAAM_MerchantFrame_Page:SetText(IAAM_GetPageString())
        IAAM_MerchantFrame_Update()
    end
end

--=============================================
--
--        IAAM_MerchantFrame_OnHide()
--
function IAAM_MerchantFrame_OnHide(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_OnHide()")
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

--=============================================
--
--        IAAM_MerchantFrame_ItemButton_OnClick()
--
function IAAM_MerchantFrame_ItemButton_OnClick(self, button, down)
    IAAM_DebugPrint("IAAM_MerchantFrame_ItemButton_OnClick()")
    IAAM_DebugPrint(self:GetName())
    if button == "RightButton" then
        if UnitIsUnit("player","target") then
            --
            -- Remove item from your list
            --
            IAAM_Character.ItemsForSale[""..self.ItemID] = nil
            --
            -- Remove item from the queried list
            --
            IAAM_Target_ItemsForSale[""..self.ItemID] = nil
            IAAM_MerchantFrame_Update()
        end
    end
end

--=============================================
--
--        IAAM_MerchantFrame_OnLoad()
--
function IAAM_MerchantFrame_OnLoad(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_OnLoad()")
    IAAM_MerchantFrame.page = 1
    --
    -- Make window movable
    --
    self:RegisterForDrag("LeftButton")
    --
    -- Set up item buttons
    --
    for i = 1, IAAM_ITEMS_PER_PAGE do
        local ItemButton = _G["IAAM_MerchantFrame_Item"..i.."ItemButton"]
        ItemButton:SetScript("OnClick", IAAM_MerchantFrame_ItemButton_OnClick)
        ItemButton:SetScript("OnEnter", IAAM_MerchantFrame_Item_OnEnter)
        ItemButton:SetScript("OnLeave", IAAM_MerchantFrame_Item_OnLeave)
        ItemButton.UpdateTooltip = IAAM_MerchantFrame_Item_OnEnter
    end
    --
    -- Set core event handlers
    --
    for Key in pairs(IAAM_EventHandlers) do
        _G[self:GetName()][Key] = IAAM_EventHandlers[Key]
        _G[self:GetName()]:RegisterEvent(Key)
        IAAM_DebugPrint("Core: Registered event: " .. Key)
    end
    --
    -- Initialize message addon channel
    --
    C_ChatInfo.RegisterAddonMessagePrefix(IAAM_Channel)
    local Result = C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM_Channel)
end

--=============================================
--
--        IAAM_MerchantFrame_HideItems()
--
function IAAM_MerchantFrame_HideItems()
    IAAM_DebugPrint("IAAM_MerchantFrame_HideItems()")
    for i = 1, IAAM_ITEMS_PER_PAGE do
        _G["IAAM_MerchantFrame_Item"..i]:Hide()
    end
end

--=============================================
--
--        IAAM_MerchantFrame_OnShow()
--
function IAAM_MerchantFrame_OnShow(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_OnShow()")
    IAAM_MerchantFrame_HideItems()
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
    local name = IAAM_GetName("target")
    if name == nil then
        self:Hide()
    else                   
        self:SetTitle(name)
        SetPortraitTexture(IAAM_MerchantFramePortrait, "target")
    end
    IAAM_MerchantFrame_Page:SetText(IAAM_GetPageString())
    IAAM_MerchantFrame_Update()
end

--=============================================
--
--        IAAM_MerchantFrame_OnUpdate()
--
function IAAM_MerchantFrame_OnUpdate(self)

end

--=============================================
--
--        IAAM_MerchantFrame_OnMouseWheel()
--
function IAAM_MerchantFrame_OnMouseWheel(self, value)
    IAAM_DebugPrint("IAAM_MerchantFrame_OnMouseWheel()")
	if ( value > 0 ) then
		if ( IAAM_PrevPageButton:IsShown() and IAAM_PrevPageButton:IsEnabled() ) then
			IAAM_MerchantFrame_PrevPageButton_OnClick(self);
		end
	else
		if ( IAAM_NextPageButton:IsShown() and IAAM_NextPageButton:IsEnabled() ) then
			IAAM_MerchantFrame_NextPageButton_OnClick(self);
		end	
	end
end

--=============================================
--
--        IAAM_MerchantFrame_Item_OnEnter()
--
function IAAM_MerchantFrame_Item_OnEnter(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_Item_OnEnter()")
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetMerchantItem(self:GetID())
    GameTooltip_ShowCompareItem(GameTooltip)
    GameTooltip:SetHyperlink("item:"..self.ItemID)
end

--=============================================
--
--        IAAM_MerchantFrame_Item_OnLeave()
--
function IAAM_MerchantFrame_Item_OnLeave(self)
    IAAM_DebugPrint("IAAM_MerchantFrame_Item_OnLeave()")
    GameTooltip:Hide()
end

--=============================================
--
--        IAAM_MerchantFrame_Update()
--
function IAAM_MerchantFrame_Update()
    IAAM_DebugPrint("IAAM_MerchantFrame_Update()")
    local NumItems
    
    NumItems = IAAM_GetNumItems(IAAM_Target_ItemsForSale)
    
    IAAM_MerchantFrame_Page:SetText("Page "..IAAM_MerchantFrame.page.." of "..math.ceil(NumItems / IAAM_ITEMS_PER_PAGE))
    
    IAAM_MerchantFrame_HideItems()
    for i = 1, IAAM_ITEMS_PER_PAGE do
        local Index = (((IAAM_MerchantFrame.page - 1) * IAAM_ITEMS_PER_PAGE) + i)
        if Index <= NumItems then
            local Item            = IAAM_GetItemAt(IAAM_Target_ItemsForSale, Index)
            local ItemFrame       = _G["IAAM_MerchantFrame_Item"..i]
            local ItemFrameButton = _G["IAAM_MerchantFrame_Item"..i.."ItemButton"]
            local ItemFrameMoney  = _G["IAAM_MerchantFrame_Item"..i.."MoneyFrame"]
            local ItemFrameName   = _G["IAAM_MerchantFrame_Item"..i.."Name"]
            IAAM_Target_QueryItemInfo(Item)
            ItemFrameName:SetText(Item.Name)
            SetItemButtonCount(ItemFrameButton, Item.Count)
            SetItemButtonStock(ItemFrameButton, Item.CountAvailable)
            SetItemButtonTexture(ItemFrameButton, Item.Texture)
            ItemFrameButton.price        = Item.Price
			ItemFrameButton.extendedCost = nil
			ItemFrameButton.name         = Item.Name
			ItemFrameButton.link         = Item.Link  -- GetMerchantItemLink(Index)
            ItemFrameButton.ItemID       = Item.ID
            ItemFrameButton.texture      = Item.Texture
			MoneyFrame_SetMaxDisplayWidth(ItemFrameMoney, IAAM_MAX_MONEY_DISPLAY_WIDTH)
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