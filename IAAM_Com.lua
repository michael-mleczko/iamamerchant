local _, IAAM = ...

--============================================================
--============================================================
--
--             Variables
--

IAAM.COM_Prefix          = "IAAM"
IAAM.COM_Channel         = "IAmAMerchant"
IAAM.COM_ChannelPassword = "n7Jndj920Jow"

IAAM.COM_COMMAND_RequestItems           = "c"
IAAM.COM_COMMAND_RequestItemsResponse   = "d"
IAAM.COM_COMMAND_QueryBroadcast         = "e"
IAAM.COM_COMMAND_QueryBroadcastResponse = "f"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.COM_Init()
--
function IAAM.COM_Init()
    --
    -- Initialize message addon channel
    --
    if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM.COM_Prefix) == false then
        C_ChatInfo.RegisterAddonMessagePrefix(IAAM.COM_Prefix)
        if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM.COM_Prefix) == false then
            IAAM.DEBUG_Print(false, "IAAM.COM_Init: Could not register message prefix.")
        end
    end
    --
    -- Initliaze IAAM channel
    --
    Id = GetChannelName(IAAM.COM_Channel)
    if Id == 0 then
        JoinPermanentChannel(IAAM.COM_Channel, IAAM.COM_ChannelPassword)
        Id = GetChannelName(IAAM.COM_Channel)
        if Id == 0 then
            IAAM.DEBUG_Print(false, "Failed joining communication channel")
        else
            IAAM.DEBUG_Print(false, "Joined communication channel: ", Id)
        end
    else
        IAAM.DEBUG_Print(false, "Already in communication channel")
    end
end

--============================================================
--
--             IAAM.COM_SendRequestItems()
--
function IAAM.COM_SendRequestItems(UnitName)
    IAAM.DEBUG_Print(false, "IAAM.COM_SendRequestItems("..UnitName..")")
    if ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM_Prefix, IAAM.COM_COMMAND_RequestItems, "WHISPER", UnitName) == false then
        IAAM.DEBUG_Print(false, "IAAM.COM_SendRequestItems: Could not send addon message.")
    end
end

--============================================================
--
--             IAAM.COM_SendItem()
--
function IAAM.COM_SendItem(UnitName, Link, StackSize, Price)
    IAAM.DEBUG_Print(false, "IAAM.COM_SendItem("..UnitName..", "..Link..", "..StackSize..", "..Price..")")
    local DataString = IAAM.COM_COMMAND_RequestItemsResponse.." "..Link.." "..StackSize.." "..Price.." "..GetItemCount(Link, true, true)
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM_Prefix, DataString, "WHISPER", UnitName)
end

--============================================================
--
--             IAAM.COM_QueryBroadcastWorld()
--
function IAAM.COM_QueryBroadcastWorld()
    IAAM.DEBUG_Print(false, "IAAM.COM_QueryBroadcastWorld()")
    Id = GetChannelName(IAAM.COM_Channel)
    if Id == 0 then
        IAAM.DEBUG_Print(false, "Cannot send addon data. Communication channel not found. Id: ", Id)
    else
        ChatThrottleLib:SendChatMessage("NORMAL", IAAM.COM_Prefix, IAAM.COM_COMMAND_QueryBroadcast, "CHANNEL", nil, Id)
    end
end

--============================================================
--
--             IAAM.COM_QueryBroadcastGuild()
--
function IAAM.COM_QueryBroadcastGuild()
    IAAM.DEBUG_Print(false, "IAAM.COM_QueryBroadcastGuild()")
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM_Prefix, IAAM.COM_COMMAND_QueryBroadcast, "GUILD")
end

--============================================================
--
--             IAAM.COM_QueryBroadcastResponse()
--
function IAAM.COM_QueryBroadcastResponse(Target)
    IAAM.DEBUG_Print(false, "IAAM.COM_QueryBroadcastResponse()")
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM_Prefix, IAAM.COM_COMMAND_QueryBroadcastResponse.." "..IAAM.CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", Target)
end
