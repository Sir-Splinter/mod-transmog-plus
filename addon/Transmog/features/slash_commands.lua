local Transmog = _G.Transmog

-- Shows the transmog alert anchor, or toggles the session-only UI test mode.
SLASH_TRANSMOG1 = "/transmog"
SlashCmdList["TRANSMOG"] = function(cmd)
    cmd = string.lower((cmd or ""):gsub("^%s+", ""):gsub("%s+$", ""))

    if cmd == "testmode" then
        Transmog:SetTestMode(not Transmog.testMode)
        return
    end

    if cmd == "help" then
        twfprint("/transmog testmode - toggle session-only grid test mode")
        return
    end

    Transmog.newTransmogAlert:ShowAnchor()
end

-- Toggles debug mode on/off.
SLASH_TRANSMOGDEBUG1 = "/transmogdebug"
SlashCmdList["TRANSMOGDEBUG"] = function(cmd)
    if cmd then
        if Transmog.debug then
            Transmog.debug = false
            twfprint("Transmog debug off")
        else
            Transmog.debug = true
            twfprint("Transmog debug on")
        end
    end
end

-- Registers TransmogFrame for ESC key handling (we hide GossipFrame and
-- replace it with our own frame, so Blizzard's default ESC logic needs this).
if not UISpecialFrames then
    UISpecialFrames = {}
end
tinsert(UISpecialFrames, "TransmogFrame")
