
--============================================================
--============================================================
--
--             Events
--

IAAM_EVENT_Handlers = {}

--============================================================
--
--             IAAM_CORE_EventHandler()
--
function IAAM_EVENT_GlobalHandler(self, Event, ...)
    IAAM_DEBUG_Print(false, "Core: Event "..Event)
    IAAM_EVENT_Handlers[Event](...)
end

--============================================================
--
--             CHAT_MSG_ADDON()
--
function IAAM_EVENT_Handlers.CHAT_MSG_ADDON(...)
    local Prefix, Data, Channel, Sender, Target, _, _, Name, _  = ...;
    --
    -- Remove realm from sender name in Classic WoW
    --
    if IAAM_TocVersion < 80000 then
        Sender = IAAM_CORE_RemoveRealmFromName(Sender)
    end
    --
    -- Extract link and remove link string from data string
    --
    local Link, Data = IAAM_LINK_Get(Data)
    --
    -- Create a table with all arguments
    --
    local Table = IAAM_CORE_GetData(Data)
    --
    -- Table[1] contains the communication command
    --
    local Command = Table[1]
    if Command == IAAM_COM_COMMAND_Item then
        IAAM_DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM_COM_COMMAND_Item")
        --
        -- Item received
        --
        if Sender == IAAM_Frame.Name then
            --                                               Link  Count     Price     CountAvailable
            IAAM_CORE_AddItem(IAAM_Merchant.ItemsForSale, Link, Table[2], Table[3], Table[4])
            if IAAM_Frame:IsShown() == false then
                IAAM_Frame:Show()
            end
            IAAM_FRAME_Update()
        end
    elseif Command == IAAM_COM_COMMAND_Query then
        IAAM_DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM_COM_COMMAND_Query")
        --
        -- Query received from a player.
        -- Send your merchant information.
        --
        for Key, ItemForSale in pairs(IAAM_Character.ItemsForSale) do
            IAAM_COM_SendItem(Sender, ItemForSale.Link, ItemForSale.Count, ItemForSale.Price)
        end
    elseif Command == IAAM_COM_COMMAND_Advertise then
        IAAM_DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM_COM_COMMAND_Advertise")
        --
        -- Received advertising. Re-advertise.
        -- TODO: Inform player about the received advertisement?
        --
        IAAM_COM_ReAdvertise(Sender)
    elseif Command == IAAM_COM_COMMAND_ReAdvertise then
        IAAM_DEBUG_Print(false, "CHAT_MSG_ADDON: IAAM_COM_COMMAND_ReAdvertise")
        --
        -- Received re-advertising.
        -- TODO: Display a GUI frame, e.g. button, so that the player sees the targeted player uses IAmAMerchant.
        --       Button may be grayed out if the player has no items to offer.
        --
    end
end

--=============================================================
--
--             PLAYER_TARGET_CHANGED()
--
function IAAM_EVENT_Handlers.PLAYER_TARGET_CHANGED()
    if IAAM_CORE_IsValidUnitID("target") then
        local Name = IAAM_CORE_GetName("target")
        if Name ~= nil then
            IAAM_COM_Advertise(Name)
        end
    end
end

--=============================================================
--
--             VARIABLES_LOADED()
--
--  Secondary entry point of this addon
--
function IAAM_EVENT_Handlers.VARIABLES_LOADED(event, ...)
    IAAM_DEBUG_Print(false, "Core: Variables loaded")
    
    if type(IAAM_Merchant) ~= "table" then
        IAAM_Merchant = {}
    end
    if type(IAAM_Merchant.ItemsForSale) ~= "table" then
        IAAM_Merchant.ItemsForSale = {}
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
    if type(IAAM_Account) ~= "table" then
        IAAM_Account = {}
    end
    if type(IAAM_Account.Merchants) ~= "table" then
        IAAM_Account.Merchants = {}
    end
    if type(IAAM_Character.IsSoundEnabled) ~= "boolean" then
        IAAM_Character.IsSoundEnabled = false
    end
    IAAM_COM_Init()
    tinsert(UISpecialFrames, "IAAM_Frame")
    print("IAmAMerchant (v"..IAAM_VERSION..")")
end