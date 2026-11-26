import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import TelegramCore
import ItemListUI
import AccountContext
import SGItemListUI

private enum AyuSection: Int32, SGItemListSection {
    case profile
    case privacy
    case visuals
    case balances
    case gifts
}

private enum AyuBoolSetting: Hashable {
    case localPremium
    case ghostMode
    case nftVisuals
    case collectibleNumbers
    case collectibleUsernames
    case collectiblePhoneNumbers
    case giftAnimations
}

private enum AyuSelector: Hashable {
    case verification
}

private enum AyuLink: Hashable {
    case increaseLevel
    case decreaseLevel
    case addStars
    case addGrams
    case setTonBalance
    case setCollectibleUsername
    case setCollectiblePhone
    case addGift
    case openTelegramGifts
    case openGallery
    case openWorkshop
    case upgradeGift(Int)
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
    weak var settingsController: ViewController?

    let arguments = SGItemListArguments<AyuBoolSetting, AyuSelector, AyuSelector, AyuLink, AnyHashable>(
        context: context,
        setBoolValue: { setting, value in
            switch setting {
            case .localPremium:
                defaults.set(value, forKey: "ayu.preferences.localPremium")
            case .ghostMode:
                defaults.set(value, forKey: "ayu.preferences.ghostMode")
            case .nftVisuals:
                defaults.set(value, forKey: "ayu.preferences.nftVisuals")
            case .collectibleNumbers:
                defaults.set(value, forKey: "ayu.preferences.collectibleNumbers")
            case .collectibleUsernames:
                defaults.set(value, forKey: "ayu.preferences.collectibleUsernames")
            case .collectiblePhoneNumbers:
                defaults.set(value, forKey: "ayu.preferences.collectiblePhoneNumbers")
            case .giftAnimations:
                defaults.set(value, forKey: "ayu.preferences.giftAnimations")
            }
            refresh.set(true)
        },
        setOneFromManyValue: { setting in
            guard setting == .verification else { return }
            let current = defaults.integer(forKey: "ayu.preferences.verificationType")
            let options = [
                ("None", 0), ("Verified (local)", 1), ("Major", 2), ("Hold", 3)
            ].map { item in
                let (title, value) = item
                return SGOneFromManyOption(title: title, isSelected: current == value, action: {
                    defaults.set(value, forKey: "ayu.preferences.verificationType")
                    refresh.set(true)
                })
            }
            selectorPresenter?(setting, options)
        },
        openDisclosureLink: { link in
            var animateGiftUpgrade = false
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
            case .setTonBalance, .setCollectibleUsername, .setCollectiblePhone:
                let title: String
                let key: String
                switch link {
                case .setTonBalance: title = "Local TON balance preview"; key = "ayu.preferences.visualTon"
                case .setCollectibleUsername: title = "Collectible username label"; key = "ayu.preferences.collectibleUsername"
                default: title = "Collectible phone label"; key = "ayu.preferences.collectiblePhone"
                }
                let alert = UIAlertController(title: title, message: "Optional local display value. This does not read or change your Telegram account or wallet.", preferredStyle: .alert)
                alert.addTextField { field in
                    field.text = defaults.string(forKey: key)
                    field.placeholder = link == .setTonBalance ? "Leave empty if unset" : "Enter a value yourself"
                    if link == .setTonBalance { field.keyboardType = .decimalPad }
                }
                alert.addAction(UIAlertAction(title: "Save preview", style: .default) { _ in
                    var value = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if link == .setTonBalance, !value.isEmpty, let amount = Double(value), amount.isFinite, amount >= 0 {
                        value = amount.formatted(.number.precision(.fractionLength(0...6)))
                    } else if link == .setTonBalance, !value.isEmpty {
                        let invalidValue = UIAlertController(title: "Invalid TON preview", message: "Enter a non-negative numeric value, or leave it empty to clear the preview.", preferredStyle: .alert)
                        invalidValue.addAction(UIAlertAction(title: "OK", style: .default))
                        settingsController?.present(invalidValue, animated: true)
                        return
                    } else if link == .setCollectibleUsername {
                        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                    }
                    if value.isEmpty { defaults.removeObject(forKey: key) }
                    else { defaults.set(value, forKey: key) }
                    refresh.set(true)
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                settingsController?.present(alert, animated: true)
            case .openTelegramGifts:
                let peerSignal = context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                let _ = (peerSignal |> deliverOnMainQueue).start(next: { peer in
                    guard let peer, let controller = context.sharedContext.makePeerInfoController(context: context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil) else {
                        return
                    }
                    settingsController?.navigationController?.pushViewController(controller, animated: true)
                })
            case .openGallery:
                let gallery = AyuGiftGalleryController()
                settingsController?.navigationController?.pushViewController(gallery, animated: true)
            case .openWorkshop:
                let workshop = AyuGiftWorkshopController()
                settingsController?.navigationController?.pushViewController(workshop, animated: true)
            case .addGift:
                var gifts = ayuGiftRecords(defaults: defaults)
                gifts.append(AyuStoredGift(id: UUID(), title: "Ayu Gift", rarity: "common", isNFT: false, nftNumber: nil, hasAnimatedFrame: false))
                saveAyuGiftRecords(gifts, defaults: defaults)
            case let .upgradeGift(giftIndex):
                var gifts = ayuGiftRecords(defaults: defaults)
                if gifts.indices.contains(giftIndex), !gifts[giftIndex].isNFT {
                    let nextNumber = defaults.integer(forKey: "ayu.gifts.nextLocalNumber") + 1
                    defaults.set(nextNumber, forKey: "ayu.gifts.nextLocalNumber")
                    gifts[giftIndex].isNFT = true
                    gifts[giftIndex].nftNumber = nextNumber
                    gifts[giftIndex].hasAnimatedFrame = true
                    gifts[giftIndex].rarity = gifts[giftIndex].rarity == "legendary" ? "legendary" : "epic"
                    saveAyuGiftRecords(gifts, defaults: defaults)
                    animateGiftUpgrade = defaults.object(forKey: "ayu.preferences.giftAnimations") == nil || defaults.bool(forKey: "ayu.preferences.giftAnimations")
                }
            case .reset:
                defaults.set(false, forKey: "ayu.preferences.localPremium")
                defaults.set(0, forKey: "ayu.preferences.verificationType")
                defaults.set(80, forKey: "ayu.preferences.profileLevel")
                defaults.set(false, forKey: "ayu.preferences.ghostMode")
                defaults.set(0, forKey: "ayu.preferences.visualStars")
                defaults.set(0.0, forKey: "ayu.preferences.visualGrams")
                ["ayu.preferences.nftVisuals", "ayu.preferences.collectibleNumbers", "ayu.preferences.collectibleUsernames", "ayu.preferences.collectiblePhoneNumbers", "ayu.preferences.giftAnimations", "ayu.preferences.visualTon", "ayu.preferences.collectibleUsername", "ayu.preferences.collectiblePhone"].forEach(defaults.removeObject(forKey:))
                defaults.removeObject(forKey: "ayu.gifts.localCollection")
                defaults.removeObject(forKey: "ayu.gifts.nextLocalNumber")
            }
            if animateGiftUpgrade, let view = settingsController?.view {
                UIView.transition(with: view, duration: 0.45, options: [.transitionFlipFromTop, .allowAnimatedContent]) {
                    refresh.set(true)
                }
            } else {
                refresh.set(true)
            }
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

        entries.append(.header(id: id.count, section: .visuals, text: "Visual", badge: nil))
        entries.append(.toggle(id: id.count, section: .visuals, settingName: .nftVisuals, value: defaults.object(forKey: "ayu.preferences.nftVisuals") == nil ? true : defaults.bool(forKey: "ayu.preferences.nftVisuals"), text: "NFT visual style", enabled: true))
        entries.append(.toggle(id: id.count, section: .visuals, settingName: .collectibleNumbers, value: defaults.object(forKey: "ayu.preferences.collectibleNumbers") == nil ? true : defaults.bool(forKey: "ayu.preferences.collectibleNumbers"), text: "Collectible numbers (local samples)", enabled: true))
        entries.append(.toggle(id: id.count, section: .visuals, settingName: .collectibleUsernames, value: defaults.bool(forKey: "ayu.preferences.collectibleUsernames"), text: "Collectible username label", enabled: true))
        entries.append(.disclosure(id: id.count, section: .visuals, link: .setCollectibleUsername, text: "Set local username label · \(defaults.string(forKey: "ayu.preferences.collectibleUsername") ?? "unset")"))
        entries.append(.toggle(id: id.count, section: .visuals, settingName: .collectiblePhoneNumbers, value: defaults.bool(forKey: "ayu.preferences.collectiblePhoneNumbers"), text: "Collectible phone label", enabled: true))
        entries.append(.disclosure(id: id.count, section: .visuals, link: .setCollectiblePhone, text: "Set local phone label · \(defaults.string(forKey: "ayu.preferences.collectiblePhone") ?? "unset")"))
        entries.append(.toggle(id: id.count, section: .visuals, settingName: .giftAnimations, value: defaults.object(forKey: "ayu.preferences.giftAnimations") == nil ? true : defaults.bool(forKey: "ayu.preferences.giftAnimations"), text: "Gift upgrade and merge animations", enabled: true))
        entries.append(.notice(id: id.count, section: .visuals, text: "All labels and effects here are local previews. No collectible username or phone number is fetched or assigned."))

        entries.append(.header(id: id.count, section: .balances, text: "Local balance preview", badge: nil))
        let ton = defaults.string(forKey: "ayu.preferences.visualTon") ?? "unset"
        entries.append(.notice(id: id.count, section: .balances, text: "Stars: \(stars)   •   Grams: \(String(format: "%.4g", grams))   •   TON preview: \(ton)"))
        entries.append(.disclosure(id: id.count, section: .balances, link: .addStars, text: "Add 100 local Stars"))
        entries.append(.disclosure(id: id.count, section: .balances, link: .addGrams, text: "Add 10 local Grams"))
        entries.append(.disclosure(id: id.count, section: .balances, link: .setTonBalance, text: "Set local TON balance preview"))
        entries.append(.notice(id: id.count, section: .balances, text: "Preview values only; they do not affect wallet, payments, or server balances."))

        entries.append(.header(id: id.count, section: .gifts, text: "Local gift collection", badge: nil))
        entries.append(.notice(id: id.count, section: .gifts, text: "Gifts: \(gifts.count)   •   Local collectibles: \(localNFTCount)"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .openTelegramGifts, text: "Open Telegram Gifts · real collection and actions"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .openGallery, text: "Open local collectible preview gallery"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .openWorkshop, text: "Gift Workshop · workflow preview"))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .addGift, text: "Add sample gift"))
        for (giftIndex, gift) in gifts.enumerated() {
            let status = gift.isNFT
                ? "Local collectible #\(gift.nftNumber ?? 0) · \(gift.rarity.capitalized) · animated frame"
                : "\(gift.rarity.capitalized) · ordinary local gift"
            entries.append(.notice(id: id.count, section: .gifts, text: "\(gift.title) — \(status)"))
            if !gift.isNFT {
                entries.append(.disclosure(id: id.count, section: .gifts, link: .upgradeGift(giftIndex), text: "Upgrade sample “\(gift.title)” to local collectible"))
            }
        }
        if gifts.isEmpty {
            entries.append(.notice(id: id.count, section: .gifts, text: "Add a sample gift to try the local collectible preview."))
        }
        entries.append(.notice(id: id.count, section: .gifts, text: "Upgrade assigns a local collectible number and animated frame. It is a visual client-side conversion, not a blockchain mint or Telegram gift transfer."))
        entries.append(.disclosure(id: id.count, section: .gifts, link: .reset, text: "Reset all AyuTweaks data"))

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AyuTweaks"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: nil, initialScrollToItem: nil)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    settingsController = controller
    selectorPresenter = { [weak controller] setting, options in
        guard let controller else { return }
        sgPresentOneFromManySelector(controller: controller, setting: setting, presentationData: context.sharedContext.currentPresentationData.with { $0 }, options: options)
    }
    return controller
}
