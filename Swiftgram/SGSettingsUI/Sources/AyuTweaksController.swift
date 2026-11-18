import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import AccountContext
import SGItemListUI
import SGOneFromManySelector

private enum AyuSection: Int32, SGItemListSection {
    case profile
    case privacy
    case balances
    case gifts
}

private enum AyuBoolSetting: Hashable {
    case localPremium
    case ghostMode
}

private enum AyuSelector: Hashable {
    case verification
}

private enum AyuLink: Hashable {
    case increaseLevel
    case decreaseLevel
    case addStars
    case addGrams
    case addGift
    case upgradeGift
    case reset
}

private struct AyuStoredGift: Codable {
    var id: UUID
    var title: String
    var rarity: String
    var isNFT: Bool
    var nftNumber: Int?
    var hasAnimatedFrame: Bool
}

private func ayuGiftRecords(defaults: UserDefaults) -> [AyuStoredGift] {
    guard let data = defaults.data(forKey: "ayu.gifts.localCollection"),
          let records = try? JSONDecoder().decode([AyuStoredGift].self, from: data) else {
        return []
    }
    return records
}

private func saveAyuGiftRecords(_ records: [AyuStoredGift], defaults: UserDefaults) {
    guard let data = try? JSONEncoder().encode(records) else { return }
    defaults.set(data, forKey: "ayu.gifts.localCollection")
}

/// Native Swiftgram ItemList destination for AyuTweaks. All values are client-side previews.
public func ayuTweaksController(context: AccountContext) -> ViewController {
    let defaults = UserDefaults.standard
    let refresh = ValuePromise(true, ignoreRepeated: false)
    var selectorPresenter: ((AyuSelector, [SGOneFromManyOption]) -> Void)?

    let arguments = SGItemListArguments<AyuBoolSetting, AyuSelector, AyuSelector, AyuLink, AnyHashable>(
        context: context,
        setBoolValue: { setting, value in
            switch setting {
            case .localPremium:
                defaults.set(value, forKey: "ayu.preferences.localPremium")
            case .ghostMode:
                defaults.set(value, forKey: "ayu.preferences.ghostMode")
            }
            refresh.set(true)
        },
        setOneFromManyValue: { setting in
            guard setting == .verification else { return }
            let current = defaults.integer(forKey: "ayu.preferences.verificationType")
            let options = [
                ("None", 0), ("Verified (local)", 1), ("Major", 2), ("Hold", 3)
            ].map { title, value in
                SGOneFromManyOption(title: title, isSelected: current == value, action: {
                    defaults.set(value, forKey: "ayu.preferences.verificationType")
                    refresh.set(true)
                })
            }
            selectorPresenter?(setting, options)
        },
        openDisclosureLink: { link in
            switch link {
            case .increaseLevel:
                defaults.set(min(1000, max(0, defaults.integer(forKey: "ayu.preferences.profileLevel") + 10)), forKey: "ayu.preferences.profileLevel")
            case .decreaseLevel:
                let oldValue = defaults.object(forKey: "ayu.preferences.profileLevel") == nil ? 80 : defaults.integer(forKey: "ayu.preferences.profileLevel")
                defaults.set(max(0, oldValue - 10), forKey: "ayu.preferences.profileLevel")
            case .addStars:
                defaults.set(min(1_000_000, defaults.integer(forKey: "ayu.preferences.visualStars") + 100), forKey: "ayu.preferences.visualStars")
            case .addGrams:
                defaults.set(max(0, defaults.double(forKey: "ayu.preferences.visualGrams") + 10), forKey: "ayu.preferences.visualGrams")
            case .addGift:
                var gifts = ayuGiftRecords(defaults: defaults)
                gifts.append(AyuStoredGift(id: UUID(), title: "Ayu Gift", rarity: "common", isNFT: false, nftNumber: nil, hasAnimatedFrame: false))
                saveAyuGiftRecords(gifts, defaults: defaults)
            case .upgradeGift:
                var gifts = ayuGiftRecords(defaults: defaults)
                if let index = gifts.firstIndex(where: { !$0.isNFT }) {
                    let nextNumber = defaults.integer(forKey: "ayu.gifts.nextLocalNumber") + 1
                    defaults.set(nextNumber, forKey: "ayu.gifts.nextLocalNumber")
                    gifts[index].isNFT = true
                    gifts[index].nftNumber = nextNumber
                    gifts[index].hasAnimatedFrame = true
                    gifts[index].rarity = gifts[index].rarity == "legendary" ? "legendary" : "epic"
                    saveAyuGiftRecords(gifts, defaults: defaults)
                }
            case .reset:
                defaults.set(false, forKey: "ayu.preferences.localPremium")
                defaults.set(0, forKey: "ayu.preferences.verificationType")
                defaults.set(80, forKey: "ayu.preferences.profileLevel")
                defaults.set(false, forKey: "ayu.preferences.ghostMode")
                defaults.set(0, forKey: "ayu.preferences.visualStars")
                defaults.set(0.0, forKey: "ayu.preferences.visualGrams")
                defaults.removeObject(forKey: "ayu.gifts.localCollection")
                defaults.removeObject(forKey: "ayu.gifts.nextLocalNumber")
            }
            refresh.set(true)
        }
    )

    let signal = combineLatest(refresh.get(), context.sharedContext.presentationData)
    |> map { _, presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let level = defaults.object(forKey: "ayu.preferences.profileLevel") == nil ? 80 : defaults.integer(forKey: "ayu.preferences.profileLevel")
        let verification = defaults.integer(forKey: "ayu.preferences.verificationType")
        let stars = defaults.integer(forKey: "ayu.preferences.visualStars")
        let grams = defaults.double(forKey: "ayu.preferences.visualGrams")
        let gifts = ayuGiftRecords(defaults: defaults)
        let localNFTCount = gifts.filter { $0.isNFT }.count
        let id = SGItemListCounter()
        typealias Entry = SGItemListUIEntry<AyuSection, AyuBoolSetting, AyuSelector, AyuSelector, AyuLink, AnyHashable>
        var entries: [Entry] = []
        entries.append(.header(id: id.count, section: .profile, text: "Profile appearance", badge: nil))
        entries.append(.toggle(id: id.count, section: .profile, settingName: .localPremium, value: defaults.bool(forKey: "ayu.preferences.localPremium"), text: "Local Premium preview", enabled: true))
        entries.append(.oneFromManySelector(id: id.count, section: .profile, settingName: .verification, text: "Verification style", value: ["None", "Verified (local)", "Major", "Hold"][min(max(verification, 0), 3)], enabled: true))
        entries.append(.notice(id: id.count, section: .profile, text: "Profile level: \(level) (local preview)"))
        entries.append(.disclosure(id: id.count, section: .profile, link: .increaseLevel, text: "Increase level by 10"))
        entries.append(.disclosure(id: id.count, section: .profile, link: .decreaseLevel, text: "Decrease level by 10"))

        entries.append(.header(id: id.count, section: .privacy, text: "Privacy preference", badge: nil))
        entries.append(.toggle(id: id.count, section: .privacy, settingName: .ghostMode, value: defaults.bool(forKey: "ayu.preferences.ghostMode"), text: "Ghost Mode preference", enabled: true))
        entries.append(.notice(id: id.count, section: .privacy, text: "Saved locally only. This does not change read receipts, online status, or network activity."))

        entries.append(.header(id: id.count, section: .balances, text: "Local balance preview", badge: nil))
        entries.append(.notice(id: id.count, section: .balances, text: "Stars: \(stars)   •   Grams: \(grams.formatted(.number.precision(.fractionLength(0...4))))"))
        entries.append(.disclosure(id: id.count, section: .balances, link: .addStars, text: "Add 100 local Stars"))
        entries.append(.disclosure(id: id.count, section: .balances, link: .addGrams, text: "Add 10 local Grams"))
        entries.append(.notice(id: id.count, section: .balances, text: "Preview values only; they do not affect wallet, payments, or server balances."))

        entries.append(.header(id: id.count, section: .gifts, text: "Local gift collection", badge: nil))
        entries.append(.notice(id: id.count, section: .gifts, text: "Gifts: \(gifts.count)   •   Local collectibles: \(localNFTCount)"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .addGift, text: "Add sample gift"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .upgradeGift, text: "Upgrade first available gift to local collectible"))
        entries.append(.notice(id: id.count, section: .gifts, text: "Upgrade is a visual local conversion only. It does not mint or transfer an NFT."))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .reset, text: "Reset all AyuTweaks data"))

        let controllerState = ItemListControllerState(presentationData: presentationData, title: "AyuTweaks", leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: nil)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    selectorPresenter = { [weak controller] setting, options in
        guard let controller else { return }
        sgPresentOneFromManySelector(controller: controller, setting: setting, presentationData: context.sharedContext.currentPresentationData.with { $0 }, options: options)
    }
    return controller
}
