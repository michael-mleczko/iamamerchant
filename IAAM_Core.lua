local _, IAAM = ...

_G.IAAM = IAAM

--============================================================
--============================================================
--
--             Variables
--
IAAM.CORE    = {}
IAAM.VERSION = "2.3.0"

local BINDING_NAME_OPENPLAYER          = "Open vendor window"
local BINDING_NAME_OPENMERCHANTTRACKER = "Open merchant tracker"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.CORE_AddItem()
--
function IAAM.CORE_AddItem(Table, Link, StackSize, Price, Quantity)
    IAAM.DEBUG.Print(false, "IAAM.CORE_AddItem(", Table, ", "..Link..", "..StackSize..", "..Price..", "..Quantity..")")
    Table[""..Link]           = {}
    Table[""..Link].Link      = Link
    Table[""..Link].StackSize = StackSize
    Table[""..Link].Price     = Price
    Table[""..Link].Quantity  = Quantity
    IAAM.CORE_QueryItemInfo(Table[""..Link])
end

--============================================================
--
--             IAAM.CORE_AddItem()
--
function IAAM.CORE_UpdateList()
    for k, v in pairs(IAAM_Character.ItemsForSale) do
        v.Quantity = C_Item.GetItemCount(v.Link, true, true)
    end
end

--=============================================================
--
--             IAAM.CORE_IsValidUnitID()
--
function IAAM.CORE_IsValidUnitID(UnitID)
    return UnitIsPlayer(UnitID) and UnitExists(UnitID) and UnitIsFriend("player", UnitID)
end

--=============================================================
--
--             IAAM.CORE_IsValidName()
--
function IAAM.CORE_IsValidName(UnitName)
    return UnitName ~= _G["UNKNOWN"] and UnitName ~= _G["UNKNOWNOBJECT"]
end

--============================================================
--
--             IAAM.CORE_RemoveRealmFromName()
--
function IAAM.CORE_RemoveRealmFromName(UnitName)
    return string.sub(UnitName, string.find(UnitName, "[^-]+"))
end

--============================================================
--
--             IAAM.CORE_GetName()
--
function IAAM.CORE_GetName(UnitID)
    if IAAM.TocVersion > 80000 then
        local Name = GetUnitName(UnitID, true)
        if C_PlayerInfo.UnitIsSameServer(PlayerLocation:CreateFromUnit(UnitID)) then
            Name = Name.."-"..GetRealmName()
        end
        return Name
    else
        local Name = GetUnitName(UnitID, true)
        return Name
    end
end

--============================================================
--
--             IAAM.CORE_GetNumItems()
--
function IAAM.CORE_GetNumItems(Table)
    local Num = 0
    for _, _ in pairs(Table) do
        Num = Num + 1
    end
    return Num
end

--============================================================
--
--             IAAM.CORE_GetData()
--
function IAAM.CORE_GetData(Data)
    IAAM.DEBUG.Print(false, "IAAM.CORE_GetData()")
    local Index = 1
    local Table = {}
    local Link, Data = IAAM.LINK_Get(Data)
    if Link ~= nil then
        Table.Link = Link
    end
    --
    -- Transform a string into an array (table).
    --
    for Word in string.gmatch(Data, "%w+") do
        local Number = tonumber(Word)
        if Number ~= nil then
            table.insert(Table, Number)
        else
            table.insert(Table, Word)
        end
    end
    return Table
end

--============================================================
--
--             IAAM.CORE_QueryItemInfo()
--
function IAAM.CORE_QueryItemInfo(Item)
    --
    -- Query only if information is missing
    --
    if Item.Texture == nil or Item.ID == nil then
        local Name, _, _, _, _, _, _, _, _, Texture = GetItemInfo(Item.Link)
        Item.Name    = Name
        Item.Texture = Texture
        Item.ID      = GetItemInfoInstant(Item.Link)
    end
end

--============================================================
--
--             IAAM.CORE_GetItemAt()
--
function IAAM.CORE_GetItemAt(Table, Index)
    --
    -- Iterate throgh all elements in the table and return
    -- the element at the position of Index. Need to used
    -- dictionary to avoid reordering of items in the array.
    ---
    for Key, Value in pairs(Table) do
        if Index == 1 then
            return Value
        end
        Index = Index - 1
    end
    return nil
end

--============================================================
--
--             IAAM.CORE_PrintCommands()
--
function IAAM.CORE_PrintCommands(index)
    print(" ")
    print("IAmAMerchant (v"..IAAM.VERSION..")")
    print(" ")
    print("Slash command list:")
    print("/iaam add <item_link> <item_count> <price>")
    print("/iaam toggleshowall")
    print("/iaam clear")
end

--============================================================
--
--             IAAM.CORE_CopyTable()
--
function IAAM.CORE_CopyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end