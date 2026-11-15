local _, IAAM = ...

_G.IAAM = IAAM

--============================================================
--============================================================
--
--             Variables
--
IAAM.CORE    = {}
IAAM.VERSION = "2.3.0"

--
-- Labels shown in the key bindings menu. The game looks them up as
-- global variables named BINDING_NAME_<binding name from Bindings.xml>,
-- so these must stay global.
--
BINDING_NAME_OPENPLAYER          = "Open vendor window"
BINDING_NAME_OPENMERCHANTTRACKER = "Open merchant tracker"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.CORE.AddItem()
--
function IAAM.CORE.AddItem(Table, Link, StackSize, Price, Quantity)
    IAAM.DEBUG.Print(false, "IAAM.CORE.AddItem(", Table, ", "..Link..", "..StackSize..", "..Price..", "..Quantity..")")
    Table[""..Link]           = {}
    Table[""..Link].Link      = Link
    Table[""..Link].StackSize = StackSize
    Table[""..Link].Price     = Price
    Table[""..Link].Quantity  = Quantity
    IAAM.CORE.QueryItemInfo(Table[""..Link])
end

--============================================================
--
--             IAAM.CORE.UpdateList()
--
function IAAM.CORE.UpdateList()
    for k, v in pairs(IAAM_Character.ItemsForSale) do
        v.Quantity = C_Item.GetItemCount(v.Link, true, true)
    end
end

--=============================================================
--
--             IAAM.CORE.IsValidUnitID()
--
function IAAM.CORE.IsValidUnitID(UnitID)
    return UnitIsPlayer(UnitID) and UnitExists(UnitID) and UnitIsFriend("player", UnitID)
end

--=============================================================
--
--             IAAM.CORE.IsValidName()
--
function IAAM.CORE.IsValidName(UnitName)
    return UnitName ~= _G["UNKNOWN"] and UnitName ~= _G["UNKNOWNOBJECT"]
end

--============================================================
--
--             IAAM.CORE.RemoveRealmFromName()
--
function IAAM.CORE.RemoveRealmFromName(UnitName)
    return string.sub(UnitName, string.find(UnitName, "[^-]+"))
end

--============================================================
--
--             IAAM.CORE.GetName()
--
function IAAM.CORE.GetName(UnitID)
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
--             IAAM.CORE.GetNumItems()
--
function IAAM.CORE.GetNumItems(Table)
    local Num = 0
    for _, _ in pairs(Table) do
        Num = Num + 1
    end
    return Num
end

--============================================================
--
--             IAAM.CORE.GetData()
--
function IAAM.CORE.GetData(Data)
    IAAM.DEBUG.Print(false, "IAAM.CORE.GetData()")
    local Index = 1
    local Table = {}
    local Link, Data = IAAM.LINK.Get(Data)
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
--             IAAM.CORE.QueryItemInfo()
--
function IAAM.CORE.QueryItemInfo(Item)
    --
    -- Query only if information is missing
    --
    if Item.Texture == nil or Item.ID == nil then
        local Name, _, _, _, _, _, _, _, _, Texture = C_Item.GetItemInfo(Item.Link)
        Item.Name    = Name
        Item.Texture = Texture
        Item.ID      = C_Item.GetItemInfoInstant(Item.Link)
    end
end

--============================================================
--
--             IAAM.CORE.GetItemAt()
--
function IAAM.CORE.GetItemAt(Table, Index)
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
--             IAAM.CORE.PrintCommands()
--
function IAAM.CORE.PrintCommands(index)
    print(" ")
    print("IAmAMerchant (v"..IAAM.VERSION..")")
    print(" ")
    print("Slash command list:")
    print("/iaam add <item_link> <item_count> <price>")
    print("/iaam toggleshowall")
    print("/iaam clear")
    print("/iaam diag - test communication with this character only")
    print("/iaam diag <name> - test communication with another player")
    print("/iaam diag show - show the last diagnosis report")
end

--============================================================
--
--             IAAM.CORE.CopyTable()
--
function IAAM.CORE.CopyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end