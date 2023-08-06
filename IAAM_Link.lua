
--============================================================
--============================================================
--
--             Local variables
---

local IAAM_ItemLinkPattern  = "(|c.-|H.-:.-|h|r)"

--============================================================
--============================================================
--
--             Global functions
--

--============================================================
--
--             IAAM_LINK_Get()
--
--  Extracts an item link from a string. The item will be 
--  reomved entirely from the String.
--
function IAAM_LINK_Get(String)
    --
    -- Get start and end index of the item within the given string.
    --
    local StartIndex, EndIndex = string.find(String, IAAM_ItemLinkPattern)
    if StartIndex ~= nil then
        --
        -- If an item link was found, return: ItemLink, String
        --
        return string.sub(String, StartIndex, EndIndex), string.gsub(String, IAAM_ItemLinkPattern, "")
    end
    --
    -- If no item link was found, return: nil, String
    --
    return nil, String
end
