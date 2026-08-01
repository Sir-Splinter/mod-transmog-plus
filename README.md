# mod-transmog-plus

Slot-based transmogrification module for [AzerothCore](https://github.com/azerothcore/azerothcore-wotlk).

Appearances are stored per equipment slot rather than per item, so your selected look remains active when you replace or swap gear.

## Features

- Slot-based transmogrification — appearances remain attached to the equipment slot when gear is swapped.
- Account-wide appearance collection — appearances unlocked by one character are available to every character on the same account.
- Configurable appearance-unlock rules.
- Optional retail-inspired collection behavior.
- Optional appearance unlocking when an item is obtained.
- Optional appearance unlocking when an item is equipped.
- Configurable binding requirements for collection.
- Configurable class, armor-type, weapon-type, race, and proficiency eligibility checks.
- Option to hide individual armor slots, including helm, shoulders, chest, cloak, and other supported slots.
- Configurable prices, quality restrictions, type rules, and requirement overrides.
- Gossip-menu fallback when the client addon is not installed.

## Collection Modes

The module supports several collection configurations.

### Legacy behavior

Appearances unlock when an eligible item is equipped.

```ini
Transmog.CollectionUnlockSource = 0
Transmog.CollectionBindingRequirement = 0
Transmog.CollectionEligibility = 0
Transmog.CollectionUnlockOnEquip = 1
```

### Retail-inspired behavior

Eligible appearances are collected when an item is obtained and satisfies the configured binding requirements.

Collection eligibility is evaluated independently from whether a character may currently apply that appearance.

```ini
Transmog.CollectionUnlockSource = 1
Transmog.CollectionBindingRequirement = 2
Transmog.CollectionEligibility = 1
Transmog.CollectionUnlockOnEquip = 1
```

This allows an account to collect eligible appearances across different characters and classes while retaining the normal application restrictions.

See `conf/mod_transmog_plus.conf.dist` for descriptions of every mode and available value.

## Optional Client Addon

This module includes a WoW 3.3.5a client addon in the `addon/` directory.

The addon provides:

- Visual transmogrification interface.
- 3D character and appearance previews.
- Appearance sorting by item level or name.
- Appearance filtering by item subtype.
- Full-name appearance search.
- Collected-appearance counter.
- Multi-page appearance grid.
- Outfit saving and loading.
- Slot hiding and reset controls.
- Class-aware weapon-slot display.
- Session-only layout test mode.

If the addon is not installed, the standard gossip menu is used as a fallback.

![Addon UI](docs/Addon_Preview.png)

### Addon test mode

The addon includes a client-side test mode for testing the layout without adding appearances or changing account or character data.

Toggle it with:

```text
/transmog testmode
```

While test mode is active:

- The appearance grid is filled with repeated client-side preview entries.
- Three appearance pages can be tested.
- All three lower equipment-slot buttons are displayed.
- Applying transmogrifications is disabled.
- Outfit modification is disabled.
- No collection, account, character, or server data is changed.
- The window title indicates that test mode is active.

Run the command again to disable test mode.

Test mode is not saved and automatically resets after logout, client restart, or `/reload`.

### Known addon issue

- The glow border for equipment slots with pending transmogrification changes may not display correctly.

## Installation

1. Place the module under the `modules/` directory of your AzerothCore source tree.

   ```text
   modules/mod-transmog-plus
   ```

2. Re-run CMake and rebuild AzerothCore.

3. Copy:

   ```text
   conf/mod_transmog_plus.conf.dist
   ```

   to:

   ```text
   mod_transmog_plus.conf
   ```

4. Review and adjust the configuration options.

5. Import the SQL files manually, or allow AzerothCore to auto-import them during the next server startup.

6. Spawn the transmogrification NPC in game:

   ```text
   .npc add 190012
   ```

### Addon installation

Copy:

```text
addon/Transmog/
```

to the WoW client's addon directory:

```text
Interface/AddOns/Transmog/
```

Restart the client or run:

```text
/reload
```

after replacing addon files.

## Configuration

All module settings are documented in:

```text
conf/mod_transmog_plus.conf.dist
```

Configuration includes:

- Collection unlock source.
- Collection binding requirements.
- Collection eligibility rules.
- Unlock-on-equip behavior.
- Account-wide collection behavior.
- Transmogrification prices.
- Item-quality restrictions.
- Armor and weapon compatibility.
- Mixed armor-type rules.
- Class, race, skill, level, and proficiency requirements.
- Requirement-ignore options.
- Hidden-slot behavior.

Collection eligibility and appearance application restrictions are separate systems.

For example, retail-inspired collection may allow an account to collect an appearance through one character while normal armor, weapon, or class restrictions continue to control which characters may apply it.

## Known Limitations

### Hidden appearance icon

When an equipment slot is hidden, its character-sheet icon becomes invisible instead of displaying a dedicated hidden-slot icon.

A fake item entry is used to represent the hidden state because it is required for the client equipment display to refresh correctly.

### Equipment-set counter

Transmogrifying an item belonging to an equipment set may cause the client to display an incorrect equipped-set count, such as `5/6` instead of `6/6`.

The set bonus continues to function correctly. This is only a character-sheet display issue.

### Client cache

Some appearance, equipment, or addon-display changes may require a relog or `/reload` before the client refreshes every visual element.

## Credits

- [flekz-games](https://github.com/flekz-games) for [cmangos-transmog](https://github.com/flekz-games/cmangos-transmog)
- [malinmr](https://github.com/malinmr) for porting the addon to AzerothCore
- [Stefan2102](https://github.com/Stefan2102) for the original `mod-transmog-plus` AzerothCore module

## License

GNU Affero General Public License v3. See `LICENSE`.
