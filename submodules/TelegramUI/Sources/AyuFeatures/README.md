# AyuTweaks foundation

This directory is included automatically by `submodules/TelegramUI/BUILD` through
`glob(["Sources/**/*.swift"])`. No separate Bazel target is required for these files.

## Files

- `AyuPreferences.swift`: persistent, client-only preferences.
- `AyuTweaksSettingsView.swift`: SwiftUI settings surface.
- `AyuProfileDecorations.swift`: reusable local profile decorations.
- `AyuLocalBalanceView.swift`: local Stars / Grams preview labels.
- `AyuGiftStore.swift`: local Codable gift collection and local upgrade numbering.
- `AyuGiftCollectibleCard.swift`: decorative collectible card with a pulsing frame.

## Integration contract

The current repository's settings UI was migrated away from the old monolithic
`SettingsController.swift` / `ItemListController` path. The actual settings
entry point is owned by the current Swiftgram settings flow. Do not resurrect
the old controller or add a guessed file path. To expose this view, add a
navigation destination in that settings flow:

```swift
NavigationLink {
    AyuTweaksSettingsView()
} label: {
    Label("AyuTweaks", systemImage: "slider.horizontal.3")
}
```

The profile integration point is the profile header/content view in the
`PeerInfoUI` package. Add `AyuProfileDecorations()` to its SwiftUI/Component
content only after locating the current header composition; do not modify
`TelegramUser` or Postbox storage. Use `AyuLocalBalanceView(kind: .stars)`
and `AyuLocalBalanceView(kind: .grams)` only in UI preview surfaces.

## Deliberate boundaries

All values and gifts in this module are local presentation data. They do not
grant Telegram Premium, create official verification, alter server balances,
mint or transfer NFTs, or modify Telegram's gift records. The verification
choices are labelled as local previews. Ghost Mode is currently a stored
preference only; it does not suppress read receipts, online presence, or
network activity. Those behaviours must not be implied by this settings toggle.

## Verification still required

A full Bazel build and simulator visual inspection have not been run in this
environment. Before release, compile the Telegram target and visually verify
the settings destination, profile decorations, and collectible animation on a
simulator. Add the view's actual settings and PeerInfo entry points only after
reviewing their current host implementations.
