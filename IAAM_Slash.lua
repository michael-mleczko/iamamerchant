local _, IAAM = ...

--============================================================
--============================================================
--
--             Slash commands
--

SLASH_IAAMSlashCommand1 = "/iaam"

--============================================================
--
--             IAAMSlashCommand()
--
--  Used to:
--    * Add new items
--    * clear the items for sale list
--    * enable or disable iaam
--
function SlashCmdList.IAAMSlashCommand(Message, EditBox)
    IAAM.DEBUG.Print(false, "Core: Slash command")
    --
    -- Store space seperated arguments in a table
    --
    local Table = IAAM.CORE_GetData(Message)
    --
    -- Check if table is empty
    --
    if IAAM.CORE_GetNumItems(Table) == 0 then
        IAAM.CORE_PrintCommands()
        return
    end
    --
    -- Which slash command option?
    --
    if Table[1] == "add" then
        --
        -- Check argument count for add command
        --
        if IAAM.CORE_GetNumItems(Table) < 3 then
            print("IAmAMerchant: Wrong command!")
            IAAM.CORE_PrintCommands()
            return
        end
        --
        -- Check if item link is valid
        --
        local ItemID = Table.Link and GetItemInfoInstant(Table.Link)
        if ItemID == nil then
            print("IAmAMerchant: Couldn't find item!")
            IAAM.CORE_PrintCommands()
            return
        end
        --
        -- Check if last two arguemtns are numbers
        --
        if tonumber(Table[2]) == nil or tonumber(Table[3]) == nil then
            print("IAmAMerchant: Wrong parameters!")
            IAAM.CORE_PrintCommands()
            return
        end
        --
        -- Add item to list characters for sale list
        --
        IAAM.CORE_AddItem(IAAM_Character.ItemsForSale, Table.Link, Table[2], Table[3], C_Item.GetItemCount(Table.Link, true, true))
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
    elseif Table[1] == "clear" then
        IAAM_Character.ItemsForSale = {}
    else
        print("IAmAMerchant: Wrong command!")
        IAAM.CORE_PrintCommands()
    end
end