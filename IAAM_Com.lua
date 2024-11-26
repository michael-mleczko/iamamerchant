local _, IAAM = ...

--============================================================
--============================================================
--
--             Variables
--
IAAM.COM                 = {}
IAAM.COM.Prefix          = "IAAM"
IAAM.COM.ChannelName     = "IAmAMerchant"
IAAM.COM.ChannelPassword = "n7Jndj920Jow"

IAAM.COM.COMMAND                        = {}
IAAM.COM.COMMAND.RequestItems           = "c"
IAAM.COM.COMMAND.RequestItemsResponse   = "d"
IAAM.COM.COMMAND.QueryBroadcast         = "e"
IAAM.COM.COMMAND.QueryBroadcastResponse = "f"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.COM.JoinChannel()
--
function IAAM.COM.JoinChannel()
    --
    -- Check if other channels already exist. If not, wait a bit.
    --
    local NumChannels = GetNumDisplayChannels()
    if NumChannels == 0 then
        C_Timer.After(3, IAAM.COM.JoinChannel)
        return
    end
    --
    -- Initialize message addon channel
    --
    if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM.COM.Prefix) == false then
        C_ChatInfo.RegisterAddonMessagePrefix(IAAM.COM.Prefix)
        if C_ChatInfo.IsAddonMessagePrefixRegistered(IAAM.COM.Prefix) == false then
            IAAM.DEBUG.Print(false, "IAAM.COM.Init: Could not register message prefix.")
        end
    end
    --
    -- Initliaze IAAM channel
    --
    Id = GetChannelName(IAAM.COM.ChannelName)
    if Id == 0 then
        JoinPermanentChannel(IAAM.COM.ChannelName, IAAM.COM.ChannelPassword)
        Id = GetChannelName(IAAM.COM.ChannelName)
        if Id == 0 then
            IAAM.DEBUG.Print(false, "Failed joining communication channel")
        else
            IAAM.DEBUG.Print(false, "Joined communication channel: ", Id)
        end
    else
        IAAM.DEBUG.Print(false, "Already in communication channel")
    end
end

--============================================================
--
--             IAAM.COM.Init()
--
function IAAM.COM.Init()
  IAAM.COM.JoinChannel()
end

--============================================================
--
--             IAAM.COM_SendRequestItems()
--
function IAAM.COM_SendRequestItems(UnitName)
    IAAM.DEBUG.Print(false, "IAAM.COM_SendRequestItems("..UnitName..")")
    if ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM.Prefix, IAAM.COM.COMMAND.RequestItems, "WHISPER", UnitName) == false then
        IAAM.DEBUG.Print(false, "IAAM.COM_SendRequestItems: Could not send addon message.")
    end
end

--============================================================
--
--             IAAM.COM_SendItem()
--
function IAAM.COM_SendItem(UnitName, Link, StackSize, Price)
    IAAM.DEBUG.Print(false, "IAAM.COM_SendItem("..UnitName..", "..Link..", "..StackSize..", "..Price..")")
    local DataString = IAAM.COM.COMMAND.RequestItemsResponse.." "..Link.." "..StackSize.." "..Price.." "..C_Item.GetItemCount(Link, true, true)
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM.Prefix, DataString, "WHISPER", UnitName)
end

--============================================================
--
--             IAAM.COM_QueryBroadcastWorld()
--
function IAAM.COM_QueryBroadcastWorld()
    IAAM.DEBUG.Print(false, "IAAM.COM_QueryBroadcastWorld()")
    Id = GetChannelName(IAAM.COM.ChannelName)
    if Id == 0 then
        IAAM.DEBUG.Print(false, "Cannot send addon data. Communication channel not found. Id: ", Id)
    else
        ChatThrottleLib:SendChatMessage("NORMAL", IAAM.COM.Prefix, IAAM.COM.COMMAND.QueryBroadcast, "CHANNEL", nil, Id)
    end
end

--============================================================
--
--             IAAM.COM_QueryBroadcastGuild()
--
function IAAM.COM_QueryBroadcastGuild()
    IAAM.DEBUG.Print(false, "IAAM.COM_QueryBroadcastGuild()")
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM.Prefix, IAAM.COM.COMMAND.QueryBroadcast, "GUILD")
end

--============================================================
--
--             IAAM.COM_QueryBroadcastResponse()
--
function IAAM.COM_QueryBroadcastResponse(Target)
    IAAM.DEBUG.Print(false, "IAAM.COM_QueryBroadcastResponse()")
    ChatThrottleLib:SendAddonMessage("NORMAL", IAAM.COM.Prefix, IAAM.COM.COMMAND.QueryBroadcastResponse.." "..IAAM.CORE_GetNumItems(IAAM_Character.ItemsForSale), "WHISPER", Target)
end
