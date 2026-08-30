-- KeyFlash by Soundz -- Options UI

-- ── Palette ──────────────────────────────────────────────────────────────────
local GOLD  = { 1.00, 0.80, 0.10, 1.0 }
local BG    = { 0.06, 0.06, 0.09, 0.97 }
local TITLE = { 0.09, 0.09, 0.13, 1.0 }
local BTN   = { 0.15, 0.15, 0.19, 1.0 }
local PRESS = { 0.07, 0.07, 0.10, 1.0 }
local BORD  = { 0.28, 0.28, 0.35, 1.0 }

-- ── Widget helpers ────────────────────────────────────────────────────────────

-- 4-sided 1px border painted as textures
local function ApplyBorder(f, c)
    c = c or BORD
    local r, g, b, a = c[1], c[2], c[3], c[4] or 1
    local top = f:CreateTexture(nil, "BORDER"); top:SetColorTexture(r,g,b,a)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
    local bot = f:CreateTexture(nil, "BORDER"); bot:SetColorTexture(r,g,b,a)
    bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT"); bot:SetHeight(1)
    local lft = f:CreateTexture(nil, "BORDER"); lft:SetColorTexture(r,g,b,a)
    lft:SetPoint("TOPLEFT",0,-1); lft:SetPoint("BOTTOMLEFT",0,1); lft:SetWidth(1)
    local rgt = f:CreateTexture(nil, "BORDER"); rgt:SetColorTexture(r,g,b,a)
    rgt:SetPoint("TOPRIGHT",0,-1); rgt:SetPoint("BOTTOMRIGHT",0,1); rgt:SetWidth(1)
end

-- Flat dark custom button (replaces UIPanelButtonTemplate)
local function MakeBtn(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or 90, h or 24)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(BTN[1],BTN[2],BTN[3],1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(GOLD[1],GOLD[2],GOLD[3],0.11)
    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetAllPoints(); lbl:SetJustifyH("CENTER"); lbl:SetText(text)
    b:SetScript("OnMouseDown", function() bg:SetColorTexture(PRESS[1],PRESS[2],PRESS[3],1) end)
    b:SetScript("OnMouseUp",   function() bg:SetColorTexture(BTN[1],BTN[2],BTN[3],1) end)
    b:SetScript("OnLeave",     function() bg:SetColorTexture(BTN[1],BTN[2],BTN[3],1) end)
    ApplyBorder(b)
    return b
end

-- Section header: gold text + thin gold underline
local function SectionLabel(parent, text, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    lbl:SetText("|cffffe066" .. text .. "|r")
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.30)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y - 15)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y - 15)
end

-- Full-width divider line
local function Div(parent, y)
    local d = parent:CreateTexture(nil, "ARTWORK")
    d:SetColorTexture(0.20, 0.20, 0.27, 0.75)
    d:SetHeight(1)
    d:SetPoint("TOPLEFT",  parent, "TOPLEFT",  20, y)
    d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
end

-- OptionsSliderTemplate slider
local sliderN = 0
local function MakeSlider(parent, y, minV, maxV, step, loTxt, hiTxt)
    sliderN = sliderN + 1
    local name = "KeyFlashSlider" .. sliderN
    local sl = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    sl:SetWidth(218)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    local lo = _G[name.."Low"]  ; if lo then lo:SetText(loTxt or "") end
    local hi = _G[name.."High"] ; if hi then hi:SetText(hiTxt or "") end
    local tx = _G[name.."Text"] ; if tx then tx:SetText("") end
    return sl
end

-- Custom flat dropdown (matches UI palette, no Blizzard template)
local function MakeCustomDropdown(parent, y, width, effects, onSelect)
    local rowH = 22

    -- Toggle button
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(BTN[1], BTN[2], BTN[3], 1)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.11)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT",  btn, "LEFT",   8,   0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -8,  0)
    lbl:SetJustifyH("LEFT")
    btn:SetScript("OnMouseDown", function() bg:SetColorTexture(PRESS[1], PRESS[2], PRESS[3], 1) end)
    btn:SetScript("OnMouseUp",   function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    btn:SetScript("OnLeave",     function() bg:SetColorTexture(BTN[1],   BTN[2],   BTN[3],   1) end)
    ApplyBorder(btn)

    -- Fullscreen click-catcher to dismiss on outside click
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:EnableMouse(true)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(199)
    catcher:Hide()

    -- Popup list (parented to UIParent so it escapes win clipping)
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(width, #effects * rowH)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(200)
    popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    popup:Hide()
    local popBg = popup:CreateTexture(nil, "BACKGROUND")
    popBg:SetAllPoints(); popBg:SetColorTexture(0.10, 0.10, 0.13, 0.98)
    ApplyBorder(popup, BORD)

    local rows = {}
    for i, eff in ipairs(effects) do
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(width, rowH)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, -(i - 1) * rowH)
        local rbg = row:CreateTexture(nil, "BACKGROUND")
        rbg:SetAllPoints(); rbg:SetColorTexture(0, 0, 0, 0)
        local rhl = row:CreateTexture(nil, "HIGHLIGHT")
        rhl:SetAllPoints(); rhl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.13)
        local rtxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rtxt:SetPoint("LEFT", row, "LEFT", 8, 0)
        rtxt:SetJustifyH("LEFT")
        rtxt:SetText(eff.label)
        row.effId = eff.id
        row.rbg   = rbg
        row:SetScript("OnClick", function()
            lbl:SetText(eff.label)
            popup:Hide()
            catcher:Hide()
            onSelect(eff.id)
        end)
        rows[i] = row
    end

    local function refreshHighlight()
        local cur = KeyFlashDB and KeyFlashDB.effect or "ff14"
        for _, row in ipairs(rows) do
            if row.effId == cur then
                row.rbg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.22)
            else
                row.rbg:SetColorTexture(0, 0, 0, 0)
            end
        end
    end

    catcher:SetScript("OnMouseDown", function() popup:Hide(); catcher:Hide() end)
    popup:SetScript("OnShow", function() refreshHighlight(); catcher:Show() end)
    popup:SetScript("OnHide", function() catcher:Hide() end)

    btn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide()
        else popup:Show() end
    end)

    function btn:SetSelection(text) lbl:SetText(text) end

    -- Exposed so the owning window can close the list with itself: popup and
    -- catcher are parented to UIParent (to escape the window's clipping), so
    -- win:Hide() -- including via Escape through UISpecialFrames -- would
    -- otherwise leave the list floating and the invisible fullscreen catcher
    -- swallowing the next click anywhere in the UI.
    btn.popup = popup

    return btn
end

-- ============================================================
-- What's New popup (shown once on first login after a new version)
-- ============================================================
local whatsNewWindow

local function BuildWhatsNewWindow()
    if whatsNewWindow then
        whatsNewWindow:Show()
        return
    end

    -- Copy is hand-maintained; the version number comes from the TOC.
    local changes = {
        {
            title = "Auto-attack indicator no longer hidden",
            desc  = "\"Hide default WoW button flash\" was suppressing the wrong texture -- the blinking auto-attack indicator rather than the keypress visual. It now hides only the pushed-down frame.",
        },
        {
            title = "Better action bar detection",
            desc  = "Dominos bars, mouse clicks on the default bars and very large UIs were all partly missed. Late-loading bar addons are now picked up by the delayed rescan as intended.",
        },
        {
            title = "Fast key presses no longer swallowed",
            desc  = "The duplicate-press filter was wide enough to drop genuine repeat presses above roughly 7 per second. Spamming an ability now flashes on every press.",
        },
        {
            title = "Macro flashes follow bar changes",
            desc  = "Moving a spell to another slot or swapping specialization no longer leaves macro-triggered flashes pointing at the old button.",
        },
    }

    local ROW_H, ROW_GAP = 50, 12
    local HEAD_H, FOOT_H = 68, 58   -- divider-to-first-row, and divider-to-bottom
    local BODY_H = #changes * ROW_H + (#changes - 1) * ROW_GAP
    local DIV2_Y = HEAD_H + BODY_H + 10

    local W, H = 420, DIV2_Y + FOOT_H
    local f = CreateFrame("Frame", "KeyFlashWhatsNewWindow", UIParent)
    f:SetSize(W, H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetAllPoints(); bg:SetColorTexture(BG[1], BG[2], BG[3], BG[4])

    -- Border
    ApplyBorder(f, BORD)

    -- Gold top stripe
    local accentTop = f:CreateTexture(nil, "BORDER", nil, 1)
    accentTop:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
    accentTop:SetHeight(3)
    accentTop:SetPoint("TOPLEFT"); accentTop:SetPoint("TOPRIGHT")

    -- Title bar background
    local titleBg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    titleBg:SetColorTexture(TITLE[1], TITLE[2], TITLE[3], 1)
    titleBg:SetHeight(36)
    titleBg:SetPoint("TOPLEFT"); titleBg:SetPoint("TOPRIGHT")

    -- Title bar separator
    local titleSep = f:CreateTexture(nil, "ARTWORK")
    titleSep:SetColorTexture(0.22, 0.22, 0.30, 1)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, -36)
    titleSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -36)

    -- Minimap icon in title
    local titleIcon = f:CreateTexture(nil, "OVERLAY")
    titleIcon:SetTexture([[Interface\AddOns\KeyFlash\minimap_icon.tga]])
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("LEFT", f, "TOPLEFT", 12, -20)

    -- Title text
    local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 7, 0)
    titleText:SetText("|cffffe066KeyFlash " .. (KeyFlash.VERSION or "") .. "  — What's New|r")

    -- Close X button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    closeX:SetPoint("CENTER")
    closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)
    closeX:SetText("X")
    closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(1, 0.95, 0.65, 1) end)
    closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Divider under header
    local div1 = f:CreateTexture(nil, "ARTWORK")
    div1:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.30)
    div1:SetHeight(1)
    div1:SetPoint("TOPLEFT",  f, "TOPLEFT",  20, -52)
    div1:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -52)

    -- Changelog entries
    local lastAnchor = div1
    local firstRow = true
    for _, entry in ipairs(changes) do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(W - 40, ROW_H)
        row:SetPoint("TOP", lastAnchor, "BOTTOM", 0, firstRow and -(HEAD_H - 52) or -ROW_GAP)
        firstRow = false

        local dot = row:CreateTexture(nil, "OVERLAY")
        dot:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        dot:SetSize(5, 5)
        dot:SetPoint("TOPLEFT", 0, -5)

        local titleLbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        titleLbl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        titleLbl:SetText(entry.title)
        titleLbl:SetTextColor(1, 1, 1, 1)
        titleLbl:SetPoint("LEFT", dot, "RIGHT", 8, 4)

        local descLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descLbl:SetFont("Fonts\\FRIZQT__.TTF", 11)
        descLbl:SetText(entry.desc)
        descLbl:SetTextColor(0.65, 0.65, 0.72, 1)
        descLbl:SetJustifyH("LEFT")
        descLbl:SetPoint("TOPLEFT", dot, "BOTTOMLEFT", 8, -3)
        descLbl:SetWidth(W - 60)
        descLbl:SetWordWrap(true)

        lastAnchor = row
    end

    -- Divider before button
    local div2 = f:CreateTexture(nil, "ARTWORK")
    div2:SetColorTexture(0.20, 0.20, 0.27, 0.75)
    div2:SetHeight(1)
    div2:SetPoint("TOPLEFT",  f, "TOPLEFT",  20, -DIV2_Y)
    div2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -DIV2_Y)

    -- "Got it" button
    local gotItBtn = MakeBtn(f, "Got it", 90, 26)
    gotItBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    gotItBtn:SetScript("OnClick", function() f:Hide() end)

    whatsNewWindow = f
    f:Show()
end

function KeyFlash.ShowWhatsNew()
    BuildWhatsNewWindow()
end

-- ============================================================
-- Standalone window
-- ============================================================
local win

local function BuildWindow()
    -- ── Base frame (plain, no template – we paint everything)
    win = CreateFrame("Frame", "KeyFlashMainFrame", UIParent)
    win:SetSize(440, 674)   -- provisional; height re-derived from the layout cursor below
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetMovable(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) self:StartMoving() end)
    win:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    win:Hide()
    table.insert(UISpecialFrames, "KeyFlashMainFrame")

    -- ── Dark background
    local winBg = win:CreateTexture(nil, "BACKGROUND", nil, -1)
    winBg:SetAllPoints(); winBg:SetColorTexture(BG[1],BG[2],BG[3],BG[4])

    -- ── Outer border (subtle dark edge)
    ApplyBorder(win, BORD)

    -- ── Gold accent stripe across very top (3px)
    local accentTop = win:CreateTexture(nil, "BORDER", nil, 1)
    accentTop:SetColorTexture(GOLD[1],GOLD[2],GOLD[3],1)
    accentTop:SetHeight(3)
    accentTop:SetPoint("TOPLEFT"); accentTop:SetPoint("TOPRIGHT")

    -- ── Title bar background
    local titleBg = win:CreateTexture(nil, "BACKGROUND", nil, 0)
    titleBg:SetColorTexture(TITLE[1],TITLE[2],TITLE[3],1)
    titleBg:SetHeight(36)
    titleBg:SetPoint("TOPLEFT"); titleBg:SetPoint("TOPRIGHT")

    -- ── Separator under title bar
    local titleSep = win:CreateTexture(nil, "ARTWORK")
    titleSep:SetColorTexture(0.22,0.22,0.30,1)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  win, "TOPLEFT",  0, -36)
    titleSep:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, -36)

    -- ── KeyFlash minimap icon in title bar
    local titleIcon = win:CreateTexture(nil, "OVERLAY")
    titleIcon:SetTexture([[Interface\AddOns\KeyFlash\minimap_icon.tga]])
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", win, "TOPLEFT", 12, -20)

    -- ── Title text
    local titleText = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleIcon, "RIGHT", 7, 0)
    titleText:SetText("|cffffe066KeyFlash|r  |cff555566-- by Soundz|r")

    -- ── Close button (standard WoW X)
    local closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", win, "TOPRIGHT", -5, -5)
    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    closeX:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)
    closeX:SetText("X")
    closeBtn:SetScript("OnEnter", function() closeX:SetTextColor(1, 0.95, 0.65, 1) end)
    closeBtn:SetScript("OnLeave", function() closeX:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1) end)
    closeBtn:SetScript("OnClick", function() win:Hide() end)

    -- ─────────────────────────────────────────────────────────────────────────
    -- Content (y relative to win TOPLEFT; content starts below title bar ~y=-40)
    -- ─────────────────────────────────────────────────────────────────────────
    local M = 20  -- left margin

    -- Vertical layout cursor.  Every control below asks Y(gap) for its offset
    -- instead of carrying an absolute one, so inserting or removing an option
    -- shifts only the controls after it rather than requiring ~25 constants and
    -- the window height to be renumbered by hand.
    local y = 0
    local function Y(gap)
        y = y - gap
        return y
    end

    -- ── Enable checkbox ───────────────────────────────────────────────────────
    local cbEnable = CreateFrame("CheckButton", nil, win)
    cbEnable:SetSize(22, 22)
    cbEnable:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cbEnable:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cbEnable:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cbEnable:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cbEnable:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    cbEnable:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(50))
    cbEnable:SetScript("OnClick", function(self)
        KeyFlashDB.enabled = self:GetChecked() and true or false
    end)
    local cbLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbLbl:SetPoint("LEFT", cbEnable, "RIGHT", 6, 0)
    cbLbl:SetText("Enable flash animations")

    Div(win, Y(32))

    -- ── EFFECT section ────────────────────────────────────────────────────────
    SectionLabel(win, "EFFECT", Y(12))

    local effLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    effLbl:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(28))
    effLbl:SetText("|cff888888Effect|r")

    local UpdateSwatch  -- forward ref
    local SyncSliders   -- forward ref

    local ddY = Y(14)
    local effectDD = MakeCustomDropdown(win, ddY, 163, KeyFlash.Effects, function(id)
        KeyFlashDB.effect = id
        UpdateSwatch()
        SyncSliders()
    end)

    -- ── Preview action button (44x44, styled like a WoW action slot)
    local dummy = CreateFrame("Button", "KeyFlashPreviewDummy", win)
    dummy:SetSize(44, 44)
    dummy:SetFrameLevel(12)
    dummy:SetPoint("TOPLEFT", win, "TOPLEFT", M + 196, ddY + 6)

    local dBg = dummy:CreateTexture(nil, "BACKGROUND")
    dBg:SetAllPoints(); dBg:SetColorTexture(0, 0, 0, 1)

    -- Paralysis (Monk CC) icon — amber/gold tone, very dark center, ideal preview contrast
    local dIcon = dummy:CreateTexture(nil, "ARTWORK")
    dIcon:SetTexture("Interface\\Icons\\ability_monk_paralysis")
    dIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    dIcon:SetAllPoints()

    -- Hover highlight
    local dHl = dummy:CreateTexture(nil, "HIGHLIGHT")
    dHl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    dHl:SetAllPoints(); dHl:SetBlendMode("ADD")

    -- Press darken
    dummy:SetScript("OnMouseDown", function() dIcon:SetVertexColor(0.55, 0.55, 0.55) end)
    dummy:SetScript("OnMouseUp",   function() dIcon:SetVertexColor(1, 1, 1) end)
    dummy:SetScript("OnLeave",     function() dIcon:SetVertexColor(1, 1, 1) end)

    -- Gold border (mimics selected/highlighted action button)
    ApplyBorder(dummy, GOLD)

    -- ── Preview button (next to dummy icon)
    local previewBtn = MakeBtn(win, "Press me", 90, 26)
    previewBtn:SetPoint("LEFT", dummy, "RIGHT", 8, 0)
    previewBtn:SetScript("OnClick", function()
        KeyFlash.PlayEffect(dummy)
    end)

    local previewHint = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewHint:SetPoint("TOP", previewBtn, "BOTTOM", 0, -4)
    previewHint:SetText("|cff666677or spam a button|r")

    -- ── Color row ─────────────────────────────────────────────────────────────
    local colorLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLbl:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(58))
    colorLbl:SetText("|cff888888Color|r")

    local swatchBtn = CreateFrame("Button", "KeyFlashColorSwatchWin", win)
    swatchBtn:SetSize(22, 22)
    swatchBtn:SetPoint("LEFT", colorLbl, "RIGHT", 8, 0)
    swatchBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local swBg = swatchBtn:CreateTexture(nil, "BACKGROUND")
    swBg:SetAllPoints(); swBg:SetColorTexture(0.08, 0.08, 0.08, 1)
    local swTex = swatchBtn:CreateTexture(nil, "ARTWORK")
    swTex:SetPoint("TOPLEFT",     swatchBtn, "TOPLEFT",      2, -2)
    swTex:SetPoint("BOTTOMRIGHT", swatchBtn, "BOTTOMRIGHT", -2,  2)
    swTex:SetColorTexture(1, 1, 1, 1)
    ApplyBorder(swatchBtn, BORD)

    local resetColorBtn = MakeBtn(win, "Reset Color", 86, 24)
    resetColorBtn:SetPoint("LEFT", swatchBtn, "RIGHT", 8, 0)

    UpdateSwatch = function()
        local id     = KeyFlashDB.effect or "ff14"
        local stored = KeyFlashDB.effectColors and KeyFlashDB.effectColors[id]
        local r, g, b
        if stored then
            r, g, b = stored[1], stored[2], stored[3]
        else
            local c = (KeyFlash.EffectsById[id] or KeyFlash.Effects[1]).color or { 1,1,1 }
            r, g, b = c[1], c[2], c[3]
        end
        swTex:SetColorTexture(r, g, b, 1)
    end

    swatchBtn:SetScript("OnClick", function()
        local id     = KeyFlashDB.effect or "ff14"
        local stored = KeyFlashDB.effectColors and KeyFlashDB.effectColors[id]
        local eff    = KeyFlash.EffectsById[id] or KeyFlash.Effects[1]
        local r, g, b
        if stored then
            r, g, b = stored[1], stored[2], stored[3]
        else
            local c = eff.color or { 1,1,1 }
            r, g, b = c[1], c[2], c[3]
        end
        local hadCustom = (stored ~= nil)
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                KeyFlashDB.effectColors     = KeyFlashDB.effectColors or {}
                KeyFlashDB.effectColors[id] = { nr, ng, nb }
                swTex:SetColorTexture(nr, ng, nb, 1)
            end,
            cancelFunc = function(prev)
                KeyFlashDB.effectColors     = KeyFlashDB.effectColors or {}
                KeyFlashDB.effectColors[id] = hadCustom
                    and { prev.r, prev.g, prev.b } or nil
                UpdateSwatch()
            end,
        })
    end)

    resetColorBtn:SetScript("OnClick", function()
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectColors     = KeyFlashDB.effectColors or {}
        KeyFlashDB.effectColors[id] = nil
        UpdateSwatch()
    end)

    Div(win, Y(34))

    -- ── ANIMATION section ─────────────────────────────────────────────────────
    SectionLabel(win, "ANIMATION", Y(13))

    -- Speed
    local speedLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    speedLbl:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(25))
    speedLbl:SetText("|cff888888Speed|r")
    local speedVal = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    speedVal:SetPoint("LEFT", speedLbl, "RIGHT", 8, 0)

    local speedSlider = MakeSlider(win, Y(16), 0.3, 3.0, 0.1,
        "|cff555566fast|r", "|cff555566slow|r")
    speedSlider:SetScript("OnValueChanged", function(self, val)
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].animSpeed = val
        speedVal:SetText(string.format("|cffffe066%.1fx|r", val))
    end)
    local speedDef = MakeBtn(win, "Default", 68, 22)
    speedDef:SetPoint("LEFT", speedSlider, "RIGHT", 8, 0)
    speedDef:SetScript("OnClick", function()
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].animSpeed = 1.0
        speedSlider:SetValue(1.0)
    end)

    -- Size
    local sizeLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLbl:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(36))
    sizeLbl:SetText("|cff888888Size|r")
    local sizeVal = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sizeVal:SetPoint("LEFT", sizeLbl, "RIGHT", 8, 0)

    local sizeSlider = MakeSlider(win, Y(16), 0.5, 3.0, 0.1,
        "|cff555566small|r", "|cff555566large|r")
    sizeSlider:SetScript("OnValueChanged", function(self, val)
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].overlayScale = val
        sizeVal:SetText(string.format("|cffffe066%.1fx|r", val))
    end)
    local sizeDef = MakeBtn(win, "Default", 68, 22)
    sizeDef:SetPoint("LEFT", sizeSlider, "RIGHT", 8, 0)
    sizeDef:SetScript("OnClick", function()
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].overlayScale = 1.0
        sizeSlider:SetValue(1.0)
    end)

    -- Opacity
    local opLbl = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opLbl:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(36))
    opLbl:SetText("|cff888888Opacity|r")
    local opVal = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    opVal:SetPoint("LEFT", opLbl, "RIGHT", 8, 0)

    local opSlider = MakeSlider(win, Y(16), 0.1, 1.0, 0.05,
        "|cff555566dim|r", "|cff555566full|r")
    opSlider:SetScript("OnValueChanged", function(self, val)
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].opacity = val
        opVal:SetText(string.format("|cffffe066%d%%|r", math.floor(val * 100 + 0.5)))
    end)
    local opDef = MakeBtn(win, "Default", 68, 22)
    opDef:SetPoint("LEFT", opSlider, "RIGHT", 8, 0)
    opDef:SetScript("OnClick", function()
        local id = KeyFlashDB.effect or "ff14"
        KeyFlashDB.effectSettings = KeyFlashDB.effectSettings or {}
        KeyFlashDB.effectSettings[id] = KeyFlashDB.effectSettings[id] or {}
        KeyFlashDB.effectSettings[id].opacity = 1.0
        opSlider:SetValue(1.0)
    end)

    Div(win, Y(34))

    -- ── COMPATIBILITY section ─────────────────────────────────────────────────
    SectionLabel(win, "COMPATIBILITY", Y(12))

    local cbHook = CreateFrame("CheckButton", nil, win)
    cbHook:SetSize(22, 22)
    cbHook:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cbHook:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cbHook:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cbHook:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cbHook:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    cbHook:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(24))
    cbHook:SetScript("OnClick", function(self)
        KeyFlashDB.forceUseActionHook = self:GetChecked() and true or false
    end)
    local cbHookLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbHookLbl:SetPoint("LEFT", cbHook, "RIGHT", 6, 0)
    cbHookLbl:SetText("Force UseAction hook")
    local cbHookSub = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbHookSub:SetPoint("TOPLEFT", cbHook, "BOTTOMLEFT", 0, -2)
    cbHookSub:SetText("|cff555566Requires reload. Enable if buttons on custom bars don't flash.|r")

    local cbFlash = CreateFrame("CheckButton", nil, win)
    cbFlash:SetSize(22, 22)
    cbFlash:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cbFlash:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cbFlash:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cbFlash:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cbFlash:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    cbFlash:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(42))
    cbFlash:SetScript("OnClick", function(self)
        KeyFlashDB.suppressWowFlash = self:GetChecked() and true or false
    end)
    local cbFlashLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbFlashLbl:SetPoint("LEFT", cbFlash, "RIGHT", 6, 0)
    cbFlashLbl:SetText("Hide default WoW button flash")
    local cbFlashSub = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbFlashSub:SetPoint("TOPLEFT", cbFlash, "BOTTOMLEFT", 0, -2)
    cbFlashSub:SetText("|cff555566Hides the pushed-down frame shown while a button is held. Proc glows and the auto-attack indicator are unaffected.|r")

    Div(win, Y(42))

    -- ── MINIMAP section ───────────────────────────────────────────────────────
    SectionLabel(win, "MINIMAP", Y(12))

    local cbMinimap = CreateFrame("CheckButton", nil, win)
    cbMinimap:SetSize(22, 22)
    cbMinimap:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cbMinimap:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cbMinimap:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cbMinimap:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cbMinimap:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    cbMinimap:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(24))
    cbMinimap:SetScript("OnClick", function(self)
        local show = self:GetChecked() and true or false
        KeyFlashDB.minimapHide = not show
        local mb = KeyFlash.minimapButton
        if mb then
            if show then mb:Show() else mb:Hide() end
        end
    end)
    local cbMinimapLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cbMinimapLbl:SetPoint("LEFT", cbMinimap, "RIGHT", 6, 0)
    cbMinimapLbl:SetText("Show minimap button")

    Div(win, Y(32))

    -- ── Restore All Defaults ──────────────────────────────────────────────────
    local restoreBtn = MakeBtn(win, "Restore All Defaults", 160, 26)
    restoreBtn:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(16))
    restoreBtn:SetScript("OnClick", function()
        StaticPopup_Show("KEYFLASH_RESET_CONFIRM")
    end)

    StaticPopupDialogs["KEYFLASH_RESET_CONFIRM"] = {
        text         = "Reset all KeyFlash settings to defaults?\nThis will reload the UI.",
        button1      = "Reset",
        button2      = "Cancel",
        OnAccept     = function() KeyFlashDB = nil; ReloadUI() end,
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
    }

    Div(win, Y(32))

    -- ── Credits ───────────────────────────────────────────────────────────────
    local credits = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    credits:SetPoint("TOPLEFT", win, "TOPLEFT", M, Y(6))
    credits:SetText("|cff444455Feedback & Bugreports:|r  |cff666677twitch.tv/soundzgood|r  |cff444455/|r  |cff666677Discord: soundz1|r")

    -- Window height follows the cursor, so adding a control no longer means
    -- remembering to bump a hardcoded height as well.
    win:SetHeight(-y + 12)

    -- ── SyncSliders: load current effect's per-effect settings into UI ────────
    SyncSliders = function()
        local id = KeyFlashDB.effect or "ff14"
        local es = (KeyFlashDB.effectSettings or {})[id] or {}

        local spd = es.animSpeed or 1.0
        speedSlider:SetValue(spd)
        speedVal:SetText(string.format("|cffffe066%.1fx|r", spd))

        local sz = es.overlayScale or 1.0
        sizeSlider:SetValue(sz)
        sizeVal:SetText(string.format("|cffffe066%.1fx|r", sz))

        local op = es.opacity or 1.0
        opSlider:SetValue(op)
        opVal:SetText(string.format("|cffffe066%d%%|r", math.floor(op * 100 + 0.5)))
    end

    -- ── Sync all controls when window opens ───────────────────────────────────
    win:SetScript("OnShow", function()
        cbEnable:SetChecked(KeyFlashDB.enabled)
        cbHook:SetChecked(KeyFlashDB.forceUseActionHook and true or false)
        cbFlash:SetChecked(KeyFlashDB.suppressWowFlash and true or false)
        cbMinimap:SetChecked(not (KeyFlashDB.minimapHide and true or false))

        local eff = KeyFlash.EffectsById[KeyFlashDB.effect or "ff14"] or KeyFlash.Effects[1]
        effectDD:SetSelection(eff.label)

        UpdateSwatch()
        SyncSliders()
    end)

    win:SetScript("OnHide", function()
        effectDD.popup:Hide()
    end)
end

-- ============================================================
-- Blizzard settings panel (thin shell -- opens the window)
-- ============================================================
local panel

local function BuildPanel()
    panel      = CreateFrame("Frame")
    panel.name = "KeyFlash"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffffe066KeyFlash|r  |cffaaaaaa-- by Soundz|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("|cffaaaaaaButton-press visual effects for your action bars.|r")

    local divTex = panel:CreateTexture(nil, "ARTWORK")
    divTex:SetColorTexture(0.25, 0.25, 0.30, 0.6)
    divTex:SetHeight(1)
    divTex:SetPoint("TOPLEFT",  panel, "TOPLEFT",  16, -56)
    divTex:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -56)

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(190, 26)
    openBtn:SetText("Open KeyFlash Settings")
    openBtn:SetPoint("TOPLEFT", 16, -80)
    openBtn:SetScript("OnClick", function() KeyFlash.ToggleWindow() end)

    local credits = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    credits:SetPoint("TOPLEFT", 16, -122)
    credits:SetText("Feedback & Bugreports:  twitch.tv/soundzgood  |  Discord: soundz1")

    return panel
end

-- ============================================================
-- Public API
-- ============================================================
function KeyFlash.ToggleWindow()
    if not win then return end
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end

function KeyFlash.OpenSettings()
    KeyFlash.ToggleWindow()
end

-- ============================================================
-- Registration
-- ============================================================
local _cat

local optFrame = CreateFrame("Frame")
optFrame:RegisterEvent("PLAYER_LOGIN")
optFrame:SetScript("OnEvent", function(self)
    BuildWindow()
    BuildPanel()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        _cat = Settings.RegisterCanvasLayoutCategory(panel, "KeyFlash")
        Settings.RegisterAddOnCategory(_cat)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        _cat = panel
    end
    self:UnregisterEvent("PLAYER_LOGIN")
end)