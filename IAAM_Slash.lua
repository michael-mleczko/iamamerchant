local _, IAAM = ...

--============================================================
--============================================================
--
--             Slash commands
--

IAAM.SLASH = {}

--============================================================
--
--             IAAM.SLASH.HandleCommand()
--
--  Used to:
--    * Add new items
--    * clear the items for sale list
--    * enable or disable iaam
--
function IAAM.SLASH.HandleCommand(Message, EditBox)
    IAAM.DEBUG.Print(false, "Core: Slash command")
    --
    -- Diagnosis: /iaam diag [show | <partner name>]
    -- Handled first, because partner names on Forever contain a space.
    --
    local Command, Argument = string.match(Message, "^%s*(%S+)%s*(.-)%s*$")
    if Command and string.lower(Command) == "diag" then
        if string.lower(Argument) == "show" then
            IAAM.DIAG.ShowLastReport()
        else
            IAAM.DIAG.Start(Argument ~= "" and Argument or nil)
        end
        return
    end
    --
    -- Store space seperated arguments in a table
    --
    local Table = IAAM.CORE.GetData(Message)
    --
    -- Check if table is empty
    --
    if IAAM.CORE.GetNumItems(Table) == 0 then
        IAAM.CORE.PrintCommands()
        return
    end
    --
    -- Which slash command option?
    --
    if Table[1] == "add" then
        --
        -- Check argument count for add command
        --
        if IAAM.CORE.GetNumItems(Table) < 3 then
            print("IAmAMerchant: Wrong command!")
            IAAM.CORE.PrintCommands()
            return
        end
        --
        -- Check if item link is valid
        --
        local ItemID = Table.Link and C_Item.GetItemInfoInstant(Table.Link)
        if ItemID == nil then
            print("IAmAMerchant: Couldn't find item!")
            IAAM.CORE.PrintCommands()
            return
        end
        --
        -- Check if last two arguemtns are numbers
        --
        if tonumber(Table[2]) == nil or tonumber(Table[3]) == nil then
            print("IAmAMerchant: Wrong parameters!")
            IAAM.CORE.PrintCommands()
            return
        end
        --
        -- Add item to list characters for sale list
        --
        IAAM.CORE.AddItem(IAAM_Character.ItemsForSale, Table.Link, Table[2], Table[3], C_Item.GetItemCount(Table.Link, true, true))
        --
        -- If own merchant window is open, add it to targets for sale list and update the window
        -- so that the added item will be displayed instantly
        --
        if IAAM_VW:IsShown() then
            IAAM.VW.Update()
        end
        print("IAmAMerchant: Item "..Table.Link.." added.")
    elseif Table[1] == "toggleshowall" then
        if IAAM_Character.ShowAll == false then
            IAAM_Character.ShowAll = true
            print("IAmAMerchant now also shows merchants that have nothing for sale.")
        else
            print("IAmAMerchant now only shows merchants that have items for sale.")
            IAAM_Character.ShowAll = false
        end
        if IAAM_MT:IsShown() then
            IAAM_MT:UpdateList()
        end
    elseif Table[1] == "clear" then
        IAAM_Character.ItemsForSale = {}
        if IAAM_VW:IsShown() then
            IAAM_VW.Page = 1
            IAAM.VW.Update()
        end
    else
        print("IAmAMerchant: Wrong command!")
        IAAM.CORE.PrintCommands()
    end
end

--
-- Register /iaam. The game links SLASH_<KEY>1 to SlashCmdList.<KEY>,
-- so both must stay global.
--
SLASH_IAMAMERCHANT1      = "/iaam"
SlashCmdList.IAMAMERCHANT = IAAM.SLASH.HandleCommand
