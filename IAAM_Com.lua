
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

IAAM_COM_COMMAND_CheckPlayer            = "a"
IAAM_COM_COMMAND_CheckPlayerResponse    = "b"
IAAM_COM_COMMAND_RequestItems           = "c"
IAAM_COM_COMMAND_RequestItemsResponse   = "d"
IAAM_COM_COMMAND_QueryBroadcast         = "e"
IAAM_COM_COMMAND_QueryBroadcastResponse = "f"

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
--             IAAM_COM_SendRequestItems()
--
function IAAM_COM_SendRequestItems(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_SendRequestItems("..UnitName..")")
    if C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_RequestItems, "WHISPER", UnitName) == false then
        IAAM_DEBUG_Print(false, "IAAM_COM_SendRequestItems: Could not send addon message.")
    end
end

--============================================================
--
--             IAAM_COM_SendItem()
--
function IAAM_COM_SendItem(UnitName, Link, Count, Price)
    IAAM_DEBUG_Print(false, "IAAM_COM_SendItem("..UnitName..", "..Link..", "..Count..", "..Price..")")
    local DataString = IAAM_COM_COMMAND_RequestItemsResponse.." "..Link.." "..Count.." "..Price.." "..GetItemCount(Link, true, true)
    C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, DataString, "WHISPER", UnitName)
end

--============================================================
--
--             IAAM_COM_CheckPlayer()
--
function IAAM_COM_CheckPlayer(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_CheckPlayer("..UnitName..") NumItems: ", IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale))
    --
    -- Check if the player is a merchant
    --
    if IAAM_CORE_IsValidName(UnitName) then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_CheckPlayer, "WHISPER", UnitName)
    end
end

--============================================================
--
--             IAAM_COM_CheckPlayerResponse()
--
function IAAM_COM_CheckPlayerResponse(UnitName)
    IAAM_DEBUG_Print(false, "IAAM_COM_CheckPlayerResponse("..UnitName..") NumItems: ", IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale))
    --
    -- Check if the player is a merchant
    --
    if IAAM_CORE_IsValidName(UnitName) then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_CheckPlayerResponse.." "..IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", UnitName)
    end
end

--============================================================
--
--             IAAM_COM_QueryBroadcastYell()
--
function IAAM_COM_QueryBroadcastYell()
    IAAM_DEBUG_Print(false, "IAAM_COM_QueryBroadcastYell()")
    if IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale) > 0 then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_QueryBroadcast, "YELL")
    end
end

--============================================================
--
--             IAAM_COM_QueryBroadcastGuild()
--
function IAAM_COM_QueryBroadcastGuild()
    IAAM_DEBUG_Print(false, "IAAM_COM_QueryBroadcastGuild()")
    if IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale) > 0 then
        C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_QueryBroadcast, "GUILD")
    end
end

--============================================================
--
--             IAAM_COM_QueryBroadcastResponse()
--
function IAAM_COM_QueryBroadcastResponse(Target)
    IAAM_DEBUG_Print(false, "IAAM_COM_QueryBroadcastResponse()")
    C_ChatInfo.SendAddonMessage(IAAM_COM_Channel, IAAM_COM_COMMAND_QueryBroadcastResponse.." "..IAAM_CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", Target)
end
