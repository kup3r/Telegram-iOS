import Foundation
import Combine

public enum AyuVerificationType: Int, CaseIterable, Identifiable {
    case normal = 0
    case official = 1
    case major = 2
    case hold = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .normal: return "None"
        case .official: return "Verified (local)"
        case .major: return "Major"
        case .hold: return "Hold"
        }
    }
}

/// Stores client-only presentation preferences. These values never modify Telegram account state.
@MainActor
public final class AyuPreferences: ObservableObject {
    public static let shared = AyuPreferences()

    private enum Key {
        static let localPremium = "ayu.preferences.localPremium"
        static let verificationType = "ayu.preferences.verificationType"
        static let profileLevel = "ayu.preferences.profileLevel"
        static let ghostMode = "ayu.preferences.ghostMode"
        static let visualStars = "ayu.preferences.visualStars"
        static let visualGrams = "ayu.preferences.visualGrams"
    }

    private let defaults: UserDefaults

    @Published public var isLocalPremium: Bool { didSet { defaults.set(isLocalPremium, forKey: Key.localPremium) } }
    @Published public var verificationType: AyuVerificationType {
        didSet { defaults.set(verificationType.rawValue, forKey: Key.verificationType) }
    }
    @Published public var profileLevel: Int {
        didSet {
            profileLevel = min(max(profileLevel, 0), 1000)
            defaults.set(profileLevel, forKey: Key.profileLevel)
        }
    }
    @Published public var ghostMode: Bool { didSet { defaults.set(ghostMode, forKey: Key.ghostMode) } }
    @Published public var visualStars: Int {
        didSet {
            visualStars = max(0, visualStars)
            defaults.set(visualStars, forKey: Key.visualStars)
        }
    }
    @Published public var visualGrams: Double {
        didSet {
            if !visualGrams.isFinite || visualGrams < 0 { visualGrams = 0 }
            defaults.set(visualGrams, forKey: Key.visualGrams)
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isLocalPremium = defaults.bool(forKey: Key.localPremium)
        self.verificationType = AyuVerificationType(rawValue: defaults.integer(forKey: Key.verificationType)) ?? .normal
        self.profileLevel = defaults.object(forKey: Key.profileLevel) == nil ? 80 : defaults.integer(forKey: Key.profileLevel)
        self.ghostMode = defaults.bool(forKey: Key.ghostMode)
        self.visualStars = defaults.integer(forKey: Key.visualStars)
        self.visualGrams = max(0, defaults.double(forKey: Key.visualGrams))
    }

    public func reset() {
        isLocalPremium = false
        verificationType = .normal
        profileLevel = 80
        ghostMode = false
        visualStars = 0
        visualGrams = 0
    }
}
