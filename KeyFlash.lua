-- KeyFlash by Soundz
-- Visual button-press flash effects for your action bars.
-- SavedVariables: KeyFlashDB

KeyFlash = {}

-- ── AddOn-loaded compat shim ─────────────────────────────────────────────────
-- Retail removed the IsAddOnLoaded global (it now lives in C_AddOns).  Declared
-- here rather than next to the event frame because ScanButtons below would
-- otherwise bind to the global name and silently skip its Dominos pass.
local IsAddOnLoaded = IsAddOnLoaded or (C_AddOns and C_AddOns.IsAddOnLoaded)

-- Single source of truth for the version. It used to be hardcoded in three
-- places (here, the What's New window and the TOC), which had already drifted:
-- the TOC said 1.6 while both Lua copies still said 1.5, so nobody upgrading
-- from 1.5 was told anything and anyone coming from 1.4 saw a "1.5" dialog on
-- a 1.6 install.
local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
KeyFlash.VERSION = (GetAddOnMetadata and GetAddOnMetadata("KeyFlash", "Version")) or "?"

-- ── DB defaults ───────────────────────────────────────────────────────────────
local DB_DEFAULTS = {
    enabled          = true,
    effect           = "ff14",
    effectColors     = {},   -- [effectId] = {r, g, b}
    effectSettings   = {},   -- [effectId] = {animSpeed, overlayScale, opacity}
    minimapAngle     = 220,
    minimapHide      = false,
    suppressWowFlash = false,
    lastSeenVersion  = "",
    lastMuiNotice    = "",   -- version the mUI compatibility notice was last shown for
}

local function SetupDB()
    if not KeyFlashDB then KeyFlashDB = {} end
    for k, v in pairs(DB_DEFAULTS) do
        if type(v) == "table" then
            if KeyFlashDB[k] == nil then KeyFlashDB[k] = {} end
        elseif KeyFlashDB[k] == nil then
            KeyFlashDB[k] = v
        end
    end
end

-- ── Scale API compatibility shim ──────────────────────────────────────────────
-- Older WoW used SetFromScale/SetToScale; newer uses SetScaleFrom/SetScaleTo.
local function CompatScale(anim)
    if not anim.SetScaleFrom then
        anim.SetScaleFrom = anim.SetFromScale
        anim.SetScaleTo   = anim.SetToScale
    end
    return anim
end

-- ── Effects table ─────────────────────────────────────────────────────────────
-- Fields: id, label, color, tex, tcx (SetTexCoord left,right,top,bottom or nil)
--         sF/sT/sDur : scale from/to/duration
--         aF/aDur/aDelay : alpha from / duration / start-delay (all base seconds)
--         rot (optional): rotation in degrees played alongside scale+alpha
local FF14  = [[Interface\AddOns\KeyFlash\ff14_pressed.tga]]
local KF    = [[Interface\AddOns\KeyFlash\kf_ring.tga]]
local RING  = [[Interface\AddOns\KeyFlash\ring_flash.tga]]
local ALERT = [[Interface\SpellActivationOverlay\IconAlert]]
local ANTS  = [[Interface\SpellActivationOverlay\IconAlertAnts]]
local STAR  = [[Interface\Cooldown\starburst]]
local STAR4 = [[Interface\Cooldown\star4]]
local RIPPLE = [[Interface\AddOns\KeyFlash\kf_ripple.tga]]

KeyFlash.Effects = {
    -- noPreShrink=true: overlay = full button size; animation can bloom past icon edges.
    -- noPreShrink omitted: overlay pre-shrunk so peak scale exactly fills the button (no overflow).
    -- aDelay on expanding effects ≈ 65-70% of sDur so full alpha is held until near peak.

    { id="ff14",            label="Key Ring",
      color={1.00, 0.80, 0.00}, tex=FF14, noPreShrink=true,
      sF=0.10, sT=1.30, sDur=0.30,
      aF=0.50, aDur=0.20, aDelay=0.10 },
    { id="burst",           label="Flash Square",
      color={1.00, 0.85, 0.30}, tex=ALERT, tcx={0, 66/128, 136/256, 202/256},
      sF=0.60, sT=1.10, sDur=0.28,
      aF=0.85, aDur=0.20, aDelay=0.18 },
    { id="ripple",          label="Ripple In",
      color={0.40, 0.80, 1.00}, tex=RIPPLE, noPreShrink=true,
      sF=1.30, sT=0.10, sDur=0.30,
      aF=0.50, aDur=0.20, aDelay=0.10 },
    { id="starburst",       label="Starburst",
      color={1.00, 1.00, 0.50}, tex=STAR,
      sF=0.20, sT=1.30, sDur=0.28,
      aF=0.85, aDur=0.18, aDelay=0.18 },
    { id="starburst_large", label="Starburst Large",
      color={1.00, 0.60, 0.00}, tex=STAR, noPreShrink=true,
      sF=0.20, sT=1.60, sDur=0.45,
      aF=0.80, aDur=0.25, aDelay=0.30,
      rot=180 },
    { id="pulse",           label="Pulse",
      color={0.60, 1.00, 0.60}, tex=KF,
      sF=0.90, sT=1.20, sDur=0.22,
      aF=0.70, aDur=0.15, aDelay=0.14 },
    { id="ring_collapse",   label="Square Collapse",
      color={1.00, 0.30, 0.30}, tex=RING, noPreShrink=true,
      sF=1.00, sT=0.10, sDur=0.40,
      aF=0.80, aDur=0.30, aDelay=0.05 },
    { id="star4_bling",     label="Diamond Bling",
      color={1.00, 0.95, 0.70}, tex=STAR4, noPreShrink=true,
      sF=0.10, sT=1.50, sDur=0.22,
      aF=0.85, aDur=0.14, aDelay=0.14 },
    { id="diamond_spin",    label="Diamond Spin",
      color={0.70, 0.92, 1.00}, tex=STAR4, noPreShrink=true,
      sF=0.10, sT=1.20, sDur=0.32,
      aF=0.90, aDur=0.20, aDelay=0.22,
      rot=90 },
    { id="diamond_flash",   label="Diamond Flash",
      color={1.00, 1.00, 1.00}, tex=STAR4, noPreShrink=true,
      sF=0.05, sT=1.00, sDur=0.16,
      aF=1.00, aDur=0.10, aDelay=0.08 },
    { id="classic_star",    label="Classic Star",
      color={1.00, 1.00, 1.00}, tex=STAR4, noPreShrink=true,
      sF=1.00, sT=1.50, sDur=0.30,
      aF=1.00, aDur=0.05, aDelay=0.25,
      rot=90 },
    { id="artifact_burst",  label="Artifact Burst",
      color={0.60, 0.40, 1.00}, tex="ArtifactsFX-StarBurst", isAtlas=true, noPreShrink=true,
      sF=0.30, sT=1.80, sDur=0.40,
      aF=0.90, aDur=0.25, aDelay=0.28 },
    { id="spikey_star",     label="Spikey Star",
      color={0.80, 1.00, 0.80}, tex="ChallengeMode-SpikeyStar", isAtlas=true,
      sF=0.20, sT=1.40, sDur=0.30,
      aF=0.80, aDur=0.20, aDelay=0.20 },
}

KeyFlash.EffectsById = {}
for _, e in ipairs(KeyFlash.Effects) do
    KeyFlash.EffectsById[e.id] = e
end

-- ── Overlay pool ──────────────────────────────────────────────────────────────
local pool = {}

local function NewOverlay(parent)
    local ov = CreateFrame("Frame", nil, parent)
    -- Size and position are set per-play in AcquireOverlay; just anchor here.
    ov:SetPoint("CENTER", parent, "CENTER", 0, 0)
    ov:SetSize(parent:GetWidth(), parent:GetHeight())
    ov:SetFrameLevel(parent:GetFrameLevel() + 5)
    local tex = ov:CreateTexture(nil, "OVERLAY")
    tex:SetBlendMode("ADD")
    tex:SetAllPoints(ov)
    ov.tex = tex
    local ag = ov:CreateAnimationGroup()
    ov.ag  = ag
    ov.sa  = CompatScale(ag:CreateAnimation("Scale"))
    ov.aa  = ag:CreateAnimation("Alpha")
    ov.ra  = ag:CreateAnimation("Rotation")  -- used only when eff.rot is set
    ag:SetScript("OnFinished", function()
        ov:Hide()
        pool[#pool + 1] = ov
    end)
    return ov
end

-- Sizes and returns an overlay frame anchored to button.
-- noPreShrink=true: frame = full button size; scale animation may exceed bounds (soft bloom).
-- noPreShrink=false/nil: frame pre-shrunk so peak scale = button size exactly (no overflow).
local function AcquireOverlay(button, maxScale, noPreShrink)
    local ov
    for i = #pool, 1, -1 do
        if not pool[i]:IsShown() then
            ov = table.remove(pool, i)
            break
        end
    end
    local bw = button:GetWidth()
    local bh = button:GetHeight()
    if bw <= 0 or bh <= 0 then return nil end  -- button not yet laid out
    local ow = noPreShrink and bw or (bw / maxScale)
    local oh = noPreShrink and bh or (bh / maxScale)
    if ov then
        ov:SetParent(button)
    else
        ov = NewOverlay(button)
    end
    ov:ClearAllPoints()
    ov:SetPoint("CENTER", button, "CENTER", 0, 0)
    ov:SetSize(ow, oh)
    ov:SetFrameLevel(button:GetFrameLevel() + 5)
    return ov
end

-- Kept as a no-op for compatibility: it used to do `pool = {}`, which achieved
-- nothing (PlayEffect re-reads colour, speed, size and opacity on every play,
-- and AcquireOverlay re-derives the size) while orphaning every pooled overlay
-- -- WoW frames cannot be destroyed, so they lingered as hidden children of
-- their buttons. The colour picker called it on every OnColorSelect, i.e.
-- continuously while dragging the wheel.
function KeyFlash.RebuildOverlays() end

-- Enable/disable, shared by the minimap button, the addon compartment entry
-- and /kf so all three report the state the same way.
function KeyFlash.PrintStatus()
    print("|cffffe066KeyFlash:|r " ..
        (KeyFlashDB.enabled and "|cff00ff00Enabled|r" or "|cffff4040Disabled|r"))
end

function KeyFlash.SetEnabled(on)
    KeyFlashDB.enabled = on and true or false
    KeyFlash.PrintStatus()
end

function KeyFlash.ToggleEnabled()
    KeyFlash.SetEnabled(not KeyFlashDB.enabled)
end

function KeyFlash.PlayEffect(button)
    if not button then return end
    if not KeyFlashDB or not KeyFlashDB.enabled then return end

    local effectId = KeyFlashDB.effect or "ff14"
    local eff = KeyFlash.EffectsById[effectId] or KeyFlash.Effects[1]
    local es  = (KeyFlashDB.effectSettings or {})[effectId] or {}
    local spd = es.animSpeed or 1.0

    -- Peak visual scale: larger of sF/sT.  For rotating effects, a frame's AABB
    -- grows by up to sqrt(2) when passing through 45°, so we factor that in so
    -- the overlay's bounding box never exceeds the button at any rotation angle.
    -- noPreShrink effects (e.g. ff14) use full button size — soft bloom is intentional.
    local maxScale = math.max(eff.sF, eff.sT)
    if eff.rot and eff.rot ~= 0 then
        maxScale = maxScale * math.sqrt(2)
    end
    local ov = AcquireOverlay(button, maxScale, eff.noPreShrink)
    if not ov then return end

    local sizeScale = es.overlayScale or 1.0
    if sizeScale ~= 1.0 then
        ov:SetSize(ov:GetWidth() * sizeScale, ov:GetHeight() * sizeScale)
    end

    -- Texture & color
    if eff.isAtlas then
        ov.tex:SetAtlas(eff.tex)
    else
        ov.tex:SetTexture(eff.tex)
        if eff.tcx then
            ov.tex:SetTexCoord(eff.tcx[1], eff.tcx[2], eff.tcx[3], eff.tcx[4])
        else
            ov.tex:SetTexCoord(0, 1, 0, 1)
        end
    end

    local stored = KeyFlashDB.effectColors and KeyFlashDB.effectColors[effectId]
    local r, g, b
    if stored then
        r, g, b = stored[1], stored[2], stored[3]
    else
        local c = eff.color or { 1, 1, 1 }
        r, g, b = c[1], c[2], c[3]
    end
    local opacity = es.opacity; if opacity == nil then opacity = 1.0 end
    ov.tex:SetVertexColor(r, g, b, opacity)

    -- Animations (each effect has independent scale and alpha tuning)
    ov.sa:SetScaleFrom(eff.sF, eff.sF)
    ov.sa:SetScaleTo(eff.sT, eff.sT)
    ov.sa:SetDuration((eff.sDur or 0.30) * spd)
    ov.sa:SetOrder(1)

    ov.aa:SetFromAlpha(eff.aF or 1.0)
    ov.aa:SetToAlpha(0)
    ov.aa:SetDuration((eff.aDur or 0.20) * spd)
    ov.aa:SetStartDelay((eff.aDelay or 0) * spd)
    ov.aa:SetOrder(1)

    -- Optional spin (e.g. Starburst Large)
    if eff.rot and eff.rot ~= 0 then
        ov.ra:SetRadians(math.rad(eff.rot))
        ov.ra:SetDuration((eff.sDur or 0.30) * spd)
        ov.ra:SetOrder(1)
        ov.ra:SetOrigin("CENTER", 0, 0)
    else
        ov.ra:SetRadians(0)
        ov.ra:SetDuration(0.001)
        ov.ra:SetOrder(1)
    end

    -- Stop() before Show(): OnFinished still receives the `requested` argument
    -- in 12.x, so stopping a running group can fire it, and our OnFinished
    -- hides the overlay and returns it to the pool. AcquireOverlay only hands
    -- out finished overlays today, so this cannot currently bite -- ordering it
    -- this way keeps it that way if that invariant ever changes.
    if ov.ag:IsPlaying() then ov.ag:Stop() end
    ov:Show()
    ov.ag:Play()
end

-- ── Stub for options (populated by KeyFlashOptions.lua) ──────────────────────
function KeyFlash.OpenSettings() end

-- ── Button scanning ───────────────────────────────────────────────────────────
local slotToButton   = {}
local spellIdToButton = {}  -- spellId → button, for macro-triggered casts
local slotToSpellId   = {}  -- action slot → spellId currently on it; reverse index
                            -- so a slot change can drop its stale spellIdToButton
                            -- entry in O(1) instead of scanning the whole map.

-- Deduplication: a single mouse click reaches us twice -- SecureTemplates.lua
-- calls UseAction (which we hook) and then fires PostClick -- but both land in
-- the same frame. The window only has to outlast one frame, so it is kept just
-- above a 20fps frame time. It used to be 0.15s, which also swallowed genuine
-- repeat presses faster than ~6.6/s, i.e. exactly what spammers do.
local recentFlash   = {}   -- [button] = GetTime() of last flash
local DEDUP_WINDOW  = 0.06 -- seconds

local function FlashButton(btn)
    if not btn then return end
    local now = GetTime()
    if recentFlash[btn] and (now - recentFlash[btn]) < DEDUP_WINDOW then return end
    recentFlash[btn] = now
    KeyFlash.PlayEffect(btn)
end

-- Direct PostClick hook: fires on the exact button frame that was clicked,
-- bypassing the action-slot map entirely.  Reliable for ElvUI whose bar-page
-- offsets can cause the slot map to disagree with what UseAction reports.
-- Mouse presses take this path; keyboard bindings still use the UseAction hook.
local hookedButtons    = {}
local allHookedButtons = {}  -- ordered list used as fallback when slotToButton misses
local function HookButtonDirect(btn)
    if not btn or hookedButtons[btn] then return end
    hookedButtons[btn] = true
    allHookedButtons[#allHookedButtons + 1] = btn
    btn:HookScript("PostClick", function(self, mouseBtn)
        if mouseBtn == "LeftButton" and KeyFlashDB and KeyFlashDB.enabled then
            FlashButton(self)
        end
    end)
end

-- Hooks the pushed-down state so WoW's built-in button-press visual can be
-- suppressed when suppressWowFlash is enabled.  The hook is permanent but
-- cheap: it returns immediately when the setting is off.
local hookedFlash = {}
local function HookButtonFlash(btn)
    if not btn or hookedFlash[btn] then return end
    hookedFlash[btn] = true

    -- btn.Flash is deliberately NOT hooked.  It is not the keypress blink: per
    -- Blizzard_ActionBar/Shared/ActionButton.lua it is driven only by
    -- StartFlash/StopFlash off PLAYER_ENTER_COMBAT and START_AUTOREPEAT_SPELL,
    -- i.e. it is the auto-attack / auto-repeat indicator.  Hiding it would cost
    -- the player the "is my auto-attack running?" readout.
    -- SpellCastAnimFrame is likewise left alone: it shows proc/reactive glows
    -- which are gameplay information and must stay visible.
    -- PushedTexture is the actual keypress visual: the white frame shown when
    -- the button enters PUSHED state.  SetButtonState is C-level so
    -- PushedTexture:Show() is never called from Lua; we hook SetButtonState
    -- itself and zero the texture alpha there instead.
    hooksecurefunc(btn, "SetButtonState", function(self, state)
        if not KeyFlashDB or not KeyFlashDB.suppressWowFlash then return end
        local pt = self:GetPushedTexture()
        if pt then pt:SetAlpha(state == "PUSHED" and 0 or 1) end
        -- WoW hides NormalTexture (the border frame) when entering PUSHED state.
        -- Restore it so the button border stays visible while the pushed overlay is suppressed.
        if state == "PUSHED" then
            local nt = self:GetNormalTexture()
            if nt then nt:Show() end
        end
    end)
end

local BLIZZARD_BARS = {
    { prefix = "ActionButton",              count = 12 },
    { prefix = "MultiBarBottomLeftButton",  count = 12 },
    { prefix = "MultiBarBottomRightButton", count = 12 },
    { prefix = "MultiBarLeftButton",        count = 12 },
    { prefix = "MultiBarRightButton",       count = 12 },
}

local function RegisterButton(btn)
    if not btn then return end
    -- tonumber: third-party bars may expose the attribute as a string, which
    -- would otherwise throw on the comparison below (this runs inside the
    -- frame walk, where only the GetAttribute("type") probe is pcall-guarded).
    local action = tonumber(btn.action or btn:GetAttribute("action"))
    if action and action > 0 then
        -- Prefer the visible button for each slot.  Bar addons hide the standard
        -- Blizzard frames and replace them with their own; registering the hidden
        -- default button would flash an invisible overlay.
        local existing = slotToButton[action]
        if not existing or (btn:IsShown() and not existing:IsShown()) then
            slotToButton[action] = btn
        end
        local atype, spellId = GetActionInfo(action)
        if atype == "spell" and spellId and spellId > 0 then
            spellIdToButton[spellId] = btn
            slotToSpellId[action]    = spellId
        end
    end
end

-- Re-reads which spell sits on one action slot. ACTIONBAR_SLOT_CHANGED arrives
-- as a burst of one event per slot on login and on every spec/talent change, so
-- this has to stay O(1) per slot -- calling ScanButtons here would be a serious
-- regression. slot 0 means "all slots" (see Blizzard's own handler in
-- ActionButton.lua), which is why the caller loops instead.
local function RefreshSlotSpell(action)
    action = tonumber(action)
    if not action or action <= 0 then return end
    local prev = slotToSpellId[action]
    if prev then
        -- Only drop the old mapping if it still points at this slot's button:
        -- the same spell can sit on several slots, and the survivor should keep
        -- its entry.
        if spellIdToButton[prev] == slotToButton[action] then
            spellIdToButton[prev] = nil
        end
        slotToSpellId[action] = nil
    end
    local btn = slotToButton[action]
    if not btn then return end
    local atype, spellId = GetActionInfo(action)
    if atype == "spell" and spellId and spellId > 0 then
        spellIdToButton[spellId] = btn
        slotToSpellId[action]    = spellId
    end
end

-- ── Generic frame walk (fallback discovery) ──────────────────────────────────
-- This is by far the most expensive thing KeyFlash does, and it exists only to
-- find action buttons belonging to bar addons we do not know by name.
--
-- Measured with Blizzard's own profiler (C_AddOnProfiler, via StutterAlert) on
-- a Blizzard-bars install: KeyFlash was blamed for 1101 hitch frames of 40-85ms
-- over ~84 hours, 88% of them in cities, and the dominant signature was
-- "no event firing" -- i.e. the C_Timer chain below, not any event handler.
-- Chunking (added in 1.6) did not fix that; it only decided how the cost was
-- distributed. The fix is to not do the work:
--
--   * gated behind NeedsGenericWalk(), so an install on Blizzard's own bars --
--     which the named passes above already cover completely -- never walks;
--   * one-shot per session rather than per login and per zone change, since bar
--     addons build their buttons once and do not recreate them on zoning;
--   * triggered on demand from FlashSlot when a press lands on a slot the named
--     passes could not resolve, so unknown bars still get covered.
local fullWalkInProgress = false
local genericWalkDone    = false

local FRAMES_PER_CHUNK = 100
local MAX_FRAMES       = 20000
local CHUNK_DELAY      = 0.01   -- deliberately not 0: a zero-delay timer queued
                                -- from inside a timer callback can be picked up
                                -- by the same tick's processing pass, which
                                -- collapses the whole walk back into one frame.

local function ContinueFrameWalk(f, n)
    local processed = 0
    while f and n < MAX_FRAMES and processed < FRAMES_PER_CHUNK do
        n = n + 1
        processed = processed + 1
        local ok, atype = pcall(f.GetAttribute, f, "type")
        if ok and atype == "action" then
            RegisterButton(f)
            HookButtonDirect(f)
            HookButtonFlash(f)
        end
        f = EnumerateFrames(f)
    end
    if f and n < MAX_FRAMES then
        if C_Timer then
            C_Timer.After(CHUNK_DELAY, function() ContinueFrameWalk(f, n) end)
        else
            -- No C_Timer (very old client) — finish synchronously rather
            -- than leaving the scan incomplete.
            ContinueFrameWalk(f, n)
        end
    else
        fullWalkInProgress = false
    end
end

-- Blizzard's main bar being visible means the player is on the default bars
-- (Masque skinning included), which the named pass already covers button for
-- button. Bar addons that replace them hide these frames.
local function NeedsGenericWalk()
    local ab1 = _G.ActionButton1
    if ab1 and ab1:IsShown() then return false end
    return true
end

local function StartGenericWalk()
    if genericWalkDone or fullWalkInProgress or not EnumerateFrames then return end
    genericWalkDone    = true
    fullWalkInProgress = true
    ContinueFrameWalk(EnumerateFrames(), 0)
end

-- fullScan is only about whether the generic fallback walk may be considered:
-- pass true for login/world-entry, false for high-frequency events like
-- ACTIONBAR_PAGE_CHANGED/UPDATE_BONUS_ACTIONBAR, where the named passes below
-- already give full coverage cheaply.
local function ScanButtons(fullScan)
    slotToButton    = {}
    spellIdToButton = {}
    slotToSpellId   = {}
    for _, bar in ipairs(BLIZZARD_BARS) do
        for i = 1, bar.count do
            local btn = _G[bar.prefix .. i]
            RegisterButton(btn)
            -- PostClick too: ActionButtonDown/MultiActionButtonDown only cover
            -- keybinds, so without this, mouse clicks on the default bars were
            -- only ever hooked as a side effect of the generic frame walk.
            HookButtonDirect(btn)
            HookButtonFlash(btn)
        end
    end
    -- Bartender4: buttons named BT4Button1-120 (10 bars × 12 buttons)
    for i = 1, 120 do
        local btn = _G["BT4Button" .. i]
        if btn then
            RegisterButton(btn)
            HookButtonDirect(btn)
            HookButtonFlash(btn)
        end
    end
    -- ElvUI (buttons are initialized late; explicit scan ensures they register
    -- even if the generic EnumerateFrames pass runs before ElvUI finishes setup;
    -- PostClick hooks are also installed for reliable mouse-click detection)
    for bar = 1, 10 do
        for i = 1, 12 do
            local btn = _G["ElvUI_Bar" .. bar .. "Button" .. i]
            RegisterButton(btn)
            HookButtonDirect(btn)
            HookButtonFlash(btn)
        end
    end
    -- Dominos: buttons are named DominosActionButton1-168 (globally sequential
    -- across all bars, 14 bars × 12 buttons).  PostClick hooks cover mouse clicks;
    -- UseAction hook (forced when Dominos is loaded) covers keybinds and macros.
    if IsAddOnLoaded and IsAddOnLoaded("Dominos") then
        for i = 1, 168 do
            local btn = _G["DominosActionButton" .. i]
            if btn then
                RegisterButton(btn)
                HookButtonDirect(btn)
                HookButtonFlash(btn)
            end
        end
    end
    -- Fallback discovery for bar addons we do not know by name.  Skipped
    -- entirely on Blizzard's own bars, and at most once per session -- see the
    -- StartGenericWalk block above for why.
    if fullScan and NeedsGenericWalk() then
        StartGenericWalk()
    end
end

local function FlashSlot(action)
    local btn = action and slotToButton[action]
    -- If the cached button is hidden a bar addon has replaced it with its own
    -- visible frame.  Discard it and search dynamically.
    if btn and not btn:IsShown() then btn = nil end
    if not btn then
        -- Walk all hooked buttons; prefer visible ones so we never flash a hidden
        -- default-bar button that a bar addon has moved off-screen.
        local hiddenMatch
        for _, b in ipairs(allHookedButtons) do
            if b.action == action then
                if b:IsShown() then
                    btn = b
                    break
                elseif not hiddenMatch then
                    hiddenMatch = b
                end
            end
        end
        btn = btn or hiddenMatch
        if not btn then
            -- Nothing we know of owns this slot, so some bar addon we do not
            -- recognise by name does.  Pay for the generic walk here, once,
            -- instead of speculatively on every login and zone change.
            StartGenericWalk()
        end
        if btn then slotToButton[action] = btn end
    end
    if btn then FlashButton(btn) end
end

-- ── Action hooks ──────────────────────────────────────────────────────────────
local hooksInstalled = false

local function HookUseAction()
    if hooksInstalled then return end
    hooksInstalled = true
    hooksecurefunc("UseAction", function(action)
        FlashSlot(action)
    end)
end

local function HookDefaultBindings()
    if hooksInstalled then return end
    hooksInstalled = true
    local GetActionButtonForID = _G.GetActionButtonForID
    -- Midnight (12.0) removed ActionButtonDown; fall back to UseAction hook
    if not GetActionButtonForID or not _G.ActionButtonDown then
        hooksecurefunc("UseAction", function(action) FlashSlot(action) end)
        return
    end
    hooksecurefunc("ActionButtonDown", function(id)
        local btn = GetActionButtonForID(id)
        if btn then FlashSlot(btn.action) end
    end)
    if _G.MultiActionButtonDown then
        hooksecurefunc("MultiActionButtonDown", function(barName, id)
            local bar = _G[barName]
            local btn = (bar and bar.actionButtons and bar.actionButtons[id])
                     or _G[barName .. "Button" .. id]
            if btn then FlashSlot(btn.action) end
        end)
    end
end

-- ── Minimap button ────────────────────────────────────────────────────────────
-- Position logic mirrors LibDBIcon-1.0: accounts for minimap shape variants,
-- actual minimap size, and UI effective scale during drag.
local minimapShapes = {
    ["ROUND"]                 = {true,  true,  true,  true },
    ["SQUARE"]                = {false, false, false, false},
    ["CORNER-TOPLEFT"]        = {false, false, false, true },
    ["CORNER-TOPRIGHT"]       = {false, false, true,  false},
    ["CORNER-BOTTOMLEFT"]     = {false, true,  false, false},
    ["CORNER-BOTTOMRIGHT"]    = {true,  false, false, false},
    ["SIDE-LEFT"]             = {false, true,  false, true },
    ["SIDE-RIGHT"]            = {true,  false, true,  false},
    ["SIDE-TOP"]              = {false, false, true,  true },
    ["SIDE-BOTTOM"]           = {true,  true,  false, false},
    ["TRICORNER-TOPLEFT"]     = {false, true,  true,  true },
    ["TRICORNER-TOPRIGHT"]    = {true,  false, true,  true },
    ["TRICORNER-BOTTOMLEFT"]  = {true,  true,  false, true },
    ["TRICORNER-BOTTOMRIGHT"] = {true,  true,  true,  false},
}
local MINIMAP_EDGE_OFFSET = 5

local function MinimapButtonPos(button, deg)
    local rad   = math.rad(deg or 0)
    local x, y  = math.cos(rad), math.sin(rad)
    local q     = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local shape      = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quadTable  = minimapShapes[shape] or minimapShapes.ROUND
    local w = (Minimap:GetWidth()  / 2) + MINIMAP_EDGE_OFFSET
    local h = (Minimap:GetHeight() / 2) + MINIMAP_EDGE_OFFSET
    if quadTable[q] then
        x, y = x * w, y * h
    else
        local dw = math.sqrt(2 * w^2) - 10
        local dh = math.sqrt(2 * h^2) - 10
        x = math.max(-w, math.min(x * dw, w))
        y = math.max(-h, math.min(y * dh, h))
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    local mb = CreateFrame("Button", "KeyFlashMinimapButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFixedFrameStrata(true)
    mb:SetFrameLevel(8)
    mb:SetFixedFrameLevel(true)
    mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mb:RegisterForDrag("LeftButton")

    local icon = mb:CreateTexture(nil, "ARTWORK")
    icon:SetTexture([[Interface\AddOns\KeyFlash\minimap_icon.tga]])
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")

    local border = mb:CreateTexture(nil, "OVERLAY")
    border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
    border:SetSize(WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and 50 or 53,
                   WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and 50 or 53)
    border:SetPoint("TOPLEFT", 0, 0)

    mb:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])

    mb:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my  = Minimap:GetCenter()
            local px, py  = GetCursorPosition()
            local scale   = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360
            KeyFlashDB.minimapAngle = pos
            MinimapButtonPos(mb, pos)
        end)
    end)

    mb:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    mb:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then
            KeyFlash.ToggleEnabled()
        else
            KeyFlash.OpenSettings()
        end
    end)

    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("KeyFlash", 1, 1, 0)
        GameTooltip:AddLine("|cffaaaaaaLeft-click:|r Open Settings", 1, 1, 1)
        GameTooltip:AddLine("|cffaaaaaaRight-click:|r Toggle flashes on/off", 1, 1, 1)
        GameTooltip:Show()
    end)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    MinimapButtonPos(mb, KeyFlashDB.minimapAngle or 220)
    if KeyFlashDB.minimapHide then mb:Hide() end

    KeyFlash.minimapButton = mb

    -- Addon Compartment (WoW 10+)
    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        AddonCompartmentFrame:RegisterAddon({
            text                = "KeyFlash",
            icon                = [[Interface\AddOns\KeyFlash\minimap_icon.tga]],
            registerForAnyClick = true,
            notCheckable        = true,
            -- Since 11.0 the compartment runs on the new menu framework:
            -- Blizzard_Menu/Menu.lua calls the responder as
            -- func(data, menuInputData, menu), with the mouse button in
            -- menuInputData.buttonName.  The old five-argument
            -- UIDropDownMenu signature left buttonName permanently nil, so
            -- right-click never toggled.  Guarded so an older client that
            -- still passes the legacy shape degrades to opening settings.
            func = function(_, inputData)
                local mouseBtn = type(inputData) == "table" and inputData.buttonName
                if mouseBtn == "RightButton" then
                    KeyFlash.ToggleEnabled()
                else
                    KeyFlash.OpenSettings()
                end
            end,
        })
    end
end

-- ── Slash commands ────────────────────────────────────────────────────────────
SLASH_KEYFLASH1 = "/keyflash"
SLASH_KEYFLASH2 = "/kf"
SlashCmdList["KEYFLASH"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if     msg == "on"     then KeyFlash.SetEnabled(true)
    elseif msg == "off"    then KeyFlash.SetEnabled(false)
    elseif msg == "toggle" then KeyFlash.ToggleEnabled()
    else   KeyFlash.OpenSettings()
    end
end

-- ── Initialization ────────────────────────────────────────────────────────────

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        local unit, _, _, spellId = ...
        if unit == "player" and KeyFlashDB and KeyFlashDB.enabled then
            local btn = spellId and spellIdToButton[spellId]
            if btn then FlashButton(btn) end
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- Keeps the macro fallback map (spellIdToButton) current when the player
        -- rearranges the bars, swaps spec or changes talents. slotToButton needs
        -- no refresh: slot numbers are stable, only their contents change.
        local slot = ...
        if tonumber(slot) == 0 then
            for action in pairs(slotToButton) do RefreshSlotSpell(action) end
        else
            RefreshSlotSpell(slot)
        end
    elseif event == "PLAYER_LOGIN" then
        SetupDB()
        if KeyFlashDB.lastSeenVersion ~= KeyFlash.VERSION then
            KeyFlashDB.lastSeenVersion = KeyFlash.VERSION
            if C_Timer then
                C_Timer.After(3, function() KeyFlash.ShowWhatsNew() end)
            end
        end
        ScanButtons(false)   -- bars may not be visible yet; the walk decision waits
        local useHook = KeyFlashDB.forceUseActionHook
            or (IsAddOnLoaded and (
                IsAddOnLoaded("Bartender4") or
                IsAddOnLoaded("Neuron")     or
                IsAddOnLoaded("ElvUI")      or
                IsAddOnLoaded("TukUI")      or
                IsAddOnLoaded("Dominos")))
        if useHook then
            HookUseAction()
        else
            HookDefaultBindings()
        end
        CreateMinimapButton()

        -- ── Compatibility notice for mUI (by muleyo)
        -- mUI has its own action bar flash module that hooks ActionButtonDown with
        -- the same star4 texture. Both addons fire independently; if mUI's flash is
        -- enabled this results in two overlapping effects per keypress.
        -- We just inform the user — we never disable or interfere with mUI.
        -- Shown once per KeyFlash version rather than on every single login.
        if IsAddOnLoaded and IsAddOnLoaded("mUI")
                and KeyFlashDB.lastMuiNotice ~= KeyFlash.VERSION then
            local mdb = _G["mUIDB"]
            local muiFlashOn = (mdb == nil)  -- default is enabled if no saved var yet
            if mdb and mdb.profiles then
                local key = mdb.profileKeys
                    and mdb.profileKeys[UnitName("player") .. " - " .. GetRealmName()]
                    or "Default"
                local profile = mdb.profiles[key]
                local bars    = profile and profile.actionbars
                muiFlashOn    = bars ~= nil and bars.flash ~= false
            end
            if muiFlashOn then
                KeyFlashDB.lastMuiNotice = KeyFlash.VERSION
                print("|cffffe066KeyFlash:|r |cffaaaaaamUI detected with button flash enabled.|r")
                print("|cffaaaaaa  Both effects will play on every keypress. To avoid doubling,")
                print("  disable mUI's flash via |r|cfffff066/mUI|r |cffaaaaaa→ ActionBars → Button Flash.|r")
            end
        end

        self:UnregisterEvent("PLAYER_LOGIN")
        -- ElvUI and some other bar addons finish building their buttons after
        -- PLAYER_LOGIN. Schedule a follow-up scan so they are caught in time.
        if C_Timer then
            C_Timer.After(2, function() ScanButtons(true) end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ScanButtons(false)   -- as above: named passes now, walk decision on the delayed scan
        -- Re-scan after a short delay on world entry to catch any bar addon
        -- (e.g. ElvUI) that finalises its buttons on the next few frames.
        if C_Timer then
            C_Timer.After(2, function() ScanButtons(true) end)
        end
    else
        -- ACTIONBAR_PAGE_CHANGED / UPDATE_BONUS_ACTIONBAR: named-bar passes
        -- above already give these full coverage; skip the expensive generic
        -- walk since these events can fire repeatedly in quick succession
        -- (stance/form changes, vehicle mounts) during combat.
        ScanButtons(false)
    end
end)
