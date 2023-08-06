
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
    IAAM_DEBUG_Print(false, "Core: Slash command")
    --
    -- Store space seperated arguments in a table
    --
    local Table = IAAM_CORE_GetData(Message)
    --
    -- Check if table is empty
    --
    if IAAM_CORE_GetNumItems(Table) == 0 then
        print("IAmAMerchant: Wrong command!")
        IAAM_CORE_PrintCommands()
        return
    end
    --
    -- Which slash command option?
    --
    if Table[1] == "add" then
        --
        -- Check argument count for add command
        --
        if IAAM_CORE_GetNumItems(Table) < 3 then
            print("IAmAMerchant: Wrong command!")
            IAAM_CORE_PrintCommands()
            return
        end
        --
        -- Check if item link is valid
        --
        local ItemID = GetItemInfoInstant(Table.Link)
        if ItemID == nil then
            print("IAmAMerchant: Couldn't find item!")
            IAAM_CORE_PrintCommands()
            return
        end
        --
        -- Check if last two arguemtns are numbers
        --
        if tonumber(Table[2]) == nil or tonumber(Table[3]) == nil then
            print("IAmAMerchant: Wrong parameters!")
            IAAM_CORE_PrintCommands()
            return
        end
        --
        -- Add item to list characters for sale list
        --
        IAAM_CORE_AddItem(IAAM_Character.ItemsForSale, Table.Link, Table[2], Table[3], GetItemCount(Table.Link, true, true))
        --
        -- If own merchant window is open, add it to targets for sale list and update the window
        -- so that the added item will be displayed instantly
        --
        if IAAM_Frame:IsShown() then
            IAAM_FRAME_Update()
        end
        print("IAmAMerchant: Item "..Table[2].." added.")
    elseif Table[1] == "on" then
        IAAM_Character.IsEnabled = true
    elseif Table[1] == "off" then
        IAAM_Character.IsEnabled = false
    elseif Table[1] == "clear" then
        IAAM_Character.ItemsForSale = {}
    elseif Table[1] == "help" then
        print(" ")
        print("IAmAMerchant (v"..IAAM_VERSION..")")
        print(" ")
        print("Slash command list:")
        IAAM_CORE_PrintCommands()
        print(" ")
    elseif Table[1] == "sound" then
        if Table[2] == "on" then
            IAAM_Character.IsSoundEnabled = true
        elseif Table[2] == "off" then
            IAAM_Character.IsSoundEnabled = false
        end
    else
        print("IAmAMerchant: Wrong command!")
        IAAM_CORE_PrintCommands()
    end
end