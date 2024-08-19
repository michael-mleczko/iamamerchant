local _, IAAM = ...

--============================================================
--============================================================
--
--             Events
--

IAAM.EVENT_Handlers = {}

--============================================================
--
--             IAAM_EVENT_GlobalHandler()
--
function IAAM_EVENT_GlobalHandler(self, Event, ...)
    IAAM.DEBUG_Print(false, "Core: Event "..Event)
    IAAM.EVENT_Handlers[Event](...)
end

--============================================================
--
--             CHAT_MSG_CHANNEL()
--
function IAAM.EVENT_Handlers.CHAT_MSG_CHANNEL(...)
    Data, Sender, _, ChannelName = ...
    --
    -- Handle YELL
    --
    _, ChannelName = strsplit(" ", ChannelName)
    if ChannelName == IAAM.COM_Channel then
        if Data == IAAM.COM_COMMAND_QueryBroadcast then
            IAAM.DEBUG_Print(false, "CHAT_MSG_CHANNEL: IAAM.COM_COMMAND_QueryBroadcast")
            IAAM.COM_QueryBroadcastResponse(Sender)
        end
    end
end

--============================================================
--
--             CHAT_MSG_ADDON()
--
function IAAM.EVENT_Handlers.CHAT_MSG_ADDON(...)
    local Prefix, Data, Channel, Sender, Target, _, _, Name, _  = ...
    --
    -- Handle YELL
    --
    if Channel == "YELL" or Channel == "GUILD" or Channel == "CHANNEL" then
        if Data == IAAM.COM_COMMAND_QueryBroadcast then
            IAAM.DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM.COM_COMMAND_QueryBroadcast")
            IAAM.COM_QueryBroadcastResponse(Target)
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
        if Command == IAAM.COM_COMMAND_RequestItemsResponse then
            IAAM.DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM.COM_COMMAND_RequestItemsResponse")
            --
            -- Item received
            --
            if Target == IAAM_Frame.Name then
                --                                            Link  StackSize Price     Quantity
                IAAM.CORE_AddItem(IAAM.Merchant.ItemsForSale, Link, Table[2], Table[3], Table[4])
                if IAAM_Frame:IsShown() == false then
                    IAAM_Frame:Show()
                end
                IAAM.FRAME_Update()
            end
        elseif Command == IAAM.COM_COMMAND_RequestItems then
            IAAM.DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM.COM_COMMAND_RequestItems")
            --
            -- Request item list received from a player.
            -- Send your merchant information.
            --
            for Key, ItemForSale in pairs(IAAM_Character.ItemsForSale) do
                IAAM.COM_SendItem(Target, ItemForSale.Link, ItemForSale.StackSize, ItemForSale.Price)
            end
        elseif Command == IAAM.COM_COMMAND_QueryBroadcastResponse then
            IAAM.DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM.COM_COMMAND_QueryBroadcastResponse")
            print("ShowAll", IAAM_Character.ShowAll)
            if IAAM_Character.ShowAll == true or Table[2] > 0 then
                if IAAM_MT.DataTable ~= nil then  -- Avoid handling received reponses after a reload
                    IAAM_MT.DataTable:InsertTable({
                        { Player = Target, NumItems = Table[2] },
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
function IAAM.EVENT_Handlers.VARIABLES_LOADED(event, ...)
    IAAM.DEBUG_Print(false, "Core: Variables loaded")

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
    if IAAM_Character.IsEnabled == nil then
        IAAM_Character.IsEnabled = true
    end
    if IAAM_Character.ShowAll == nil then
        IAAM_Character.ShowAll = false
    end
    if type(IAAM.Account) ~= "table" then
        IAAM.Account = {}
    end
    if type(IAAM.Account.Merchants) ~= "table" then
        IAAM.Account.Merchants = {}
    end
    if type(IAAM_Character.IsSoundEnabled) ~= "boolean" then
        IAAM_Character.IsSoundEnabled = false
    end
    IAAM.COM_Init()
    --AutoQueryMixin:Init()
    --
    -- Make frames close on ESC
    --
    tinsert(UISpecialFrames, "IAAM_Frame")
    tinsert(UISpecialFrames, "IAAM_MT")
    print("IAmAMerchant (v"..IAAM.VERSION..")")
end