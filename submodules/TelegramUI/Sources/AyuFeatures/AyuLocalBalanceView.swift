import SwiftUI

/// A local-only balance label. Never use this value for transactions or server requests.
public struct AyuLocalBalanceView: View {
    public enum Kind: Equatable {
        case stars
        case grams
    }

    @ObservedObject private var preferences = AyuPreferences.shared
    private let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: kind == .stars ? "star.fill" : "diamond.fill")
                .foregroundStyle(kind == .stars ? .yellow : .cyan)
            Text(value)
                .monospacedDigit()
        }
        .accessibilityLabel("\(kind == .stars ? "Local Stars preview" : "Local Grams preview"): \(value)")
    }

    private var value: String {
        switch kind {
        case .stars:
            return preferences.visualStars.formatted()
        case .grams:
            return preferences.visualGrams.formatted(.number.precision(.fractionLength(0...4)))
        }
    }
}
