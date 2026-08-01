#include "Transmog.h"
#include "Chat.h"

// Keep one shared collection cache per account while logged-in players reference it.
// Load one account cache and reuse it for all characters from that account.
void Transmog::LoadCollectionForAccount(uint32 accountId)
{
    {
        // Readers can inspect the shared cache concurrently.
        std::shared_lock<std::shared_mutex> lock(collectionMutex);
        if (collectionCache.contains(accountId))
            return;
    }

    std::unordered_set<uint32> items;
    QueryResult result = CharacterDatabase.Query("SELECT item_template_id FROM mod_transmog_plus_appearances WHERE account_id = {}", accountId);
    if (result)
    {
        do
        {
            items.insert((*result)[0].Get<uint32>());
        } while (result->NextRow());
    }

    std::unique_lock<std::shared_mutex> lock(collectionMutex);
    if (!collectionCache.contains(accountId))
        collectionCache.emplace(accountId, std::move(items));
}

// Release the account cache only after the last character stops using it.
void Transmog::UnrefCollectionForAccount(uint32 accountId)
{
    std::unique_lock<std::shared_mutex> lock(collectionMutex);
    auto refIt = collectionRefCounts.find(accountId);
    if (refIt == collectionRefCounts.end())
        return;

    if (--refIt->second == 0)
    {
        collectionRefCounts.erase(refIt);
        collectionCache.erase(accountId);
    }
}

// Collection updates use an exclusive lock so readers never observe a partial insert.
bool Transmog::AddCollectedAppearance(uint32 accountId, uint32 itemId)
{
    std::unique_lock<std::shared_mutex> lock(collectionMutex);
    auto accountIt = collectionCache.find(accountId);
    if (accountIt == collectionCache.end())
    {
        collectionCache.emplace(accountId, std::unordered_set<uint32>{ itemId });
        return true;
    }

    auto result = accountIt->second.insert(itemId);
    return result.second;
}

// Add one appearance through a shared path used by equip and acquisition hooks.
bool Transmog::TryCollectAppearance(Player* player, Item* item, bool acquired)
{
    if (!Enable || !player || !item)
        return false;

    ItemTemplate const* itemTemplate = item->GetTemplate();
    if (!itemTemplate)
        return false;

    if (acquired)
    {
        if (CollectionUnlockSource != TransmogCollectionUnlockSource::Acquired)
            return false;

        switch (CollectionBindingRequirement)
        {
            case TransmogCollectionBindingRequirement::Any:
                break;
            case TransmogCollectionBindingRequirement::BindOnPickupOnly:
                if (itemTemplate->Bonding != BIND_WHEN_PICKED_UP)
                    return false;
                break;
            case TransmogCollectionBindingRequirement::PermanentlyBound:
                if (!item->IsSoulBound() && itemTemplate->Bonding != BIND_WHEN_PICKED_UP)
                    return false;
                break;
        }
    }
    else if (!CollectionUnlockOnEquip)
    {
        return false;
    }

    bool eligible = false;
    if (!acquired)
    {
        // Preserve the original module's equip-time collection behavior exactly.
        eligible = (itemTemplate->Class == ITEM_CLASS_ARMOR || itemTemplate->Class == ITEM_CLASS_WEAPON) &&
            !TransmogRules_CanNeverTransmog(itemTemplate);
    }
    else
    {
        eligible = CollectionEligibility == TransmogCollectionEligibility::AccountCollectible
            ? TransmogRules_IsCollectibleAppearance(itemTemplate)
            : TransmogRules_SuitableForTransmogrification(player, itemTemplate);
    }

    if (!eligible)
        return false;

    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 itemId = itemTemplate->ItemId;

    LoadCollectionForAccount(accountId);
    if (!AddCollectedAppearance(accountId, itemId))
        return false;

    CharacterDatabase.Execute(
        "INSERT IGNORE INTO mod_transmog_plus_appearances (account_id, item_template_id) VALUES ({}, {})",
        accountId, itemId);

    ChatHandler(player->GetSession()).PSendSysMessage(
        "{} {}",
        GetItemLink(itemId, player->GetSession()),
        Tstr(player->GetSession(), LANG_TRANSMOG_APPEARANCE_ADDED));

    return true;
}
