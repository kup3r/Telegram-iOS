import Foundation
import Combine

public enum AyuGiftRarity: String, Codable, CaseIterable, Identifiable, Hashable {
    case common, rare, epic, legendary
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}

public struct AyuGift: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var rarity: AyuGiftRarity
    public var isNFT: Bool
    public var nftNumber: Int?
    public var hasAnimatedFrame: Bool

    public init(title: String, rarity: AyuGiftRarity = .common) {
        self.id = UUID()
        self.title = title
        self.rarity = rarity
        self.isNFT = false
        self.nftNumber = nil
        self.hasAnimatedFrame = false
    }
}

/// A local collection for UI prototyping. It does not mint, transfer, or alter Telegram gifts.
@MainActor
public final class AyuGiftStore: ObservableObject {
    public static let shared = AyuGiftStore()

    @Published public private(set) var gifts: [AyuGift] = []
    private let defaults: UserDefaults
    private let storageKey = "ayu.gifts.localCollection"
    private let counterKey = "ayu.gifts.nextLocalNumber"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AyuGift].self, from: data) {
            self.gifts = decoded
        }
    }

    public func addGift(title: String, rarity: AyuGiftRarity = .common) {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        gifts.append(AyuGift(title: normalized, rarity: rarity))
        persist()
    }

    @discardableResult
    public func upgradeToLocalCollectible(id: UUID) -> Bool {
        guard let index = gifts.firstIndex(where: { $0.id == id && !$0.isNFT }) else { return false }
        let number = defaults.integer(forKey: counterKey) + 1
        defaults.set(number, forKey: counterKey)
        gifts[index].isNFT = true
        gifts[index].nftNumber = number
        gifts[index].hasAnimatedFrame = true
        gifts[index].rarity = maxRarity(gifts[index].rarity)
        persist()
        return true
    }

    public func removeGift(id: UUID) {
        gifts.removeAll { $0.id == id }
        persist()
    }

    private func maxRarity(_ rarity: AyuGiftRarity) -> AyuGiftRarity {
        switch rarity {
        case .common, .rare: return .epic
        case .epic, .legendary: return .legendary
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(gifts) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
