#include "Transmog.h"
#include "Log.h"

namespace
{
    std::set<uint32> ParseEntryList(std::string const& value)
    {
    // Configuration entry lists are whitespace-separated numeric item IDs.
    std::set<uint32> entries;
        std::istringstream stream(value);
        for (uint32 entry; stream >> entry;)
            entries.insert(entry);
        return entries;
    }
}

// Load all policy switches before any player or appearance request is handled.
void Transmog::LoadConfig()
{
    Enable = sConfigMgr->GetOption<bool>("Transmog.Enable", true);
    PriceCopper = sConfigMgr->GetOption<uint32>("Transmog.PriceCopper", 1000);

    Allowed = ParseEntryList(sConfigMgr->GetOption<std::string>("Transmog.Allowed", ""));
    NotAllowed = ParseEntryList(sConfigMgr->GetOption<std::string>("Transmog.NotAllowed", ""));

    AllowPoor = sConfigMgr->GetOption<bool>("Transmog.AllowPoor", true);
    AllowCommon = sConfigMgr->GetOption<bool>("Transmog.AllowCommon", true);
    AllowUncommon = sConfigMgr->GetOption<bool>("Transmog.AllowUncommon", true);
    AllowRare = sConfigMgr->GetOption<bool>("Transmog.AllowRare", true);
    AllowEpic = sConfigMgr->GetOption<bool>("Transmog.AllowEpic", true);
    AllowLegendary = sConfigMgr->GetOption<bool>("Transmog.AllowLegendary", true);
    AllowArtifact = sConfigMgr->GetOption<bool>("Transmog.AllowArtifact", true);
    AllowHeirloom = sConfigMgr->GetOption<bool>("Transmog.AllowHeirloom", true);

    AllowMixedArmorTypes = sConfigMgr->GetOption<bool>("Transmog.AllowMixedArmorTypes", false);
    AllowMixedOffhandArmorTypes = sConfigMgr->GetOption<bool>("Transmog.AllowMixedOffhandArmorTypes", false);
    AllowLowerTiers = sConfigMgr->GetOption<bool>("Transmog.AllowLowerTiers", false);
    AllowMixedWeaponHandedness = sConfigMgr->GetOption<bool>("Transmog.AllowMixedWeaponHandedness", true);
    AllowFishingPoles = sConfigMgr->GetOption<bool>("Transmog.AllowFishingPoles", false);
    AllowMixedWeaponTypes = sConfigMgr->GetOption<uint8>("Transmog.AllowMixedWeaponTypes", 1);

    IgnoreReqRace = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqRace", false);
    IgnoreReqClass = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqClass", false);
    IgnoreReqSkill = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqSkill", false);
    IgnoreReqSpell = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqSpell", false);
    IgnoreReqEvent = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqEvent", false);
    IgnoreReqStats = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqStats", false);

    // CollectionUnlockMode replaces the older pair of CollectionUnlockSource and
    // CollectionUnlockOnEquip. A negative sentinel lets existing installations
    // continue using their old config until an administrator updates it.
    int32 configuredUnlockMode = sConfigMgr->GetOption<int32>("Transmog.CollectionUnlockMode", -1);
    if (configuredUnlockMode >= 0)
    {
        if (configuredUnlockMode > static_cast<int32>(TransmogCollectionUnlockMode::AcquiredAndEquipped))
        {
            LOG_WARN("module", "mod-transmog-plus: Invalid Transmog.CollectionUnlockMode value {}. "
                "Expected 0, 1, or 2. Falling back to 0 (EQUIPPED_ONLY).", configuredUnlockMode);
            configuredUnlockMode = static_cast<int32>(TransmogCollectionUnlockMode::EquippedOnly);
        }

        // The new option is authoritative. Deprecated options are intentionally
        // not read here, so they can never override or interfere with it.
        CollectionUnlockMode = static_cast<TransmogCollectionUnlockMode>(configuredUnlockMode);
    }
    else
    {
        uint8 legacyUnlockSource = sConfigMgr->GetOption<uint8>("Transmog.CollectionUnlockSource", 0);
        bool legacyUnlockOnEquip = sConfigMgr->GetOption<bool>("Transmog.CollectionUnlockOnEquip", true);

        if (legacyUnlockSource > 1)
        {
            LOG_WARN("module", "mod-transmog-plus: Invalid deprecated Transmog.CollectionUnlockSource value {}. "
                "Treating it as 0 (EQUIPPED_ONLY).", static_cast<uint32>(legacyUnlockSource));
            legacyUnlockSource = 0;
        }

        if (legacyUnlockSource == 1)
        {
            CollectionUnlockMode = legacyUnlockOnEquip
                ? TransmogCollectionUnlockMode::AcquiredAndEquipped
                : TransmogCollectionUnlockMode::AcquiredOnly;
        }
        else
        {
            // The obsolete 0 + 0 combination used to stop all collection. There
            // is no collection-disabled mode now; Transmog.Enable controls the
            // module, so the safest migration is the original equip-only behavior.
            CollectionUnlockMode = TransmogCollectionUnlockMode::EquippedOnly;
            if (!legacyUnlockOnEquip)
            {
                LOG_WARN("module", "mod-transmog-plus: Deprecated collection settings resolve to no unlock path. "
                    "Falling back to Transmog.CollectionUnlockMode = 0 (EQUIPPED_ONLY). "
                    "Use Transmog.Enable = 0 to disable the module.");
            }
        }

        LOG_WARN("module", "================================================================");
        LOG_WARN("module", "mod-transmog-plus: OUTDATED COLLECTION CONFIGURATION DETECTED");
        LOG_WARN("module", "mod-transmog-plus: Transmog.CollectionUnlockSource and "
            "Transmog.CollectionUnlockOnEquip are deprecated.");
        LOG_WARN("module", "mod-transmog-plus: Their values were translated for this startup. "
            "Update mod_transmog_plus.conf and add:");
        LOG_WARN("module", "mod-transmog-plus: Transmog.CollectionUnlockMode = {}",
            static_cast<uint32>(CollectionUnlockMode));
        LOG_WARN("module", "================================================================");
    }

    uint8 bindingRequirement = sConfigMgr->GetOption<uint8>("Transmog.CollectionBindingRequirement", 0);
    if (bindingRequirement > static_cast<uint8>(TransmogCollectionBindingRequirement::PermanentlyBound))
        bindingRequirement = static_cast<uint8>(TransmogCollectionBindingRequirement::Any);
    CollectionBindingRequirement = static_cast<TransmogCollectionBindingRequirement>(bindingRequirement);

    uint8 eligibility = sConfigMgr->GetOption<uint8>("Transmog.CollectionEligibility", 0);
    if (eligibility > static_cast<uint8>(TransmogCollectionEligibility::AccountCollectible))
        eligibility = static_cast<uint8>(TransmogCollectionEligibility::CharacterUsable);
    CollectionEligibility = static_cast<TransmogCollectionEligibility>(eligibility);

}
