local _, IAAM = ...

--============================================================
--============================================================
--
--             Variables
--

IAAM.DEBUG         = {}
IAAM.DEBUG.Enabled = false

if IAAM.DEBUG.Enabled == true then
    SLASH_RELOADUI1       = "/rl"
    SlashCmdList.RELOADUI = ReloadUI

    SLASH_FRAMESTK1       = "/fs"
    SlashCmdList.FRAMESTK = function()
        LoadAddOn("Blizzard_DebugTools")
        FrameStackTooltip_Toggle()
    end

    for i = 1, NUM_CHAT_WINDOWS do
        _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
    end
end

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM.DEBUG.Print()
--
--  Print a message if debug mode is on. It is possible to
--  force output, even if debug mode is disabled.
--
function IAAM.DEBUG.Print(Force, ...)
    if IAAM.DEBUG.Enabled == true or Force == true then
        print("IAAM >> ", ...)
    end
end