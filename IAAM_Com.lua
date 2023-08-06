
--============================================================
--============================================================
--
--             Local variables
--

local IAAM_COM_Channel = "IAAM_COM_Channel"

--============================================================
--============================================================
--
--             Global variables
--

IAAM_COM_COMMAND_Advertise   = "A"
IAAM_COM_COMMAND_ReAdvertise = "B"
IAAM_COM_COMMAND_Query       = "Q"
IAAM_COM_COMMAND_Item        = "I"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM_COM_Init()
--
function IAAM_COM_Init()
    --
    -- Initialize message addon channel
    --
    if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM_COM_Channel) == false then
        C_ChatInfo.RegisterAddonMessagePrefix(IAAM_COM_Channel)
        if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM_COM_Channel) == false then
            IAAM_DEBUG_Print(false, "IAAM_COM_Init: Could not register message prefix.")
        end
    end
end

--============================================================
--
--             IAAM_COM_SendQuery()
--
function IAAM_COM_SendQuery(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_SendQuery("..UnitName..")")
    if C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_Query, "WHISPER", UnitName) == false then
        IAAM_DEBUG_Print(false, "IAAM_COM_SendQuery: Could not send addon message.")
    end
end

--============================================================
--
--             IAAM_COM_SendItem()
--
function IAAM_COM_SendItem(UnitName, Link, Count, Price)
    IAAM_DEBUG_Print(false, "IAAM_COM_SendItem("..UnitName..", "..Link..", "..Count..", "..Price..")")
    local DataString = IAAM_COM_COMMAND_Item.." "..Link.." "..Count.." "..Price.." "..GetItemCount(Link, true, true)
    C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, DataString, "WHISPER", UnitName)
end

--============================================================
--
--             IAAM_COM_Advertise()
--
function IAAM_COM_Advertise(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_Advertise("..UnitName..") NumItems: ", IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale))
    --
    -- Advertise and add your number of items for sale.
    -- If no items are for sale, you won't have a merchant mark for
    -- other players, as we only want to mark players who are selling
    -- something. If one adds an item, all players on the mercahtn list
    -- will be readvertised with the new items for sale number.
    --
    if IAAM_CORE_IsValidName(UnitName) then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_Advertise.." "..IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", UnitName)
    end
end

--============================================================
--
--             IAAM_COM_ReAdvertise()
--
function IAAM_COM_ReAdvertise(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_ReAdvertise("..UnitName..") NumItems: ", IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale))
    --
    -- See IAAM_COM_Advertise
    --
    if IAAM_CORE_IsValidName(UnitName) then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_ReAdvertise.." "..IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", UnitName)
    end
end
