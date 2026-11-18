import SwiftUI

/// Settings surface for client-only Ayu presentation options.
public struct AyuTweaksSettingsView: View {
    @ObservedObject private var preferences = AyuPreferences.shared
    @ObservedObject private var giftStore = AyuGiftStore.shared
    @State private var newGiftTitle = ""
    @State private var selectedRarity: AyuGiftRarity = .common

    public init() {}

    public var body: some View {
        Form {
            Section("Profile appearance") {
                Toggle("Local Premium preview", isOn: $preferences.isLocalPremium)
                Picker("Verification style", selection: $preferences.verificationType) {
                    ForEach(AyuVerificationType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                Stepper("Profile level: \(preferences.profileLevel)", value: $preferences.profileLevel, in: 0...1000)
            }

            Section("Privacy preference") {
                Toggle("Ghost Mode preference", isOn: $preferences.ghostMode)
                Text("This is currently a saved UI preference only. It does not change online status, read receipts, or network activity.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Local balance preview") {
                Stepper("Stars: \(preferences.visualStars)", value: $preferences.visualStars, in: 0...1_000_000)
                HStack {
                    Text("Grams")
                    Spacer()
                    TextField("0.00", value: $preferences.visualGrams, format: .number.precision(.fractionLength(0...4)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 130)
                }
                Text("These numbers affect only Ayu preview components, not payments, wallet data, or server balances.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Local gift collection") {
                HStack {
                    TextField("Gift name", text: $newGiftTitle)
                    Button("Add") {
                        giftStore.addGift(title: newGiftTitle, rarity: selectedRarity)
                        newGiftTitle = ""
                    }
                    .disabled(newGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Picker("Rarity", selection: $selectedRarity) {
                    ForEach(AyuGiftRarity.allCases) { rarity in
                        Text(rarity.title).tag(rarity)
                    }
                }
                if giftStore.gifts.isEmpty {
                    Text("No local gifts yet").foregroundStyle(.secondary)
                } else {
                    ForEach(giftStore.gifts) { gift in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(gift.title)
                                    Text(gift.isNFT ? "Local collectible #\(gift.nftNumber ?? 0)" : gift.rarity.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if gift.isNFT {
                                    Image(systemName: "sparkles").foregroundStyle(.purple)
                                } else {
                                    Button("Upgrade") {
                                        _ = giftStore.upgradeToLocalCollectible(id: gift.id)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let gift = giftStore.gifts[index]
                            giftStore.removeGift(id: gift.id)
                        }
                    }
                }
            }

            Section {
                Button("Reset Ayu settings", role: .destructive) {
                    preferences.reset()
                }
            }
        }
        .navigationTitle("AyuTweaks")
        .navigationBarTitleDisplayMode(.inline)
    }
}
