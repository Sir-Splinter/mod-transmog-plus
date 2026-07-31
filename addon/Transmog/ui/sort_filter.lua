local Transmog = _G.Transmog

-- Client-side sorting, subtype filtering, and full-name searching for
-- collected appearances. No server or protocol changes are required.

Transmog.appearanceSortMode = "LEVEL_DESC"
Transmog.appearanceSubtypeFilter = nil
Transmog.appearanceSearchText = ""
Transmog.appearanceFilterOptions = {}

local SORT_LABELS = {
    LEVEL_DESC = "Item level: high to low",
    LEVEL_ASC = "Item level: low to high",
    NAME_ASC = "Name: A to Z",
    NAME_DESC = "Name: Z to A",
}

local SORT_ORDER = { "LEVEL_DESC", "LEVEL_ASC", "NAME_ASC", "NAME_DESC" }

local function safeLower(value)
    -- GetItemInfo() supplies the complete localized item name. Keep the
    -- complete string intact; do not split it into prefixes or suffixes.
    return string.lower(value or "")
end

local function compareFullNames(a, b, descending)
    local nameA = safeLower(a.name)
    local nameB = safeLower(b.name)

    if nameA ~= nameB then
        if descending then
            return nameA > nameB
        end
        return nameA < nameB
    end

    -- Stable deterministic order for duplicate localized names.
    return (a.id or 0) < (b.id or 0)
end

function Transmog:GetAppearanceSortLabel()
    return SORT_LABELS[self.appearanceSortMode] or SORT_LABELS.LEVEL_DESC
end

function Transmog:ResetAppearanceSubtypeFilter()
    self.appearanceSubtypeFilter = nil
end

function Transmog:BuildAppearanceFilterOptions(items)
    local seen = {}
    local options = {}

    for _, item in ipairs(items or {}) do
        if item.id ~= self.HIDDEN_ITEM_ID and item.t2 and item.t2 ~= "" and not seen[item.t2] then
            seen[item.t2] = true
            table.insert(options, item.t2)
        end
    end

    table.sort(options, function(a, b)
        return safeLower(a) < safeLower(b)
    end)

    self.appearanceFilterOptions = options

    if self.appearanceSubtypeFilter and not seen[self.appearanceSubtypeFilter] then
        self.appearanceSubtypeFilter = nil
    end
end

function Transmog:GetFilteredSortedAppearances(slot, itemClass)
    local source = self.availableTransmogItems[slot] and self.availableTransmogItems[slot][itemClass] or {}
    local hiddenItem = nil
    local result = {}
    local searchText = safeLower(self.appearanceSearchText)

    for _, item in ipairs(source) do
        if item.id == self.HIDDEN_ITEM_ID then
            -- Keep the hidden/reset entry available regardless of search text.
            hiddenItem = item
        else
            local subtypeMatches = not self.appearanceSubtypeFilter or item.t2 == self.appearanceSubtypeFilter
            local nameMatches = searchText == "" or string.find(safeLower(item.name), searchText, 1, true) ~= nil

            if subtypeMatches and nameMatches then
                table.insert(result, item)
            end
        end
    end

    table.sort(result, function(a, b)
        local mode = self.appearanceSortMode
        if mode == "LEVEL_ASC" then
            if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
            return compareFullNames(a, b, false)
        elseif mode == "NAME_ASC" then
            return compareFullNames(a, b, false)
        elseif mode == "NAME_DESC" then
            return compareFullNames(a, b, true)
        else
            if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
            return compareFullNames(a, b, false)
        end
    end)

    if hiddenItem then
        table.insert(result, 1, hiddenItem)
    end

    return result
end

local function refreshList()
    if not Transmog.currentTransmogSlot or not Transmog.currentTransmogItemClass then return end
    Transmog.currentPage = 1
    Transmog:renderAvailableTransmogs(Transmog.currentTransmogSlot, Transmog.currentTransmogItemClass)
end

local function initializeSortDropdown()
    local info
    for _, mode in ipairs(SORT_ORDER) do
        info = UIDropDownMenu_CreateInfo()
        info.text = SORT_LABELS[mode]
        info.value = mode
        info.checked = Transmog.appearanceSortMode == mode
        info.func = function()
            Transmog.appearanceSortMode = this.value
            UIDropDownMenu_SetSelectedValue(TransmogSortDropDown, this.value)
            UIDropDownMenu_SetText(TransmogSortDropDown, "Sort: " .. SORT_LABELS[this.value])
            CloseDropDownMenus()
            refreshList()
        end
        UIDropDownMenu_AddButton(info)
    end
end

local function initializeFilterDropdown()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All"
    info.value = "__ALL__"
    info.checked = Transmog.appearanceSubtypeFilter == nil
    info.func = function()
        Transmog.appearanceSubtypeFilter = nil
        UIDropDownMenu_SetSelectedValue(TransmogFilterDropDown, "__ALL__")
        UIDropDownMenu_SetText(TransmogFilterDropDown, "Type: All")
        CloseDropDownMenus()
        refreshList()
    end
    UIDropDownMenu_AddButton(info)

    for _, subtype in ipairs(Transmog.appearanceFilterOptions or {}) do
        info = UIDropDownMenu_CreateInfo()
        info.text = subtype
        info.value = subtype
        info.checked = Transmog.appearanceSubtypeFilter == subtype
        info.func = function()
            Transmog.appearanceSubtypeFilter = this.value
            UIDropDownMenu_SetSelectedValue(TransmogFilterDropDown, this.value)
            UIDropDownMenu_SetText(TransmogFilterDropDown, "Type: " .. this.value)
            CloseDropDownMenus()
            refreshList()
        end
        UIDropDownMenu_AddButton(info)
    end
end

function Transmog:CreateAppearanceSortFilterUI()
    if TransmogSortFilterBar then return end

    -- Build a taller right-side header panel. The existing Collected status bar
    -- remains on the first row; controls sit on a second row with consistent
    -- margins and no overlap with the decorative appearance area below.
    local bar = CreateFrame("Frame", "TransmogSortFilterBar", TransmogFrame)
    bar:SetPoint("TOPLEFT", TransmogFrame, "TOPLEFT", 247, -43)
    bar:SetWidth(482)
    bar:SetHeight(88)

    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    background:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    background:SetTexture(0.025, 0.02, 0.015, 0.82)

    local topShade = bar:CreateTexture(nil, "BORDER")
    topShade:SetPoint("TOPLEFT", bar, "TOPLEFT", 8, -2)
    topShade:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -8, -2)
    topShade:SetHeight(1)
    topShade:SetTexture(0.55, 0.43, 0.20, 0.45)

    local separator = bar:CreateTexture(nil, "BORDER")
    separator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 8, 1)
    separator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -8, 1)
    separator:SetHeight(1)
    separator:SetTexture(0.55, 0.43, 0.20, 0.75)

    -- Second-row controls: 10 px outer margins and 8 px gaps.
    local sort = CreateFrame("Frame", "TransmogSortDropDown", bar, "UIDropDownMenuTemplate")
    sort:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -6, 8)
    UIDropDownMenu_SetWidth(sort, 166)
    UIDropDownMenu_Initialize(sort, initializeSortDropdown)
    UIDropDownMenu_SetSelectedValue(sort, self.appearanceSortMode)
    UIDropDownMenu_SetText(sort, "Sort: " .. self:GetAppearanceSortLabel())

    local filter = CreateFrame("Frame", "TransmogFilterDropDown", bar, "UIDropDownMenuTemplate")
    filter:SetPoint("LEFT", sort, "RIGHT", -30, 0)
    UIDropDownMenu_SetWidth(filter, 104)
    UIDropDownMenu_Initialize(filter, initializeFilterDropdown)
    UIDropDownMenu_SetSelectedValue(filter, "__ALL__")
    UIDropDownMenu_SetText(filter, "Type: All")

    local search = CreateFrame("EditBox", "TransmogSearchBox", bar, "InputBoxTemplate")
    search:SetPoint("LEFT", filter, "RIGHT", -4, 3)
    search:SetPoint("RIGHT", bar, "RIGHT", -12, 3)
    search:SetHeight(20)
    search:SetAutoFocus(false)
    search:SetMaxLetters(50)
    search:SetTextInsets(6, 6, 0, 0)

    local searchHint = search:CreateFontString("TransmogSearchHint", "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", search, "LEFT", 7, 0)
    searchHint:SetText("Search...")

    local function updateSearchHint()
        if search:HasFocus() or (search:GetText() or "") ~= "" then
            searchHint:Hide()
        else
            searchHint:Show()
        end
    end

    search:SetScript("OnTextChanged", function()
        Transmog.appearanceSearchText = this:GetText() or ""
        updateSearchHint()
        refreshList()
    end)
    search:SetScript("OnEditFocusGained", updateSearchHint)
    search:SetScript("OnEditFocusLost", updateSearchHint)
    search:SetScript("OnEnterPressed", function()
        this:ClearFocus()
    end)
    search:SetScript("OnEscapePressed", function()
        if this:GetText() ~= "" then
            this:SetText("")
        else
            this:ClearFocus()
        end
    end)

    updateSearchHint()
    bar:Hide()
end

function Transmog:UpdateAppearanceSortFilterUI(slot, itemClass)
    self:CreateAppearanceSortFilterUI()

    if not slot or not itemClass then
        TransmogSortFilterBar:Hide()
        return
    end

    local items = self.availableTransmogItems[slot] and self.availableTransmogItems[slot][itemClass] or {}
    self:BuildAppearanceFilterOptions(items)

    UIDropDownMenu_SetSelectedValue(TransmogSortDropDown, self.appearanceSortMode)
    UIDropDownMenu_SetText(TransmogSortDropDown, "Sort: " .. self:GetAppearanceSortLabel())

    local filterText = self.appearanceSubtypeFilter or "All"
    UIDropDownMenu_SetSelectedValue(TransmogFilterDropDown, self.appearanceSubtypeFilter or "__ALL__")
    UIDropDownMenu_SetText(TransmogFilterDropDown, "Type: " .. filterText)

    if TransmogSearchBox:GetText() ~= (self.appearanceSearchText or "") then
        TransmogSearchBox:SetText(self.appearanceSearchText or "")
    end

    TransmogSortFilterBar:Show()
end
