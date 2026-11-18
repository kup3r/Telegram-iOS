# AyuTweaks local presentation foundation

The AyuTweaks feature is connected to the existing Swiftgram UI:

- `Swiftgram/SGSettingsUI/Sources/AyuTweaksController.swift` provides the native ItemList settings destination.
- `SGSettingsController.swift` exposes an **AyuTweaks** disclosure row in the existing Swiftgram settings screen.
- `SGPeerInfoRows.swift` adds a local-preview summary to the current user's profile, a separate local Stars / Grams row when balances are non-zero, and up to 12 individual local gift rows with rarity, collectible number, and animated-frame state.
- `submodules/TelegramUI/BUILD` includes the existing `SGPeerInfoRows` filegroup in the TelegramUI source set.
- The files in this directory provide the reusable SwiftUI preview components and local preferences / gift store.

## Included local controls

- Local Premium presentation toggle.
- Local verification label style: None, Verified, Major, Hold.
- Profile level adjustment.
- Ghost Mode preference toggle.
- Local Stars and Grams preview counters.
- Local gift collection with a visual upgrade to a numbered local collectible.
- Reset for local Ayu preferences and local gift data.

## Deliberate boundaries

All values and gifts are client-only presentation data. They do not grant Telegram Premium, create official verification, alter server balances, mint or transfer NFTs, or modify Telegram's gift records. Verification labels are explicitly marked as local. Ghost Mode is currently a stored preference only; it does not suppress read receipts, online presence, or network activity.

The "upgrade" action only changes a locally stored gift's visual state and assigns a local sequence number. It is not an NFT mint, blockchain transaction, or Telegram gift upgrade.

## Build / verification status

The new destination is wired into the current Swiftgram settings navigation. The self-profile row list shows Ayu preferences, local balances, and individual local gifts; these are presentation-only rows, not the Telegram wallet or server gift list. The source glob in `Swiftgram/SGSettingsUI/BUILD` includes the new controller automatically.

A full Bazel build and simulator visual inspection have not yet been run. Before release, compile the Telegram target and verify the settings navigation and self-profile row on a simulator.
