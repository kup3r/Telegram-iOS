import SwiftUI

/// Decorative card for the local Ayu gift collection; no blockchain or Telegram gift mutation.
public struct AyuGiftCollectibleCard: View {
    public let gift: AyuGift
    @State private var glow = false

    public init(gift: AyuGift) {
        self.gift = gift
    }

    private var accent: Color {
        guard gift.isNFT else { return .secondary }
        switch gift.rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    public var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: gift.isNFT
                                ? [accent.opacity(0.9), .black.opacity(0.72), accent.opacity(0.48)]
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
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(glow ? 0.95 : 0.35), accent.opacity(glow ? 0.95 : 0.55), .white.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: accent.opacity(glow ? 0.85 : 0.25), radius: glow ? 14 : 4)
                    Text("NFT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(9)
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
                if gift.isNFT {
                    Text("#\(gift.nftNumber ?? 0)  ·  \(gift.rarity.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                } else {
                    Text(gift.rarity.title + " · ordinary gift")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if gift.isNFT && gift.hasAnimatedFrame {
                    Label("Animated collectible frame", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
