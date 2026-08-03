# Transmog Collection Rules

Collection controls whether an appearance is learned for the account. Existing transmog rules
still control whether a character may apply that appearance.

## Unlock mode

```ini
Transmog.CollectionUnlockMode = 0
```

- `0 = EQUIPPED_ONLY` -- learn an eligible appearance when the item is equipped. This is the original behavior and safest default.
- `1 = ACQUIRED_ONLY` -- learn an eligible appearance when the item enters the player's inventory. Acquisition binding rules apply.
- `2 = ACQUIRED_AND_EQUIPPED` -- check on acquisition and again on equip. Equip provides a fallback for items that become collectible only after binding.

## Binding requirement

```ini
Transmog.CollectionBindingRequirement = 0
```

This option is used for acquisition-time collection in modes `1` and `2`.

- `0 = ANY` -- accept any otherwise eligible acquired item.
- `1 = BIND_ON_PICKUP_ONLY` -- accept acquired items only when their template is Bind on Pickup.
- `2 = PERMANENTLY_BOUND` -- accept items already soulbound or whose template is Bind on Pickup.

## Eligibility

```ini
Transmog.CollectionEligibility = 0
```

- `0 = CHARACTER_USABLE` -- the current character must satisfy normal collection restrictions.
- `1 = ACCOUNT_COLLECTIBLE` -- collect otherwise valid armor and weapon appearances even when the current character cannot personally use them. Application restrictions remain unchanged.

## Presets

### Legacy

```ini
Transmog.CollectionUnlockMode = 0
Transmog.CollectionBindingRequirement = 0
Transmog.CollectionEligibility = 0
```

### Every class-usable acquired item

```ini
Transmog.CollectionUnlockMode = 1
Transmog.CollectionBindingRequirement = 0
Transmog.CollectionEligibility = 0
```

### BoP acquisition with equip fallback

```ini
Transmog.CollectionUnlockMode = 2
Transmog.CollectionBindingRequirement = 1
Transmog.CollectionEligibility = 0
```

### Retail-inspired account collection

```ini
Transmog.CollectionUnlockMode = 2
Transmog.CollectionBindingRequirement = 2
Transmog.CollectionEligibility = 1
```

## Compatibility with older configurations

The deprecated settings `Transmog.CollectionUnlockSource` and
`Transmog.CollectionUnlockOnEquip` are read only when `Transmog.CollectionUnlockMode` is
missing. Their values are translated for that startup and a warning is printed asking the
administrator to update `mod_transmog_plus.conf`.

When `Transmog.CollectionUnlockMode` is present, it is authoritative. The deprecated settings
do not override or interfere with it.
