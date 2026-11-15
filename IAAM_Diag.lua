local _, IAAM = ...

--============================================================
--============================================================
--
--             Diagnosis
--
--  /iaam diag          Tests that only need this character.
--  /iaam diag <name>   Additional tests with a second player who has
--                      this addon version installed. Ideally both
--                      players run it with each other's name.
--  /iaam diag show     Shows the last report again.
--
--  Every client with this addon answers diagnosis messages on its own
--  (see IAAM.DIAG.OnAddonMessage), so a partner only needs to be online.
--
--  The results are printed to chat, shown in a window from which they
--  can be copied, and stored in IAAM_Account.DiagReports (last 5).
--
--  All messages are sent with C_ChatInfo.SendAddonMessage directly
--  instead of ChatThrottleLib, so that the raw result codes of the
--  game are visible in the report.
--

IAAM.DIAG = {}

IAAM.DIAG.PREFIX         = "IAAMDIAG"
IAAM.DIAG.CHANNEL_NAME   = "IAAMDiag"
IAAM.DIAG.SEPARATOR      = ";"
IAAM.DIAG.TIMEOUT        = 6     -- Seconds to wait for an answer
IAAM.DIAG.RUN_TIMEOUT    = 180   -- Seconds after which a run is aborted
IAAM.DIAG.CHANNEL_LINGER = 120   -- Seconds to stay in the channel after the last activity
IAAM.DIAG.BURST_SIZE     = 15
IAAM.DIAG.CHUNK_SIZE     = 200   -- Bytes of payload per message (limit is 255 in total)
IAAM.DIAG.LIST_ITEMS     = 40    -- Items in the test item list
IAAM.DIAG.MAX_REPORTS    = 5
IAAM.DIAG.MAX_INBOX      = 500   -- Received messages to keep

IAAM.DIAG.Running   = false
IAAM.DIAG.RunID     = 0
IAAM.DIAG.Lines     = {}
IAAM.DIAG.Inbox     = {}   -- Received messages of the current session
IAAM.DIAG.Incoming  = {}   -- Incoming chunked lists by sender and token

--============================================================
--
--             Helpers
--

--
-- Returns a value from a dotted global path such as
-- "C_ChatInfo.SendAddonMessage", or nil if any part is missing.
--
function IAAM.DIAG.GetGlobal(Path)
    local Value = _G
    for Part in string.gmatch(Path, "[^%.]+") do
        if type(Value) ~= "table" then
            return nil
        end
        Value = Value[Part]
    end
    return Value
end

function IAAM.DIAG.NewToken()
    return tostring(math.random(100000, 999999))
end

function IAAM.DIAG.Quote(Value)
    if Value == nil then
        return "nil"
    end
    return "\""..tostring(Value).."\""
end

--
-- Simple checksum to compare transferred data
--
function IAAM.DIAG.Checksum(Text)
    local Sum = 0
    for i = 1, #Text do
        Sum = (Sum * 31 + string.byte(Text, i)) % 2147483647
    end
    return Sum
end

--
-- Turns a result code of SendAddonMessage into "Name (Code)"
--
function IAAM.DIAG.ResultName(Result)
    if Enum and Enum.SendAddonMessageResult then
        for Name, Value in pairs(Enum.SendAddonMessageResult) do
            if Value == Result then
                return Name.." ("..tostring(Result)..")"
            end
        end
    end
    return tostring(Result)
end

function IAAM.DIAG.IsSuccess(Result)
    local Success = Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0
    return Result == Success or Result == true
end

--
-- Checks whether a sender name belongs to this character
--
function IAAM.DIAG.IsMe(Sender)
    if Sender == nil then
        return false
    end
    local Name, Realm = UnitFullName("player")
    return Sender == UnitName("player")
        or Sender == GetUnitName("player", true)
        or (Realm ~= nil and Sender == Name.."-"..Realm)
end

--
-- Name of this character as given by the different name functions
--
function IAAM.DIAG.GetOwnNames()
    local Name, Realm = UnitName("player")
    local FullName, FullRealm = UnitFullName("player")
    return string.format("UnitName=%s,%s UnitFullName=%s,%s GetUnitName(true)=%s",
        IAAM.DIAG.Quote(Name), IAAM.DIAG.Quote(Realm),
        IAAM.DIAG.Quote(FullName), IAAM.DIAG.Quote(FullRealm),
        IAAM.DIAG.Quote(GetUnitName("player", true)))
end

--============================================================
--
--             Report
--

function IAAM.DIAG.Add(Status, Format, ...)
    local Text = select("#", ...) > 0 and string.format(Format, ...) or Format
    table.insert(IAAM.DIAG.Lines, string.format("[%s] %s", Status, Text))
end

--============================================================
--
--             Sending and receiving
--

function IAAM.DIAG.Send(ChatType, Target, ...)
    local Message = table.concat({...}, IAAM.DIAG.SEPARATOR)
    return C_ChatInfo.SendAddonMessage(IAAM.DIAG.PREFIX, Message, ChatType, Target)
end

--
-- Returns the first received message with the given command and token
-- whose sender passes the optional filter function.
--
function IAAM.DIAG.FindMessage(Command, Token, SenderFilter)
    for _, Entry in ipairs(IAAM.DIAG.Inbox) do
        if Entry.Command == Command and Entry.Token == Token
                and (SenderFilter == nil or SenderFilter(Entry.Sender)) then
            return Entry
        end
    end
    return nil
end

function IAAM.DIAG.CountMessages(Command, Token)
    local Count = 0
    for _, Entry in ipairs(IAAM.DIAG.Inbox) do
        if Entry.Command == Command and Entry.Token == Token then
            Count = Count + 1
        end
    end
    return Count
end

--
-- Calls Check every 0.2 seconds until it returns a value or Timeout
-- seconds have passed, then calls OnDone with the value (or nil).
--
function IAAM.DIAG.WaitFor(Check, Timeout, OnDone)
    local Start = GetTime()
    local Ticker
    Ticker = C_Timer.NewTicker(0.2, function()
        local Value = Check()
        if Value or GetTime() - Start >= Timeout then
            Ticker:Cancel()
            local Ok, Error = pcall(OnDone, Value)
            if not Ok then
                IAAM.DIAG.Add("ERROR", "%s", tostring(Error))
                IAAM.DIAG.Finish()
            end
        end
    end)
end

--
-- Answers diagnosis messages of other players (and of this character).
-- This runs on every client with the addon, not only during a test.
--
function IAAM.DIAG.OnAddonMessage(Prefix, Text, Channel, Sender)
    if Prefix ~= IAAM.DIAG.PREFIX then
        return
    end
    local Parts = { strsplit(IAAM.DIAG.SEPARATOR, Text) }
    local Command, Token = Parts[1], Parts[2]
    table.insert(IAAM.DIAG.Inbox, {
        Command = Command, Token = Token, Parts = Parts,
        Sender = Sender, Channel = Channel, Time = GetTime(),
    })
    if #IAAM.DIAG.Inbox > IAAM.DIAG.MAX_INBOX then
        table.remove(IAAM.DIAG.Inbox, 1)
    end

    if Command == "PING" then
        --
        -- PING;token;mode  ->  PONG;token;<sender as seen here>;<own names>;<in channel>
        --
        local function Answer()
            local InChannel = GetChannelName(IAAM.DIAG.CHANNEL_NAME) ~= 0 and "1" or "0"
            IAAM.DIAG.Send("WHISPER", Sender, "PONG", Token, Sender, IAAM.DIAG.GetOwnNames(), InChannel)
        end
        if Parts[3] == "partner" then
            IAAM.DIAG.JoinChannel(function() Answer() end)
        else
            Answer()
        end

    elseif Command == "CHUNK" then
        --
        -- CHUNK;token;index;total;data  ->  LISTACK;token;length;checksum;items
        --
        local Key = Sender.."#"..tostring(Token)
        local Index, Total = tonumber(Parts[3]), tonumber(Parts[4])
        if Index == nil or Total == nil then
            return
        end
        local Incoming = IAAM.DIAG.Incoming[Key] or { Parts = {}, Count = 0 }
        IAAM.DIAG.Incoming[Key] = Incoming
        if Incoming.Parts[Index] == nil then
            Incoming.Parts[Index] = Parts[5] or ""
            Incoming.Count = Incoming.Count + 1
        end
        if Incoming.Count == Total then
            IAAM.DIAG.Incoming[Key] = nil
            local Encoded = table.concat(Incoming.Parts)
            local Items = IAAM.DIAG.DecodeList(Encoded)
            IAAM.DIAG.Send("WHISPER", Sender, "LISTACK", Token, tostring(#Encoded),
                tostring(IAAM.DIAG.Checksum(Encoded)), Items)
        end

    elseif Command == "CHPING" then
        --
        -- CHPING;token on the channel  ->  CHSEEN;token (whisper)
        --
        if not IAAM.DIAG.IsMe(Sender) then
            IAAM.DIAG.Send("WHISPER", Sender, "CHSEEN", Token)
        end

    elseif Command == "BURSTEND" then
        --
        -- BURSTEND;token;sent  ->  BURSTACK;token;received
        -- Counts one second later, in case messages arrive out of order.
        --
        C_Timer.After(1, function()
            local Received = IAAM.DIAG.CountMessages("BURST", Token)
            IAAM.DIAG.Send("WHISPER", Sender, "BURSTACK", Token, tostring(Received))
        end)
    end

    IAAM.DIAG.TouchChannel()
end

--============================================================
--
--             Test item list
--

--
-- Builds an item list similar to a real one, including item links,
-- which contain "|" and other special characters.
--
function IAAM.DIAG.BuildList()
    local List = {}
    for i = 1, IAAM.DIAG.LIST_ITEMS do
        local ItemID = 2588 + i
        table.insert(List, {
            Link  = "|cff1eff00|Hitem:"..ItemID.."::::::::60:::::::::|h[Test Item "..i.."]|h|r",
            Count = i % 20 + 1,
            Price = 12345 * i,
        })
    end
    return List
end

--
-- Serialize -> compress -> Base64. Returns the text or nil and an error.
--
function IAAM.DIAG.EncodeList(List)
    return pcall(function()
        local Serialized = C_EncodingUtil.SerializeCBOR(List)
        local Compressed = C_EncodingUtil.CompressString(Serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.Default)
        return C_EncodingUtil.EncodeBase64(Compressed, Enum.Base64Variant.Standard), #Serialized, #Compressed
    end)
end

--
-- Reverse of EncodeList. Returns the number of items or an error text.
--
function IAAM.DIAG.DecodeList(Encoded)
    local Ok, Result = pcall(function()
        local Compressed = C_EncodingUtil.DecodeBase64(Encoded, Enum.Base64Variant.Standard)
        local Serialized = C_EncodingUtil.DecompressString(Compressed, Enum.CompressionMethod.Deflate)
        local List = C_EncodingUtil.DeserializeCBOR(Serialized)
        if type(List) ~= "table" or type(List[1]) ~= "table" or type(List[1].Link) ~= "string" then
            return "ERR:unexpected content"
        end
        return tostring(#List)
    end)
    if Ok then
        return Result
    end
    return "ERR:"..string.gsub(tostring(Result), IAAM.DIAG.SEPARATOR, ",")
end

--============================================================
--
--             Diagnosis channel
--

function IAAM.DIAG.HideChannel()
    for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
        local ChatFrame = _G["ChatFrame"..i]
        if ChatFrame and ChatFrame.RemoveChannel then
            ChatFrame:RemoveChannel(IAAM.DIAG.CHANNEL_NAME)
        end
    end
end

function IAAM.DIAG.JoinChannel(OnDone)
    IAAM.DIAG.TouchChannel()
    if GetChannelName(IAAM.DIAG.CHANNEL_NAME) ~= 0 then
        OnDone(true)
        return
    end
    if type(JoinTemporaryChannel) == "function" then
        IAAM.DIAG.JoinFunction = "JoinTemporaryChannel"
        JoinTemporaryChannel(IAAM.DIAG.CHANNEL_NAME)
    else
        IAAM.DIAG.JoinFunction = "JoinPermanentChannel"
        JoinPermanentChannel(IAAM.DIAG.CHANNEL_NAME)
    end
    IAAM.DIAG.JoinedChannel = true
    IAAM.DIAG.WaitFor(function()
        return GetChannelName(IAAM.DIAG.CHANNEL_NAME) ~= 0
    end, IAAM.DIAG.TIMEOUT, function(Joined)
        if Joined then
            IAAM.DIAG.HideChannel()
        end
        OnDone(Joined)
    end)
end

--
-- Leaves the channel CHANNEL_LINGER seconds after the last activity,
-- but only if the diagnosis joined it.
--
function IAAM.DIAG.TouchChannel()
    if IAAM.DIAG.LeaveTimer then
        IAAM.DIAG.LeaveTimer:Cancel()
        IAAM.DIAG.LeaveTimer = nil
    end
    if IAAM.DIAG.JoinedChannel then
        IAAM.DIAG.LeaveTimer = C_Timer.NewTimer(IAAM.DIAG.CHANNEL_LINGER, function()
            IAAM.DIAG.LeaveTimer = nil
            if not IAAM.DIAG.Running and GetChannelName(IAAM.DIAG.CHANNEL_NAME) ~= 0 then
                LeaveChannelByName(IAAM.DIAG.CHANNEL_NAME)
                IAAM.DIAG.JoinedChannel = false
            end
        end)
    end
end

--
-- Returns the display index of the channel in the channel list
--
function IAAM.DIAG.FindDisplayIndex()
    local Names = {}
    for i = 1, GetNumDisplayChannels() do
        local Name, Header = GetChannelDisplayInfo(i)
        if Name and not Header then
            table.insert(Names, Name)
            if string.lower(Name) == string.lower(IAAM.DIAG.CHANNEL_NAME) then
                return i, Names
            end
        end
    end
    return nil, Names
end

--============================================================
--
--             Test steps
--
--  Every step gets a function Next, which it must call once it is done.
--

IAAM.DIAG.Steps = {}

IAAM.DIAG.API_FUNCTIONS = {
    "C_ChatInfo.SendAddonMessage",
    "C_ChatInfo.SendAddonMessageLogged",
    "C_ChatInfo.InChatMessagingLockdown",
    "C_ChatInfo.AreOutgoingAddonChatMessagesRestricted",
    "C_ChatInfo.GetChannelRosterInfo",
    "C_EncodingUtil.SerializeCBOR",
    "C_EncodingUtil.CompressString",
    "C_EncodingUtil.EncodeBase64",
    "C_NamePlate.GetNamePlateForUnit",
    "JoinTemporaryChannel",
    "JoinPermanentChannel",
    "LeaveChannelByName",
    "GetChannelDisplayInfo",
    "SetSelectedDisplayChannel",
}

function IAAM.DIAG.Steps.Info(Next)
    local Version, Build, BuildDate, Interface = GetBuildInfo()
    IAAM.DIAG.Add("INFO", "Client %s (build %s, %s), interface %s", tostring(Version), tostring(Build), tostring(BuildDate), tostring(Interface))
    IAAM.DIAG.Add("INFO", "Names: %s", IAAM.DIAG.GetOwnNames())
    IAAM.DIAG.Add("INFO", "Trial account: %s, veteran account: %s, in guild: %s, in instance: %s",
        tostring(IsTrialAccount and IsTrialAccount()), tostring(IsVeteranTrialAccount and IsVeteranTrialAccount()),
        tostring(IsInGuild()), tostring((IsInInstance())))

    local Missing = {}
    for _, Path in ipairs(IAAM.DIAG.API_FUNCTIONS) do
        if type(IAAM.DIAG.GetGlobal(Path)) ~= "function" then
            table.insert(Missing, Path)
        end
    end
    if #Missing == 0 then
        IAAM.DIAG.Add("OK", "All %d checked API functions exist", #IAAM.DIAG.API_FUNCTIONS)
    else
        IAAM.DIAG.Add("INFO", "Missing API functions: %s", table.concat(Missing, ", "))
    end

    local Lockdown = C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
    local Restricted = C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()
    IAAM.DIAG.Add("INFO", "InChatMessagingLockdown: %s, AreOutgoingAddonChatMessagesRestricted: %s", tostring(Lockdown), tostring(Restricted))
    if Lockdown then
        IAAM.DIAG.Add("FAIL", "Addon messages are locked down right now. Run the test outside of instances.")
        IAAM.DIAG.Finish()
        return
    end
    Next()
end

function IAAM.DIAG.Steps.JoinChannel(Next)
    IAAM.DIAG.JoinChannel(function(Joined)
        if Joined then
            IAAM.DIAG.Add("OK", "Joined channel %s with %s and hid it in all chat windows", IAAM.DIAG.CHANNEL_NAME, tostring(IAAM.DIAG.JoinFunction or "(already joined)"))
        else
            IAAM.DIAG.Add("FAIL", "Could not join channel %s with %s", IAAM.DIAG.CHANNEL_NAME, tostring(IAAM.DIAG.JoinFunction))
        end
        Next()
    end)
end

--
-- Reads the channel member list and looks for ExpectedName (or this
-- character if ExpectedName is nil).
--
function IAAM.DIAG.Steps.Roster(Next, ExpectedName)
    local DisplayIndex, Names = IAAM.DIAG.FindDisplayIndex()
    if DisplayIndex == nil then
        IAAM.DIAG.Add("FAIL", "Channel not found in the channel list. Listed channels: %s", table.concat(Names, ", "))
        Next()
        return
    end
    IAAM.DIAG.RosterUpdate = nil
    SetSelectedDisplayChannel(DisplayIndex)
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.RosterUpdate == DisplayIndex
    end, IAAM.DIAG.TIMEOUT, function(Updated)
        local Count = select(5, GetChannelDisplayInfo(DisplayIndex)) or 0
        local Members, Found = {}, false
        for RosterIndex = 1, Count do
            local Name = C_ChatInfo.GetChannelRosterInfo(DisplayIndex, RosterIndex)
            if Name then
                table.insert(Members, IAAM.DIAG.Quote(Name))
                if (ExpectedName and Name == ExpectedName) or (ExpectedName == nil and IAAM.DIAG.IsMe(Name)) then
                    Found = true
                end
            end
        end
        IAAM.DIAG.Add("INFO", "Roster update event: %s, member count: %d, names read: %s",
            Updated and "yes" or "no", Count, #Members > 0 and table.concat(Members, ", ", 1, math.min(#Members, 10)) or "none")
        local Who = ExpectedName and "the partner" or "this character"
        if Found then
            IAAM.DIAG.Add("OK", "Channel member list is readable and contains %s", Who)
        elseif #Members > 0 then
            IAAM.DIAG.Add("FAIL", "Channel member list is readable but doesn't contain %s", Who)
        else
            IAAM.DIAG.Add("FAIL", "Channel member list could not be read")
        end
        Next()
    end)
end

function IAAM.DIAG.Steps.WhisperSelf(Next)
    local Token = IAAM.DIAG.NewToken()
    local Target = UnitName("player")
    local Result = IAAM.DIAG.Send("WHISPER", Target, "PING", Token, "self")
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.FindMessage("PONG", Token)
    end, IAAM.DIAG.TIMEOUT, function(Pong)
        if Pong then
            IAAM.DIAG.Add("OK", "Whisper to self (target %s): sent %s, answer from %s, PING sender seen as %s",
                IAAM.DIAG.Quote(Target), IAAM.DIAG.ResultName(Result), IAAM.DIAG.Quote(Pong.Sender), IAAM.DIAG.Quote(Pong.Parts[3]))
        else
            IAAM.DIAG.Add("FAIL", "Whisper to self (target %s): sent %s, no answer", IAAM.DIAG.Quote(Target), IAAM.DIAG.ResultName(Result))
        end
        Next()
    end)
end

function IAAM.DIAG.Steps.PingPartner(Next, Partner)
    local Token = IAAM.DIAG.NewToken()
    local Result = IAAM.DIAG.Send("WHISPER", Partner, "PING", Token, "partner")
    -- The partner joins the channel before answering, so wait longer
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.FindMessage("PONG", Token)
    end, IAAM.DIAG.TIMEOUT * 2, function(Pong)
        if Pong then
            IAAM.DIAG.PartnerName = Pong.Sender
            IAAM.DIAG.Add("OK", "Whisper to partner %s: sent %s, answer from %s",
                IAAM.DIAG.Quote(Partner), IAAM.DIAG.ResultName(Result), IAAM.DIAG.Quote(Pong.Sender))
            IAAM.DIAG.Add("INFO", "Partner sees this character as %s; partner %s; partner in channel: %s",
                IAAM.DIAG.Quote(Pong.Parts[3]), tostring(Pong.Parts[4]), Pong.Parts[5] == "1" and "yes" or "no")
            Next()
        else
            IAAM.DIAG.Add("FAIL", "Whisper to partner %s: sent %s, no answer. The partner may be offline, misspelled, without this addon version, or on a trial/veteran account (those can't send addon messages).",
                IAAM.DIAG.Quote(Partner), IAAM.DIAG.ResultName(Result))
            IAAM.DIAG.Add("SKIP", "Remaining partner tests skipped")
            IAAM.DIAG.Finish()
        end
    end)
end

function IAAM.DIAG.Steps.ListTransfer(Next, Target)
    if type(IAAM.DIAG.GetGlobal("C_EncodingUtil.SerializeCBOR")) ~= "function" then
        IAAM.DIAG.Add("SKIP", "Item list transfer: C_EncodingUtil is missing")
        Next()
        return
    end
    local Ok, Encoded, SerializedSize, CompressedSize = IAAM.DIAG.EncodeList(IAAM.DIAG.BuildList())
    if not Ok then
        IAAM.DIAG.Add("FAIL", "Item list encoding failed: %s", tostring(Encoded))
        Next()
        return
    end
    local Token = IAAM.DIAG.NewToken()
    local Total = math.ceil(#Encoded / IAAM.DIAG.CHUNK_SIZE)
    local Failed = 0
    for Index = 1, Total do
        local Data = string.sub(Encoded, (Index - 1) * IAAM.DIAG.CHUNK_SIZE + 1, Index * IAAM.DIAG.CHUNK_SIZE)
        if not IAAM.DIAG.IsSuccess(IAAM.DIAG.Send("WHISPER", Target, "CHUNK", Token, tostring(Index), tostring(Total), Data)) then
            Failed = Failed + 1
        end
    end
    IAAM.DIAG.Add("INFO", "Item list with %d items: %d bytes serialized, %d compressed, %d as Base64, %d messages (%d not sent)",
        IAAM.DIAG.LIST_ITEMS, SerializedSize, CompressedSize, #Encoded, Total, Failed)
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.FindMessage("LISTACK", Token)
    end, IAAM.DIAG.TIMEOUT + Total, function(Ack)
        local Name = IAAM.DIAG.Quote(Target)
        if Ack == nil then
            IAAM.DIAG.Add("FAIL", "Item list to %s: no confirmation received", Name)
        elseif tonumber(Ack.Parts[3]) == #Encoded and tonumber(Ack.Parts[4]) == IAAM.DIAG.Checksum(Encoded)
                and tonumber(Ack.Parts[5]) == IAAM.DIAG.LIST_ITEMS then
            IAAM.DIAG.Add("OK", "Item list to %s arrived complete and was decoded to %s items", Name, Ack.Parts[5])
        else
            IAAM.DIAG.Add("FAIL", "Item list to %s arrived damaged: length %s (expected %d), items %s",
                Name, tostring(Ack.Parts[3]), #Encoded, tostring(Ack.Parts[5]))
        end
        Next()
    end)
end

--
-- Sends a broadcast to the channel. Checks whether the partner saw it
-- (if Partner is set) and whether it came back to this character.
--
function IAAM.DIAG.Steps.Broadcast(Next, Partner)
    local ChannelID = GetChannelName(IAAM.DIAG.CHANNEL_NAME)
    if ChannelID == 0 then
        IAAM.DIAG.Add("SKIP", "Channel broadcast: not in channel")
        Next()
        return
    end
    local Token = IAAM.DIAG.NewToken()
    local Result = IAAM.DIAG.Send("CHANNEL", tostring(ChannelID), "CHPING", Token)
    IAAM.DIAG.WaitFor(function()
        if Partner then
            return IAAM.DIAG.FindMessage("CHSEEN", Token)
        end
        return IAAM.DIAG.FindMessage("CHPING", Token, IAAM.DIAG.IsMe)
    end, IAAM.DIAG.TIMEOUT, function(Answer)
        local Echo = IAAM.DIAG.FindMessage("CHPING", Token, IAAM.DIAG.IsMe)
        IAAM.DIAG.Add("INFO", "Channel broadcast sent: %s, own message received back: %s",
            IAAM.DIAG.ResultName(Result), Echo and "yes" or "no")
        if Partner then
            if Answer then
                IAAM.DIAG.Add("OK", "Channel broadcast reached the partner (%s)", IAAM.DIAG.Quote(Answer.Sender))
            else
                IAAM.DIAG.Add("FAIL", "Channel broadcast did not reach the partner")
            end
        elseif Echo then
            IAAM.DIAG.Add("OK", "Channel broadcast came back to this character")
        else
            IAAM.DIAG.Add("INCONCLUSIVE", "Own channel broadcast did not come back. It may still reach other players; the partner test decides.")
        end
        Next()
    end)
end

function IAAM.DIAG.Steps.Guild(Next)
    if not IsInGuild() then
        IAAM.DIAG.Add("SKIP", "Guild message: not in a guild")
        Next()
        return
    end
    local Token = IAAM.DIAG.NewToken()
    local Result = IAAM.DIAG.Send("GUILD", nil, "ECHO", Token)
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.FindMessage("ECHO", Token, IAAM.DIAG.IsMe)
    end, IAAM.DIAG.TIMEOUT, function(Echo)
        IAAM.DIAG.Add(Echo and "OK" or "INCONCLUSIVE", "Guild message: sent %s, own message received back: %s",
            IAAM.DIAG.ResultName(Result), Echo and "yes" or "no")
        Next()
    end)
end

--
-- SAY and YELL are addon chat types on Classic. Checks whether Forever
-- still accepts them.
--
function IAAM.DIAG.Steps.SayYell(Next)
    local Results, Tokens = {}, {}
    for _, ChatType in ipairs({ "SAY", "YELL" }) do
        Tokens[ChatType] = IAAM.DIAG.NewToken()
        Results[ChatType] = IAAM.DIAG.Send(ChatType, nil, "ECHO", Tokens[ChatType])
    end
    C_Timer.After(2, function()
        for _, ChatType in ipairs({ "SAY", "YELL" }) do
            local Echo = IAAM.DIAG.FindMessage("ECHO", Tokens[ChatType], IAAM.DIAG.IsMe)
            IAAM.DIAG.Add("INFO", "%s addon message: sent %s, own message received back: %s",
                ChatType, IAAM.DIAG.ResultName(Results[ChatType]), Echo and "yes" or "no")
        end
        Next()
    end)
end

--
-- Sends BURST_SIZE whispers at once and asks the receiver how many
-- arrived. Whispers outside instances should not be throttled.
--
function IAAM.DIAG.Steps.WhisperBurst(Next, Target)
    local Token = IAAM.DIAG.NewToken()
    local Codes = {}
    for Index = 1, IAAM.DIAG.BURST_SIZE do
        local Name = IAAM.DIAG.ResultName(IAAM.DIAG.Send("WHISPER", Target, "BURST", Token, tostring(Index)))
        Codes[Name] = (Codes[Name] or 0) + 1
    end
    IAAM.DIAG.Send("WHISPER", Target, "BURSTEND", Token, tostring(IAAM.DIAG.BURST_SIZE))
    IAAM.DIAG.WaitFor(function()
        return IAAM.DIAG.FindMessage("BURSTACK", Token)
    end, IAAM.DIAG.TIMEOUT, function(Ack)
        local Received = Ack and tonumber(Ack.Parts[3]) or 0
        local Summary = {}
        for Name, Count in pairs(Codes) do
            table.insert(Summary, Count.."x "..Name)
        end
        IAAM.DIAG.Add(Received == IAAM.DIAG.BURST_SIZE and "OK" or "FAIL",
            "Burst of %d whispers to %s: results %s, received %s",
            IAAM.DIAG.BURST_SIZE, IAAM.DIAG.Quote(Target), table.concat(Summary, ", "), Ack and tostring(Received) or "unknown (no answer)")
        Next()
    end)
end

--
-- Sends BURST_SIZE channel messages at once to see when the game starts
-- throttling them. Runs last, as it uses up the prefix's allowance.
--
function IAAM.DIAG.Steps.ChannelBurst(Next)
    local ChannelID = GetChannelName(IAAM.DIAG.CHANNEL_NAME)
    if ChannelID == 0 then
        IAAM.DIAG.Add("SKIP", "Channel burst: not in channel")
        Next()
        return
    end
    local Token = IAAM.DIAG.NewToken()
    local Codes = {}
    for Index = 1, IAAM.DIAG.BURST_SIZE do
        table.insert(Codes, IAAM.DIAG.ResultName(IAAM.DIAG.Send("CHANNEL", tostring(ChannelID), "BURST", Token, tostring(Index))))
    end
    IAAM.DIAG.Add("INFO", "Burst of %d channel messages, results in order: %s", IAAM.DIAG.BURST_SIZE, table.concat(Codes, ", "))
    Next()
end

--============================================================
--
--             Running a diagnosis
--

function IAAM.DIAG.Start(Partner)
    if IAAM.DIAG.Running then
        print("IAmAMerchant: A diagnosis is already running.")
        return
    end
    IAAM.DIAG.Running = true
    IAAM.DIAG.RunID = IAAM.DIAG.RunID + 1
    IAAM.DIAG.Partner = Partner
    IAAM.DIAG.PartnerName = nil
    IAAM.DIAG.Lines = {}

    local Steps = IAAM.DIAG.Steps
    local Run
    if Partner then
        print("IAmAMerchant: Starting partner diagnosis with "..Partner..". This takes about a minute.")
        Run = {
            Steps.Info,
            Steps.JoinChannel,
            function(Next) Steps.PingPartner(Next, Partner) end,
            function(Next) Steps.Roster(Next, IAAM.DIAG.PartnerName) end,
            function(Next) Steps.ListTransfer(Next, Partner) end,
            function(Next) Steps.Broadcast(Next, Partner) end,
            function(Next) Steps.WhisperBurst(Next, Partner) end,
        }
    else
        print("IAmAMerchant: Starting diagnosis. This takes about a minute.")
        Run = {
            Steps.Info,
            Steps.JoinChannel,
            function(Next) Steps.Roster(Next, nil) end,
            Steps.WhisperSelf,
            function(Next) Steps.ListTransfer(Next, UnitName("player")) end,
            function(Next) Steps.Broadcast(Next, nil) end,
            Steps.Guild,
            Steps.SayYell,
            function(Next) Steps.WhisperBurst(Next, UnitName("player")) end,
            Steps.ChannelBurst,
        }
    end

    local RunID = IAAM.DIAG.RunID
    C_Timer.After(IAAM.DIAG.RUN_TIMEOUT, function()
        if IAAM.DIAG.Running and IAAM.DIAG.RunID == RunID then
            IAAM.DIAG.Add("ERROR", "Diagnosis aborted after %d seconds", IAAM.DIAG.RUN_TIMEOUT)
            IAAM.DIAG.Finish()
        end
    end)

    local Index = 0
    local function Next()
        if not IAAM.DIAG.Running or IAAM.DIAG.RunID ~= RunID then
            return
        end
        Index = Index + 1
        local Step = Run[Index]
        if Step == nil then
            IAAM.DIAG.Finish()
            return
        end
        local Ok, Error = pcall(Step, Next)
        if not Ok then
            IAAM.DIAG.Add("ERROR", "Step %d: %s", Index, tostring(Error))
            Next()
        end
    end
    Next()
end

function IAAM.DIAG.Finish()
    if not IAAM.DIAG.Running then
        return
    end
    IAAM.DIAG.Running = false
    IAAM.DIAG.TouchChannel()

    local Counts = { OK = 0, FAIL = 0, INCONCLUSIVE = 0, ERROR = 0 }
    for _, Line in ipairs(IAAM.DIAG.Lines) do
        local Status = string.match(Line, "^%[(%u+)%]")
        if Counts[Status] then
            Counts[Status] = Counts[Status] + 1
        end
    end

    local Header = {
        "IAmAMerchant diagnosis report",
        "Addon version: "..tostring(IAAM.VERSION),
        "Date: "..date("%Y-%m-%d %H:%M:%S"),
        "Mode: "..(IAAM.DIAG.Partner and ("partner test with "..IAAM.DIAG.Partner) or "solo"),
        string.format("Summary: %d OK, %d FAIL, %d INCONCLUSIVE, %d ERROR",
            Counts.OK, Counts.FAIL, Counts.INCONCLUSIVE, Counts.ERROR),
        "",
    }
    local Report = table.concat(Header, "\n").."\n"..table.concat(IAAM.DIAG.Lines, "\n")

    if type(IAAM_Account) == "table" then
        IAAM_Account.DiagReports = IAAM_Account.DiagReports or {}
        table.insert(IAAM_Account.DiagReports, 1, Report)
        while #IAAM_Account.DiagReports > IAAM.DIAG.MAX_REPORTS do
            table.remove(IAAM_Account.DiagReports)
        end
    end

    print("IAmAMerchant: Diagnosis finished. "..Header[5])
    for _, Line in ipairs(IAAM.DIAG.Lines) do
        if string.match(Line, "^%[FAIL%]") or string.match(Line, "^%[ERROR%]") then
            print("  "..Line)
        end
    end
    IAAM.DIAG.ShowReport(Report)
end

function IAAM.DIAG.ShowLastReport()
    local Reports = type(IAAM_Account) == "table" and IAAM_Account.DiagReports
    if Reports and Reports[1] then
        IAAM.DIAG.ShowReport(Reports[1])
    else
        print("IAmAMerchant: No diagnosis report yet. Use /iaam diag first.")
    end
end

--============================================================
--
--             Report window
--
--  Shows the report in a read-only text field, from which it can be
--  copied with Ctrl+A and Ctrl+C.
--

function IAAM.DIAG.ShowReport(Report)
    local Frame = IAAM.DIAG.ReportFrame
    if Frame == nil then
        Frame = CreateFrame("Frame", "IAAM_DiagReportFrame", UIParent, "BasicFrameTemplateWithInset")
        Frame:SetSize(620, 440)
        Frame:SetPoint("CENTER")
        Frame:SetFrameStrata("DIALOG")
        Frame:SetMovable(true)
        Frame:EnableMouse(true)
        Frame:RegisterForDrag("LeftButton")
        Frame:SetScript("OnDragStart", Frame.StartMoving)
        Frame:SetScript("OnDragStop", Frame.StopMovingOrSizing)
        Frame.TitleText:SetText("IAmAMerchant diagnosis report")

        local ScrollFrame = CreateFrame("ScrollFrame", nil, Frame, "UIPanelScrollFrameTemplate")
        ScrollFrame:SetPoint("TOPLEFT", 14, -32)
        ScrollFrame:SetPoint("BOTTOMRIGHT", -34, 44)

        local EditBox = CreateFrame("EditBox", nil, ScrollFrame)
        EditBox:SetMultiLine(true)
        EditBox:SetAutoFocus(false)
        EditBox:SetFontObject(ChatFontNormal)
        EditBox:SetWidth(560)
        EditBox:SetScript("OnEscapePressed", EditBox.ClearFocus)
        EditBox:SetScript("OnTextChanged", function(self, UserInput)
            -- Read-only: undo changes typed by the user
            if UserInput then
                self:SetText(Frame.Report)
            end
        end)
        ScrollFrame:SetScrollChild(EditBox)
        Frame.EditBox = EditBox

        local SelectButton = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate")
        SelectButton:SetSize(120, 22)
        SelectButton:SetPoint("BOTTOMLEFT", 12, 12)
        SelectButton:SetText("Select all")
        SelectButton:SetScript("OnClick", function()
            EditBox:SetFocus()
            EditBox:HighlightText()
        end)

        local Hint = Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        Hint:SetPoint("LEFT", SelectButton, "RIGHT", 10, 0)
        Hint:SetText("Then press Ctrl+C to copy the report.")

        -- Close the window with Escape
        table.insert(UISpecialFrames, "IAAM_DiagReportFrame")
        IAAM.DIAG.ReportFrame = Frame
    end
    Frame.Report = Report
    Frame.EditBox:SetText(Report)
    Frame.EditBox:SetCursorPosition(0)
    Frame:Show()
end

--============================================================
--
--             Events
--

IAAM.DIAG.Frame = CreateFrame("Frame")
IAAM.DIAG.Frame:RegisterEvent("CHAT_MSG_ADDON")
IAAM.DIAG.Frame:RegisterEvent("CHANNEL_ROSTER_UPDATE")
IAAM.DIAG.Frame:SetScript("OnEvent", function(self, Event, ...)
    if Event == "CHAT_MSG_ADDON" then
        IAAM.DIAG.OnAddonMessage(...)
    elseif Event == "CHANNEL_ROSTER_UPDATE" then
        IAAM.DIAG.RosterUpdate = ...
    end
end)

C_ChatInfo.RegisterAddonMessagePrefix(IAAM.DIAG.PREFIX)
