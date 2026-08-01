local Transmog = _G.Transmog

transmogOutfits = {}
Transmog.availableTransmogItems = {}
Transmog.ItemButtons = {}
Transmog.currentTransmogSlotName = nil
Transmog.currentTransmogSlot = nil
Transmog.currentTransmogItemClass = nil
Transmog.currentPage = 1
Transmog.totalPages = 1
Transmog.ipp = 15
Transmog.numTransmogs = {}
Transmog.transmogDataFromServer = {}
Transmog.transmogStatusFromServer = {}
Transmog.transmogStatusToServer = {}
Transmog.tab = ''
Transmog.equippedItems = {}
Transmog.currentOutfit = nil
Transmog.equippedTransmogs = {}

Transmog.localCache = {}

-- Session-only visual test mode. This value is intentionally not stored in
-- SavedVariables and resets whenever the UI is reloaded or the client exits.
Transmog.testMode = false
Transmog.testModeDisplayCount = 45
