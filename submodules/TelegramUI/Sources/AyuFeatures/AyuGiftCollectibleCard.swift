import SwiftUI

/// Decorative card for the local Ayu gift collection; no blockchain or Telegram gift mutation.
public struct AyuGiftCollectibleCard: View {
    public let gift: AyuGift
    @State private var glow = false

    public init(gift: AyuGift) {
        self.gift = gift
    }

    public var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: gift.isNFT
                                ? [.purple.opacity(0.75), .orange.opacity(0.55)]
                                : [.secondary.opacity(0.25), .secondary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: gift.isNFT ? "gift.fill" : "gift")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.white)
                if gift.isNFT {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(glow ? 0.95 : 0.35), lineWidth: 2)
                        .shadow(color: .purple.opacity(glow ? 0.8 : 0.2), radius: glow ? 12 : 3)
                }
            }
            .frame(height: 112)
            .onAppear {
                guard gift.isNFT else { return }
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }

            VStack(spacing: 3) {
                Text(gift.title).font(.headline).lineLimit(1)
                Text(gift.isNFT ? "Local collectible #\(gift.nftNumber ?? 0)" : gift.rarity.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
