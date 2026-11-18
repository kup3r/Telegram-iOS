import SwiftUI

/// Reusable local-only profile decorations. Call from a profile view without changing TelegramUser.
public struct AyuProfileDecorations: View {
    @ObservedObject private var preferences = AyuPreferences.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            if preferences.isLocalPremium {
                Label("Premium · Local", systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
            }
            if preferences.verificationType != .normal {
                HStack(spacing: 3) {
                    Image(systemName: iconName)
                    Text(preferences.verificationType.title)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .accessibilityLabel("\(preferences.verificationType.title), local preview")
            }
            Text("Level \(preferences.profileLevel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var iconName: String {
        switch preferences.verificationType {
        case .normal: return "circle"
        case .official: return "checkmark.seal.fill"
        case .major: return "crown.fill"
        case .hold: return "hand.raised.fill"
        }
    }
}
