local _, IAAM = ...

--============================================================
--============================================================
--
--             Events
--

IAAM.EVENT          = {}
IAAM.EVENT.Handlers = {}

--============================================================
--
--             IAAM.EVENT.OnEvent()
--
function IAAM.EVENT.OnEvent(self, Event, ...)
    IAAM.DEBUG.Print(false, "[EVENT] "..Event)
    IAAM.EVENT.Handlers[Event](...)
end


--============================================================
--
--             PORTRAITS_UPDATED()
--
function IAAM.EVENT.Handlers.PORTRAITS_UPDATED(...)
    IAAM.DEBUG.Print(false, "[EVENT] PORTRAITS_UPDATED")
    local UpdateUnit = ...
    if UpdateUnit and UpdateUnit == IAAM_VWPortrait.unit then
        ButtonFrameTemplate_ShowPortrait(IAAM_VW)
        SetPortraitTexture(IAAM_VWPortrait, UpdateUnit)
    end
end

--============================================================
--
--             UNIT_PORTRAIT_UPDATE()
--
function IAAM.EVENT.Handlers.UNIT_PORTRAIT_UPDATE(...)
    IAAM.DEBUG.Print(false, "[EVENT] UNIT_PORTRAIT_UPDATE")
    local UpdateUnit = ...
    if UpdateUnit and UpdateUnit == IAAM_VWPortrait.unit then
        ButtonFrameTemplate_ShowPortrait(IAAM_VW)
        SetPortraitTexture(IAAM_VWPortrait, UpdateUnit)
    end
end

--=============================================================
--
--             VARIABLES_LOADED()
--
--  Secondary entry point of this addon
--
function IAAM.EVENT.Handlers.VARIABLES_LOADED(event, ...)
    IAAM.DEBUG.Print(false, "Core: Variables loaded")
    --
    -- Initialize variables if not yet done.
    --
    if type(IAAM.Merchant) ~= "table" then
        IAAM.Merchant = {}
    end
    if type(IAAM.Merchant.ItemsForSale) ~= "table" then
        IAAM.Merchant.ItemsForSale = {}
    end
    if type(IAAM_Character) ~= "table" then
        IAAM_Character = {}
    end
    if type(IAAM_Character.ItemsForSale) ~= "table" then
        IAAM_Character.ItemsForSale = {}
    end
    if IAAM_Character.ShowAll == nil then
        IAAM_Character.ShowAll = false
    end
    if type(IAAM_Account) ~= "table" then
        IAAM_Account = {}
    end
    IAAM.NET.Init()
    --
    -- Make frames close on ESC
    --
    tinsert(UISpecialFrames, "IAAM_VW")
    tinsert(UISpecialFrames, "IAAM_MT")
    print("IAmAMerchant (v"..IAAM.VERSION..")")
end

--
-- Initialize event handler
--
IAAM.EVENT.Frame = CreateFrame("Frame")
IAAM.EVENT.Frame:SetScript("OnEvent", IAAM.EVENT.OnEvent)
for Key in pairs(IAAM.EVENT.Handlers) do
    --_G[self:GetName()][Key] = IAAM.EVENT.Handlers[Key]
    IAAM.EVENT.Frame:RegisterEvent(Key)
    IAAM.DEBUG.Print(false, "Core: Registered event: "..Key)
end
