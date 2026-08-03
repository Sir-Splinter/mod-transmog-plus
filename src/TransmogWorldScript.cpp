#include "Transmog.h"
#include "Log.h"

class TransmogWorldScript : public WorldScript
{
public:
    TransmogWorldScript() : WorldScript("TransmogWorldScript", {
        WORLDHOOK_ON_AFTER_CONFIG_LOAD,
        WORLDHOOK_ON_STARTUP
    }) { }

    // AzerothCore calls this after the initial configuration load and again
    // after `.reload config`. Runtime transmog settings therefore take effect
    // immediately without clearing collections or restarting worldserver.
    void OnAfterConfigLoad(bool reload) override
    {
        sTransmog->LoadConfig();

        if (reload)
        {
            LOG_INFO("module", "mod-transmog-plus: Configuration reloaded. "
                "Reloaded settings include module enablement, prices, allow/deny lists, "
                "collection rules, quality rules, armor/weapon compatibility, and requirement ignores. "
                "New values apply to subsequent acquisitions, equips, and transmog actions.");
        }
    }

    // Database cleanup is startup-only and must not run on config reload.
    void OnStartup() override
    {
        CharacterDatabase.Execute("DELETE FROM mod_transmog_plus WHERE NOT EXISTS "
            "(SELECT 1 FROM characters WHERE characters.guid = mod_transmog_plus.Owner)");
    }
};

void AddSC_TransmogWorldScript()
{
    new TransmogWorldScript();
}
