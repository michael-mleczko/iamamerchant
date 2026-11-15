local _, IAAM = ...

--============================================================
--============================================================
--
--             Events
--

IAAM.EVENT          = {}
IAAM.EVENT.Handlers = {}

--============================================================
--
--             IAAM.EVENT.EventHandler()
--
function IAAM.EVENT.EventHandler(self, Event, ...)
    IAAM.DEBUG.Print(false, "[EVENT] "..Event)
    IAAM.EVENT.Handlers[Event](...)
end


--============================================================
--
--             PORTRAITS_UPDATED()
--
function IAAM.EVENT.Handlers.PORTRAITS_UPDATED(...)
    IAAM.DEBUG.Print(false, "[EVENT] PORTRAITS_UPDATED")
    local UpdateUnit = ...
    if UpdateUnit and UpdateUnit == IAAM_VWPortrait.unit then
        ButtonFrameTemplate_ShowPortrait(IAAM_VW)
        SetPortraitTexture(IAAM_VWPortrait, UpdateUnit)
    end
end

--============================================================
--
--             UNIT_PORTRAIT_UPDATE()
--
function IAAM.EVENT.Handlers.UNIT_PORTRAIT_UPDATE(...)
    IAAM.DEBUG.Print(false, "[EVENT] UNIT_PORTRAIT_UPDATE")
    local UpdateUnit = ...
    if UpdateUnit and UpdateUnit == IAAM_VWPortrait.unit then
        ButtonFrameTemplate_ShowPortrait(IAAM_VW)
        SetPortraitTexture(IAAM_VWPortrait, UpdateUnit)
    end
end

--============================================================
--
--             CHAT_MSG_CHANNEL()
--
function IAAM.EVENT.Handlers.CHAT_MSG_CHANNEL(...)
    Data, Sender, _, ChannelName = ...
    --
    -- Handle YELL
    --
    _, ChannelName = strsplit(" ", ChannelName)
    if ChannelName == IAAM.COM.ChannelName then
        if Data == IAAM.COM.COMMAND.QueryBroadcast then
            IAAM.DEBUG.Print(false, "CHAT_MSG_CHANNEL: IAAM.COM.COMMAND.QueryBroadcast")
            IAAM.COM_QueryBroadcastResponse(Sender)
        end
    end
end

--============================================================
--
--             CHAT_MSG_ADDON()
--
function IAAM.EVENT.Handlers.CHAT_MSG_ADDON(...)
    local Prefix, Data, Channel, Sender = ...
    --
    -- CHAT_MSG_ADDON fires for the messages of every addon that registered
    -- a prefix. Only handle messages that were sent by IAmAMerchant.
    --
    if Prefix ~= IAAM.COM.Prefix then
        return
    end
    --
    -- Handle YELL
    --
    if Channel == "YELL" or Channel == "GUILD" or Channel == "CHANNEL" then
        if Data == IAAM.COM.COMMAND.QueryBroadcast then
            IAAM.DEBUG.Print(false, "CHAT_MSG_ADDON: IAAM.COM.COMMAND.QueryBroadcast")
            IAAM.COM_QueryBroadcastResponse(Sender)
        end
    end
    --
    -- Handle WHISPER
    --
    if Channel == "WHISPER" then
        --
        -- Extract link and remove link string from data string
        --
        local Link, Data = IAAM.LINK_Get(Data)
        --
        -- Create a table with all arguments
        --
        local Table = IAAM.CORE_GetData(Data)
        --
        -- Table[1] contains the communication command
        --
        local Command = Table[1]
        if Command == IAAM.COM.COMMAND.RequestItemsResponse then
            IAAM.DEBUG.Print(false, "CHAT_MSG_ADDON: IAAM.COM.COMMAND.RequestItemsResponse")
            --
            -- Item received
            --
            if Sender == IAAM_VW.Name then
                --                                            Link  StackSize Price     Quantity
                IAAM.CORE_AddItem(IAAM.Merchant.ItemsForSale, Link, Table[2], Table[3], Table[4])
                if IAAM_VW:IsShown() == false then
                    IAAM_VW:Show()
                end
                IAAM.VW.Update()
            end
        elseif Command == IAAM.COM.COMMAND.RequestItems then
            IAAM.DEBUG.Print(false, "CHAT_MSG_ADDON: IAAM.COM.COMMAND.RequestItems")
            --
            -- Request item list received from a player.
            -- Send your merchant information.
            --
            for Key, ItemForSale in pairs(IAAM_Character.ItemsForSale) do
                IAAM.COM_SendItem(Sender, ItemForSale.Link, ItemForSale.StackSize, ItemForSale.Price)
            end
        elseif Command == IAAM.COM.COMMAND.QueryBroadcastResponse then
            IAAM.DEBUG.Print(false, "CHAT_MSG_ADDON: IAAM.COM.COMMAND.QueryBroadcastResponse")
            --
            -- Ignore malformed responses without a valid item count
            --
            local NumItems = tonumber(Table[2])
            if NumItems == nil then
                return
            end
            if IAAM_Character.ShowAll == true or NumItems > 0 then
                if IAAM_MT.DataTable ~= nil then  -- Avoid handling received reponses after a reload
                    IAAM_MT.DataTable:InsertTable({
                        { Player = Sender, NumItems = NumItems },
                    })
                end
            end
        end
    end
end

--=============================================================
--
--             VARIABLES_LOADED()
--
--  Secondary entry point of this addon
--
function IAAM.EVENT.Handlers.VARIABLES_LOADED(event, ...)
    IAAM.DEBUG.Print(false, "Core: Variables loaded")
    --
    -- Get toc version for this build
    --
    _, _, _, IAAM.TocVersion = GetBuildInfo()
    --
    -- Initialize variables if not yet done.
    --
    if type(IAAM.Merchant) ~= "table" then
        IAAM.Merchant = {}
    end
    if type(IAAM.Merchant.ItemsForSale) ~= "table" then
        IAAM.Merchant.ItemsForSale = {}
    end
    if type(IAAM_Character) ~= "table" then
        IAAM_Character = {}
    end
    if type(IAAM_Character.ItemsForSale) ~= "table" then
        IAAM_Character.ItemsForSale = {}
    end
    if IAAM_Character.ShowAll == nil then
        IAAM_Character.ShowAll = false
    end
    if type(IAAM_Account) ~= "table" then
        IAAM_Account = {}
    end
    IAAM.COM.Init()
    --
    -- Make frames close on ESC
    --
    tinsert(UISpecialFrames, "IAAM_VW")
    tinsert(UISpecialFrames, "IAAM_MT")
    print("IAmAMerchant (v"..IAAM.VERSION..")")
end

--
-- Initialize event handler
--
IAAM.EVENT.Frame = CreateFrame("FRAME", "EventFrame")
IAAM.EVENT.Frame:SetScript("OnEvent", IAAM.EVENT.EventHandler)
for Key in pairs(IAAM.EVENT.Handlers) do
    --_G[self:GetName()][Key] = IAAM.EVENT.Handlers[Key]
    IAAM.EVENT.Frame:RegisterEvent(Key)
    IAAM.DEBUG.Print(false, "Core: Registered event: "..Key)
end
