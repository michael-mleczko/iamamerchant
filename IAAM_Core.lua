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
--             IAAM.CORE.GetName()
--
--  Returns the name of a player unit as used for addon messages.
--
--  On WoW Forever, characters have a first name and a surname.
--  UnitName returns the surname where the realm used to be, and
--  addon messages arrive from "First Surname". The game provides the
--  separator as CHARACTERNAME_SURNAME_SEPARATOR (a space on Forever).
--
function IAAM.CORE.GetName(UnitID)
    local Name, Surname = UnitName(UnitID)
    if Name == nil then
        return nil
    end
    if Surname == nil or Surname == "" then
        return Name
    end
    local Separators = Constants and Constants.CharacterNameSeparatorConsts
    local Separator = type(Separators) == "table" and Separators.CHARACTERNAME_SURNAME_SEPARATOR or " "
    return Name..Separator..Surname
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
    -- Item ID and icon are always available right away
    --
    if Item.ID == nil or Item.Texture == nil then
        local ItemID, _, _, _, Icon = C_Item.GetItemInfoInstant(Item.Link)
        Item.ID      = ItemID
        Item.Texture = Icon
    end
    --
    -- The name needs the item data, which the game may still have to
    -- load (e.g. for items received from other players). Until then,
    -- the name is taken from the item link. GET_ITEM_INFO_RECEIVED
    -- fires once the data has been loaded.
    --
    if Item.Name == nil then
        Item.Name = C_Item.GetItemInfo(Item.Link)
        if Item.Name == nil and Item.ID then
            C_Item.RequestLoadItemDataByID(Item.ID)
        end
    end
end

--
-- Returns the name in square brackets of an item link
--
function IAAM.CORE.GetNameFromLink(Link)
    return string.match(Link or "", "%[(.-)%]")
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