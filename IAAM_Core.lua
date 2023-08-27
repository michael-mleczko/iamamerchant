
--============================================================
--============================================================
--
--             Global variables
--
IAAM_VERSION = "2.1.2"

BINDING_HEADER_IAAM = "IAmAMerchant"
BINDING_NAME_ADDONS = "Addons"

--============================================================
--============================================================
--
--             Local variables
--
local IAAM_MAX_MONEY_DISPLAY_WIDTH = 120
local IAAM_Popup_ItemLink

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM_CORE_AddItem()
--
function IAAM_CORE_AddItem(Table, Link, Count, Price, CountAvailable)
    IAAM_DEBUG_Print(false, "IAAM_CORE_AddItem(", Table, ", "..Link..", "..Count..", "..Price..", "..CountAvailable..")")
    Table[""..Link]                = {}
    Table[""..Link].Link           = Link
    Table[""..Link].Count          = Count
    Table[""..Link].Price          = Price
    Table[""..Link].CountAvailable = CountAvailable
    IAAM_CORE_QueryItemInfo(Table[""..Link])
end

--============================================================
--
--             IAAM_CORE_AddItem()
--
function IAAM_CORE_UpdateList()
    for k, v in pairs(IAAM_Character.ItemsForSale) do
        v.CountAvailable = GetItemCount(v.Link, true, true)
    end
end

--=============================================================
--
--             IAAM_CORE_IsValidUnitID()
--
function IAAM_CORE_IsValidUnitID(UnitID)
    return UnitIsPlayer(UnitID) and UnitExists(UnitID) and UnitIsFriend("player", UnitID)
end

--=============================================================
--
--             IAAM_CORE_IsValidName()
--
function IAAM_CORE_IsValidName(UnitName)
    return UnitName ~= _G["UNKNOWN"] and UnitName ~= _G["UNKNOWNOBJECT"]
end

--============================================================
--
--             IAAM_CORE_RemoveRealmFromName()
--
function IAAM_CORE_RemoveRealmFromName(UnitName)
    return string.sub(UnitName, string.find(UnitName, "[^-]+"))
end

--============================================================
--
--             IAAM_CORE_GetName()
--
function IAAM_CORE_GetName(UnitID)
    if IAAM_TocVersion > 80000 then
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
--             IAAM_CORE_GetNumItems()
--
function IAAM_CORE_GetNumItems(Table)
    local Num = 0
    for _, _ in pairs(Table) do
        Num = Num + 1
    end
    return Num
end

--============================================================
--
--             IAAM_CORE_GetData()
--
function IAAM_CORE_GetData(Data)
    IAAM_DEBUG_Print(false, "IAAM_CORE_GetData()")
    local Index = 1
    local Table = {}
    local Link, Data = IAAM_LINK_Get(Data)
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
--             IAAM_CORE_QueryItemInfo()
--
function IAAM_CORE_QueryItemInfo(Item)
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
--             IAAM_CORE_GetItemAt()
--
function IAAM_CORE_GetItemAt(Table, Index)
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
--             IAAM_CORE_PrintCommands()
--
function IAAM_CORE_PrintCommands(index)
    print("/iaam add <item_link> <item_count> <price>")
    print("/iaam on")
    print("/iaam off")
    print("/iaam clear")
    print("/iaam sound on")
    print("/iaam sound off")
end

--============================================================
--
--             IAAM_CORE_CopyTable()
--
function IAAM_CORE_CopyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end