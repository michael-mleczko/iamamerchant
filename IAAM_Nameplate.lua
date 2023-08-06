
--============================================================
--============================================================
--
--             Global functions
--

--=============================================================
--
--             IAAM_NAMEPLATE_Initialize()
--
function IAAM_NAMEPLATE_Initialize(UnitID)
    IAAM_DEBUG_Print(false, "IAAM_NAMEPLATE_Initialize(", UnitID, ")")
    -- Check whether nameplate frame already exists. If not, create one.
    -- Frames cannot be destroyed and therefore have to be reused.
    local Nameplate = C_NamePlate.GetNamePlateForUnit(UnitID)
    if Nameplate.MerchantIcon == nil then
        local Nameplate = C_NamePlate.GetNamePlateForUnit(UnitID)
        local IconScale = 1.0
        local IconX     = 4
        local IconY     = -6

        -- special ELVUI merchant icon positioning
        if ElvUI ~= nil and ElvUI[1].NamePlates.Initialized == true then
            IconX = 4
            IconY = 0
        end

        -- create merchant icon frame and attach it to the nameplate
        local Frame = CreateFrame("Frame", "IAAMTestFrame", Nameplate)
        Frame:SetFrameStrata("BACKGROUND")
        Frame:SetFrameLevel(Nameplate:GetFrameLevel())
        Frame:SetWidth (24 * IconScale)
        Frame:SetHeight(24 * IconScale)
        Frame:EnableMouse(false)
        Frame:SetPoint("RIGHT", Nameplate, "LEFT", IconX, IconY)
        Frame.Icon = Frame:CreateTexture("IAAMTestFrameIcon", "ARTWORK")
        Frame.Icon:ClearAllPoints()
        Frame.Icon:SetAllPoints(Frame)
        Frame.Icon:SetTexture("Interface/Store/category-icon-bag.blp")
        Frame:Hide()
        Nameplate.MerchantIcon = Frame
    end
end

--=============================================================
--
--             IAAM_NAMEPLATE_AddIcon()
--
function IAAM_NAMEPLATE_AddIcon(UnitID)
    IAAM_DEBUG_Print(false, "IAAM_NAMEPLATE_AddIcon(", UnitID, ")")
    local Nameplate = C_NamePlate.GetNamePlateForUnit(UnitID)
    if Nameplate ~= nil then
        local MerchantIcon = Nameplate.MerchantIcon
        if IAAM_Character.IsEnabled and MerchantIcon:IsShown() == false then
            if IAAM_Character.IsSoundEnabled == true then
                PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND)
            end
            MerchantIcon:Show()
            IAAM_DEBUG_Print(false, "Added", IAAM_CORE_GetName(UnitID))
        end
    end
end

--=============================================================
--
--             IAAM_NAMEPLATE_RemoveIcon()
--
function IAAM_NAMEPLATE_RemoveIcon(UnitID)
    IAAM_DEBUG_Print(false, "IAAM_NAMEPLATE_RemoveIcon(", UnitID, ")")
    local Nameplate = C_NamePlate.GetNamePlateForUnit(UnitID)
    if Nameplate ~= nil then
        local MerchantIcon = Nameplate.MerchantIcon
        MerchantIcon:Hide()
    end
end

--=============================================================
--
--             IAAM_NAMEPLATE_Update()
--
function IAAM_NAMEPLATE_Update()
    IAAM_DEBUG_Print(false, "IAAM_NAMEPLATE_Update()")
    for k, v in pairs(C_NamePlate.GetNamePlates()) do
        local UnitID = v.namePlateUnitToken
        local Name = IAAM_CORE_GetName(UnitID)
        if IAAM_CORE_MerchantList[Name] ~= nil and IAAM_CORE_MerchantList[Name].ItemCount > 0 then
            IAAM_NAMEPLATE_AddIcon(UnitID)
        else
            IAAM_NAMEPLATE_RemoveIcon(UnitID)
        end
    end
end

--=============================================================
--
--             IAAM_NAMEPLATE_HideAll()
--
function IAAM_NAMEPLATE_HideAll()
    IAAM_DEBUG_Print(false, "IAAM_NAMEPLATE_HideAll()")
    for k, v in pairs(IAAM_NAMEPLATE_MarkFrames) do
        v:Hide()
    end
end
