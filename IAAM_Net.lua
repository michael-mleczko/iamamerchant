local _, IAAM = ...

--============================================================
--============================================================
--
--             Network (protocol v3)
--
--  How addon users find each other on WoW Forever:
--
--  * Presence: every client joins a hidden chat channel. Its member
--    list contains all addon users, on every internal realm.
--
--  * Reachability: addon messages usually only arrive between players
--    on the same internal realm. Messages to other internal realms are
--    accepted by the game but almost always dropped silently. So a HELLO
--    is whispered to the channel members, and whoever answers is
--    reachable. Players without an answer are asked again later, since
--    a message across internal realms does get through occasionally.
--
--  * Item lists are requested with GETLIST and sent back as one
--    serialized, compressed and Base64-encoded text, split into several
--    LIST messages.
--
--  Messages (prefix IAAM.NET.PREFIX, fields separated by ";"):
--
--    HELLO;<protocol>;<addon version>;<item count>     -> HELLOACK;<same fields>
--    HELLOACK;<protocol>;<addon version>;<item count>
--    GETLIST;<request id>                              -> LIST;<request id>;<index>;<total>;<data>
--    LIST;<request id>;<index>;<total>;<data>
--

IAAM.NET = {}

IAAM.NET.PREFIX           = "IAAM3"
IAAM.NET.PROTOCOL         = 3
IAAM.NET.SEPARATOR        = ";"
IAAM.NET.CHANNEL_NAME     = "IAmAMerchantV3"
IAAM.NET.CHANNEL_PASSWORD = "iaam3"            -- Only keeps players from joining by accident
IAAM.NET.CHUNK_SIZE       = 200                -- Bytes of list data per message (limit is 255 in total)
IAAM.NET.PING_TIMEOUT     = 10                 -- Seconds to wait for HELLOACK
IAAM.NET.PING_INTERVAL    = 120                -- Seconds before asking a player without answer again
IAAM.NET.REACHABLE_RECHECK = 600               -- Seconds before asking a reachable player again
IAAM.NET.MAX_PINGS        = 40                 -- HELLOs per refresh at most
IAAM.NET.LIST_TIMEOUT     = 10                 -- Seconds to wait for the next part of an item list
IAAM.NET.MAX_ITEMS        = 200                -- Items accepted in a received list

IAAM.NET.Peers          = {}    -- Other addon users by name
IAAM.NET.Requests       = {}    -- Item lists requested by this client, by request id
IAAM.NET.Pinged         = {}    -- Time of the last HELLO by name, for the chat filter
IAAM.NET.AutoPing       = false -- True while the merchant tracker is shown
IAAM.NET.OnPeersChanged = nil   -- Called when the peer list changes (set by the merchant tracker)

--============================================================
--
--             Helpers
--

function IAAM.NET.Split(Text)
    return { strsplit(IAAM.NET.SEPARATOR, Text) }
end

function IAAM.NET.Send(Target, Priority, ...)
    if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        return false
    end
    local Message = table.concat({...}, IAAM.NET.SEPARATOR)
    ChatThrottleLib:SendAddonMessage(Priority, IAAM.NET.PREFIX, Message, "WHISPER", Target)
    return true
end

function IAAM.NET.GetPeer(Name)
    local Peer = IAAM.NET.Peers[Name]
    if Peer == nil then
        Peer = { Name = Name, InChannel = false, Reachable = nil, NumItems = nil }
        IAAM.NET.Peers[Name] = Peer
    end
    return Peer
end

function IAAM.NET.NotifyChanged()
    if IAAM.NET.OnPeersChanged then
        IAAM.NET.OnPeersChanged()
    end
end

function IAAM.NET.GetOwnNumItems()
    return IAAM.CORE.GetNumItems(IAAM_Character.ItemsForSale)
end

--
-- Returns the peers sorted for display: reachable players with the
-- most items first, then players without an answer yet, then players
-- that didn't answer. Only players in the channel or reachable ones.
--
function IAAM.NET.GetSortedPeers()
    local List = {}
    for _, Peer in pairs(IAAM.NET.Peers) do
        if Peer.InChannel or Peer.Reachable then
            table.insert(List, Peer)
        end
    end
    local function Rank(Peer)
        if Peer.Reachable == true then
            return 1
        elseif Peer.Reachable == nil then
            return 2
        end
        return 3
    end
    table.sort(List, function(A, B)
        if Rank(A) ~= Rank(B) then
            return Rank(A) < Rank(B)
        end
        if (A.NumItems or 0) ~= (B.NumItems or 0) then
            return (A.NumItems or 0) > (B.NumItems or 0)
        end
        return A.Name < B.Name
    end)
    return List
end

--============================================================
--
--             Channel
--

--
-- Joins the hidden channel. Waits
-- until the game's own channels are joined, so that this channel
-- doesn't take their numbers (e.g. /1 for General).
--
function IAAM.NET.JoinChannel()
    if GetNumDisplayChannels() == 0 then
        C_Timer.After(3, IAAM.NET.JoinChannel)
        return
    end
    if GetChannelName(IAAM.NET.CHANNEL_NAME) == 0 then
        JoinPermanentChannel(IAAM.NET.CHANNEL_NAME, IAAM.NET.CHANNEL_PASSWORD)
    end
    local Tries = 0
    local Ticker
    Ticker = C_Timer.NewTicker(0.5, function()
        Tries = Tries + 1
        if GetChannelName(IAAM.NET.CHANNEL_NAME) ~= 0 then
            Ticker:Cancel()
            IAAM.NET.HideChannel()
            if IAAM.NET.AutoPing then
                IAAM.NET.Refresh(false)
            end
        elseif Tries >= 20 then
            Ticker:Cancel()
            IAAM.DEBUG.Print(false, "IAAM.NET.JoinChannel: could not join "..IAAM.NET.CHANNEL_NAME)
        end
    end)
end

--
-- Removes the channel from all chat windows
--
function IAAM.NET.HideChannel()
    for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
        local ChatFrame = _G["ChatFrame"..i]
        if ChatFrame and ChatFrame.RemoveChannel then
            ChatFrame:RemoveChannel(IAAM.NET.CHANNEL_NAME)
        end
    end
end

function IAAM.NET.FindDisplayIndex()
    for i = 1, GetNumDisplayChannels() do
        local Name, Header = GetChannelDisplayInfo(i)
        if Name and not Header and string.lower(Name) == string.lower(IAAM.NET.CHANNEL_NAME) then
            return i
        end
    end
    return nil
end

--
-- Asks the game for the channel member list. The answer arrives as
-- CHANNEL_ROSTER_UPDATE, see IAAM.NET.ReadRoster.
--
function IAAM.NET.RequestRoster()
    local DisplayIndex = IAAM.NET.FindDisplayIndex()
    if DisplayIndex == nil then
        return false
    end
    IAAM.NET.RosterIndex = DisplayIndex
    SetSelectedDisplayChannel(DisplayIndex)
    return true
end

function IAAM.NET.ReadRoster(DisplayIndex)
    if DisplayIndex ~= IAAM.NET.RosterIndex then
        return
    end
    IAAM.NET.RosterReadTime = GetTime()
    local Me = IAAM.CORE.GetName("player")
    local Count = select(5, GetChannelDisplayInfo(DisplayIndex)) or 0
    local Seen = {}
    for RosterIndex = 1, Count do
        local Name = C_ChatInfo.GetChannelRosterInfo(DisplayIndex, RosterIndex)
        if Name and Name ~= Me then
            Seen[Name] = true
            IAAM.NET.GetPeer(Name).InChannel = true
        end
    end
    for Name, Peer in pairs(IAAM.NET.Peers) do
        if not Seen[Name] then
            Peer.InChannel = false
        end
    end
    if IAAM.NET.AutoPing then
        IAAM.NET.PingPeers(IAAM.NET.ForcePing)
        IAAM.NET.ForcePing = false
    end
    IAAM.NET.NotifyChanged()
end

--============================================================
--
--             Reachability
--

--
-- Reads the channel member list and then sends HELLO to players that
-- haven't been asked recently (or to all, if Force is true).
--
function IAAM.NET.Refresh(Force)
    IAAM.NET.ForcePing = Force or IAAM.NET.ForcePing
    local RequestTime = GetTime()
    IAAM.NET.RosterRequestTime = RequestTime
    if IAAM.NET.RequestRoster() then
        -- If the member list doesn't arrive, ask the players known so far
        C_Timer.After(3, function()
            if IAAM.NET.RosterRequestTime == RequestTime and (IAAM.NET.RosterReadTime or 0) < RequestTime then
                IAAM.NET.PingPeers(IAAM.NET.ForcePing)
                IAAM.NET.ForcePing = false
            end
        end)
    else
        -- Channel not listed (yet): ask the players known so far
        IAAM.NET.PingPeers(IAAM.NET.ForcePing)
        IAAM.NET.ForcePing = false
    end
end

function IAAM.NET.PingPeers(Force)
    local Now = GetTime()
    local Candidates = {}
    for _, Peer in pairs(IAAM.NET.Peers) do
        if Peer.InChannel and not Peer.Pending then
            local Interval = Peer.Reachable and IAAM.NET.REACHABLE_RECHECK or IAAM.NET.PING_INTERVAL
            if Force or Peer.LastPing == nil or Now - Peer.LastPing >= Interval then
                table.insert(Candidates, Peer)
            end
        end
    end
    -- Players never asked first
    table.sort(Candidates, function(A, B)
        return (A.LastPing or 0) < (B.LastPing or 0)
    end)
    for Index = 1, math.min(#Candidates, IAAM.NET.MAX_PINGS) do
        IAAM.NET.Ping(Candidates[Index])
    end
    IAAM.NET.NotifyChanged()
end

function IAAM.NET.Ping(Peer)
    if not IAAM.NET.SendHello(Peer.Name, "HELLO") then
        return
    end
    Peer.Pending = true
    Peer.LastPing = GetTime()
    IAAM.NET.Pinged[Peer.Name] = GetTime()
    local PingTime = Peer.LastPing
    C_Timer.After(IAAM.NET.PING_TIMEOUT, function()
        if Peer.Pending and Peer.LastPing == PingTime then
            Peer.Pending = false
            Peer.Reachable = false
            IAAM.NET.NotifyChanged()
        end
    end)
end

function IAAM.NET.SendHello(Target, Command)
    return IAAM.NET.Send(Target, "NORMAL", Command, tostring(IAAM.NET.PROTOCOL),
        tostring(IAAM.VERSION), tostring(IAAM.NET.GetOwnNumItems()))
end

function IAAM.NET.OnHello(Sender, Parts)
    local Peer = IAAM.NET.GetPeer(Sender)
    Peer.Reachable = true
    Peer.Pending = false
    Peer.Protocol = tonumber(Parts[2])
    Peer.Version = Parts[3]
    Peer.NumItems = tonumber(Parts[4])
    Peer.LastAnswer = GetTime()
    if Parts[1] == "HELLO" then
        IAAM.NET.SendHello(Sender, "HELLOACK")
    end
    IAAM.NET.NotifyChanged()
end

--============================================================
--
--             Item lists
--

--
-- Turns the own items for sale into the text sent with LIST
--
function IAAM.NET.EncodeOwnList()
    IAAM.CORE.UpdateList()
    local List = {}
    for _, Item in pairs(IAAM_Character.ItemsForSale) do
        table.insert(List, {
            Link      = Item.Link,
            StackSize = tonumber(Item.StackSize),
            Price     = tonumber(Item.Price),
            Quantity  = tonumber(Item.Quantity),
        })
    end
    local Serialized = C_EncodingUtil.SerializeCBOR(List)
    local Compressed = C_EncodingUtil.CompressString(Serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.Default)
    return C_EncodingUtil.EncodeBase64(Compressed, Enum.Base64Variant.Standard)
end

--
-- Turns a received LIST text back into items. Only accepts well-formed
-- item links and numbers. Returns nil if the text is damaged.
--
function IAAM.NET.DecodeList(Encoded)
    local Ok, List = pcall(function()
        local Compressed = C_EncodingUtil.DecodeBase64(Encoded, Enum.Base64Variant.Standard)
        local Serialized = C_EncodingUtil.DecompressString(Compressed, Enum.CompressionMethod.Deflate)
        return C_EncodingUtil.DeserializeCBOR(Serialized)
    end)
    if not Ok or type(List) ~= "table" then
        return nil
    end
    local Items = {}
    for Index, Item in ipairs(List) do
        if Index > IAAM.NET.MAX_ITEMS then
            break
        end
        if type(Item) == "table" and type(Item.Link) == "string"
                and string.match(Item.Link, "^|c.-|Hitem:[%-%d:]+|h%[.-%]|h|r$") then
            table.insert(Items, {
                Link      = Item.Link,
                StackSize = math.max(1, math.floor(tonumber(Item.StackSize) or 1)),
                Price     = math.max(0, math.floor(tonumber(Item.Price) or 0)),
                Quantity  = math.max(0, math.floor(tonumber(Item.Quantity) or 0)),
            })
        end
    end
    return Items
end

function IAAM.NET.OnGetList(Sender, Parts)
    local RequestID = Parts[2]
    if RequestID == nil or RequestID == "" then
        return
    end
    local Ok, Encoded = pcall(IAAM.NET.EncodeOwnList)
    if not Ok then
        IAAM.DEBUG.Print(false, "IAAM.NET.OnGetList: encoding failed: "..tostring(Encoded))
        return
    end
    local Total = math.max(1, math.ceil(#Encoded / IAAM.NET.CHUNK_SIZE))
    for Index = 1, Total do
        local Data = string.sub(Encoded, (Index - 1) * IAAM.NET.CHUNK_SIZE + 1, Index * IAAM.NET.CHUNK_SIZE)
        IAAM.NET.Send(Sender, "BULK", "LIST", RequestID, tostring(Index), tostring(Total), Data)
    end
end

--
-- Requests the item list of a player. Calls OnDone with a list of items
-- ({ Link, StackSize, Price, Quantity }), or with nil if the player
-- didn't answer in time.
--
function IAAM.NET.RequestList(Name, OnDone)
    local RequestID = tostring(math.random(100000, 999999))
    local Request = { Name = Name, Parts = {}, Count = 0, OnDone = OnDone }
    IAAM.NET.Requests[RequestID] = Request
    IAAM.NET.Pinged[Name] = GetTime()
    if not IAAM.NET.Send(Name, "ALERT", "GETLIST", RequestID) then
        IAAM.NET.Requests[RequestID] = nil
        OnDone(nil)
        return
    end
    IAAM.NET.ExtendRequest(RequestID)
    return RequestID
end

--
-- (Re)starts the timeout of a request; each received part resets it
--
function IAAM.NET.ExtendRequest(RequestID)
    local Request = IAAM.NET.Requests[RequestID]
    if Request == nil then
        return
    end
    if Request.Timer then
        Request.Timer:Cancel()
    end
    Request.Timer = C_Timer.NewTimer(IAAM.NET.LIST_TIMEOUT, function()
        if IAAM.NET.Requests[RequestID] == Request then
            IAAM.NET.Requests[RequestID] = nil
            Request.OnDone(nil)
        end
    end)
end

function IAAM.NET.OnList(Sender, Parts)
    local RequestID = Parts[2]
    local Request = IAAM.NET.Requests[RequestID]
    local Index, Total = tonumber(Parts[3]), tonumber(Parts[4])
    if Request == nil or Request.Name ~= Sender or Index == nil or Total == nil
            or Index < 1 or Index > Total or Total > 100 then
        return
    end
    if Request.Parts[Index] == nil then
        Request.Parts[Index] = Parts[5] or ""
        Request.Count = Request.Count + 1
    end
    if Request.Count < Total then
        IAAM.NET.ExtendRequest(RequestID)
        return
    end
    IAAM.NET.Requests[RequestID] = nil
    if Request.Timer then
        Request.Timer:Cancel()
    end
    local Items = IAAM.NET.DecodeList(table.concat(Request.Parts))
    if Items then
        local Peer = IAAM.NET.GetPeer(Sender)
        Peer.Reachable = true
        Peer.NumItems = #Items
        IAAM.NET.NotifyChanged()
    end
    Request.OnDone(Items)
end

--============================================================
--
--             Events and chat filters
--

function IAAM.NET.OnAddonMessage(Prefix, Text, Channel, Sender)
    if Prefix ~= IAAM.NET.PREFIX or Channel ~= "WHISPER" or Sender == nil then
        return
    end
    local Parts = IAAM.NET.Split(Text)
    local Command = Parts[1]
    if Command == "HELLO" or Command == "HELLOACK" then
        IAAM.NET.OnHello(Sender, Parts)
    elseif Command == "GETLIST" then
        IAAM.NET.GetPeer(Sender).Reachable = true
        IAAM.NET.OnGetList(Sender, Parts)
    elseif Command == "LIST" then
        IAAM.NET.OnList(Sender, Parts)
    end
end

--
-- Hides "No player named ..." for players asked in the last 30 seconds,
-- e.g. channel members on another ruleset.
--
function IAAM.NET.FilterPlayerNotFound(_, _, Message)
    if type(Message) ~= "string" or type(ERR_CHAT_PLAYER_NOT_FOUND_S) ~= "string"
            or (issecretvalue and issecretvalue(Message)) then
        return false
    end
    local LowerMessage = string.lower(Message)
    local Now = GetTime()
    for Name, Time in pairs(IAAM.NET.Pinged) do
        if Now - Time > 30 then
            IAAM.NET.Pinged[Name] = nil
        elseif LowerMessage == string.lower(string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, Name)) then
            return true
        end
    end
    return false
end

--
-- Hides join/leave notices of the hidden channel
--
function IAAM.NET.FilterChannelNotice(_, _, ...)
    local ChannelBaseName = select(9, ...)
    return ChannelBaseName == IAAM.NET.CHANNEL_NAME
end

function IAAM.NET.Init()
    C_ChatInfo.RegisterAddonMessagePrefix(IAAM.NET.PREFIX)
    if ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter then
        ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", IAAM.NET.FilterPlayerNotFound)
        ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", IAAM.NET.FilterChannelNotice)
    end
    IAAM.NET.Frame = CreateFrame("Frame")
    IAAM.NET.Frame:RegisterEvent("CHAT_MSG_ADDON")
    IAAM.NET.Frame:RegisterEvent("CHANNEL_ROSTER_UPDATE")
    IAAM.NET.Frame:SetScript("OnEvent", function(self, Event, ...)
        if Event == "CHAT_MSG_ADDON" then
            IAAM.NET.OnAddonMessage(...)
        elseif Event == "CHANNEL_ROSTER_UPDATE" then
            IAAM.NET.ReadRoster(...)
        end
    end)
    IAAM.NET.JoinChannel()
end
