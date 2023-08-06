
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
        --
        -- Query received from a player.
        -- Send your merchant information.
        --
        for Key, ItemForSale in pairs(IAAM_Character.ItemsForSale) do
            IAAM_COM_SendItem(Sender, ItemForSale.Link, ItemForSale.Count, ItemForSale.Price)
        end
    elseif Command == IAAM_COM_COMMAND_Advertise then
        --
        -- Received advertising. Add player to merchant list and re-advertise.
        --
        if IAAM_CORE_MerchantList[Sender] == nil then
            IAAM_CORE_MerchantList[Sender] = {}
        end
        local ItemCount                          = Table[2]
        IAAM_CORE_MerchantList[Sender].Name      = Sender
        IAAM_CORE_MerchantList[Sender].ItemCount = ItemCount
        IAAM_COM_ReAdvertise(Sender)
        IAAM_NAMEPLATE_Update(Sender)
    elseif Command == IAAM_COM_COMMAND_ReAdvertise then
        --
        -- Received re-advertising. Add player to merchant.
        --
        if IAAM_CORE_MerchantList[Sender] == nil then
            IAAM_CORE_MerchantList[Sender] = {}
        end
        local ItemCount                          = Table[2]
        IAAM_CORE_MerchantList[Sender].Name      = Sender
        IAAM_CORE_MerchantList[Sender].ItemCount = ItemCount
        IAAM_NAMEPLATE_Update(Sender)
    end
end

--=============================================================
--
--             NAME_PLATE_UNIT_ADDED()
--
function IAAM_EVENT_Handlers.NAME_PLATE_UNIT_ADDED(UnitID)
    IAAM_NAMEPLATE_Initialize(UnitID)
    local Name = IAAM_CORE_GetName(UnitID)
    if IAAM_CORE_IsValidUnitID(UnitID) then
        local Name = IAAM_CORE_GetName(UnitID)
        IAAM_COM_Advertise(Name)
    end
end

--=============================================================
--
--             NAME_PLATE_UNIT_REMOVED()
--
function IAAM_EVENT_Handlers.NAME_PLATE_UNIT_REMOVED(UnitID)
    if UnitIsPlayer(UnitID) then
        IAAM_NAMEPLATE_RemoveIcon(UnitID)
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