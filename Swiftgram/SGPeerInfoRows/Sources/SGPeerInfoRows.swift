import SGSimpleSettings
import SGStrings
import CountrySelectionUI
import Foundation
import UIKit
import AccountContext
import TelegramPresentationData
import TelegramCore
import TelegramStringFormatting

func sgPeerInfoProfileItems(nearestChatParticipant: (String?, Int32?), data: PeerInfoScreenData, context: AccountContext, presentationData: PresentationData, interaction: PeerInfoInteraction, isMyProfile: Bool) -> [PeerInfoScreenItem] {
    var items: [PeerInfoScreenItem] = []
    var itemId = 0
    var idText = ""
    var isMutualContact = false

    if case let .user(user) = data.peer {
        idText = String(user.id.id._internalGetInt64Value())
        isMutualContact = user.flags.contains(.mutualContact)
    } else if case let .channel(channel) = data.peer {
        idText = "-100" + String(channel.id.id._internalGetInt64Value())
    } else if case let .legacyGroup(group) = data.peer {
        idText = String(group.id.id._internalGetInt64Value())
    }

    if SGSimpleSettings.shared.showProfileId {
        items.append(PeerInfoScreenLabeledValueItem(id: itemId, context: context, label: "\(i18n("Chat.ID", presentationData.strings.baseLanguageCode)): \(idText)", text: "", textColor: .primary, action: { node, _ in
            interaction.openSgContextMenu(node, nil, .copy(text: idText, copyTitle: i18n("Chat.ID.Copy", presentationData.strings.baseLanguageCode), copiedTitle: i18n("Chat.ID.Copied", presentationData.strings.baseLanguageCode)))
        }, longTapAction: nil, contextAction: { node, gesture, _ in
            interaction.openSgContextMenu(node, gesture, .copy(text: idText, copyTitle: i18n("Chat.ID.Copy", presentationData.strings.baseLanguageCode), copiedTitle: i18n("Chat.ID.Copied", presentationData.strings.baseLanguageCode)))
        }, requestLayout: { _ in
            interaction.requestLayout(false)
        }))
        itemId += 1
    }

    if SGSimpleSettings.shared.showDC {
        var dcId: Int? = nil
        var phoneCountryText = ""
        var dcLabel = ""
        var dcText = ""

        if let cachedData = data.cachedData as? CachedUserData, let phoneCountry = cachedData.peerStatusSettings?.phoneCountry {
            var countryName = ""
            let countriesConfiguration = context.currentCountriesConfiguration.with { $0 }
            if let country = countriesConfiguration.countries.first(where: { $0.id == phoneCountry }) {
                countryName = country.localizedName ?? country.name
            } else if phoneCountry == "FT" {
                countryName = presentationData.strings.Chat_NonContactUser_AnonymousNumber
            } else if phoneCountry == "TS" {
                countryName = "Test"
            }
            phoneCountryText = emojiFlagForISOCountryCode(phoneCountry) + " " + countryName
        }
        if let peer = data.peer, let smallProfileImage = peer.smallProfileImage, let cloudResource = smallProfileImage.resource as? CloudPeerPhotoSizeMediaResource {
            dcId = cloudResource.datacenterId
        }

        if let dcId = dcId {
            dcLabel = "dc: \(dcId)"
            if !phoneCountryText.isEmpty {
                dcText = phoneCountryText
            }
        } else if !phoneCountryText.isEmpty {
            dcLabel = "dc: ?"
            dcText = phoneCountryText
        }

        if !dcText.isEmpty || !dcLabel.isEmpty {
            items.append(PeerInfoScreenLabeledValueItem(id: itemId, context: context, label: dcLabel, text: dcText, textColor: .primary, action: { node, _ in
                interaction.openSgContextMenu(node, nil, .openURL(url: "https://core.telegram.org/api/datacenter", title: i18n("Chat.DataCenter.LearnMore", presentationData.strings.baseLanguageCode)))
            }, longTapAction: nil, contextAction: { node, gesture, _ in
                interaction.openSgContextMenu(node, gesture, .openURL(url: "https://core.telegram.org/api/datacenter", title: i18n("Chat.DataCenter.LearnMore", presentationData.strings.baseLanguageCode)))
            }, requestLayout: { _ in
                interaction.requestLayout(false)
            }))
            itemId += 1
        }
    }

    if SGSimpleSettings.shared.showCreationDate, let channelCreationTimestamp = data.channelCreationTimestamp {
        let creationDateString = stringForDate(timestamp: channelCreationTimestamp, strings: presentationData.strings)
        items.append(PeerInfoScreenLabeledValueItem(id: itemId, context: context, label: i18n("Chat.Created.Label", presentationData.strings.baseLanguageCode), text: creationDateString, textColor: .primary, action: { node, _ in
            interaction.openSgContextMenu(node, nil, .copy(text: creationDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.Created.Copied", presentationData.strings.baseLanguageCode)))
        }, longTapAction: nil, contextAction: { node, gesture, _ in
            interaction.openSgContextMenu(node, gesture, .copy(text: creationDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.Created.Copied", presentationData.strings.baseLanguageCode)))
        }, requestLayout: { _ in
            interaction.requestLayout(false)
        }))
        itemId += 1
    }

    if let invitedAt = nearestChatParticipant.1 {
        let joinedDateString = stringForDate(timestamp: invitedAt, strings: presentationData.strings)
        items.append(PeerInfoScreenLabeledValueItem(id: itemId, context: context, label: i18n("Chat.JoinedDateTitle", presentationData.strings.baseLanguageCode, nearestChatParticipant.0 ?? "chat"), text: joinedDateString, textColor: .primary, action: { node, _ in
            interaction.openSgContextMenu(node, nil, .copy(text: joinedDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.JoinedDate.Copied", presentationData.strings.baseLanguageCode)))
        }, longTapAction: nil, contextAction: { node, gesture, _ in
            interaction.openSgContextMenu(node, gesture, .copy(text: joinedDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.JoinedDate.Copied", presentationData.strings.baseLanguageCode)))
        }, requestLayout: { _ in
            interaction.requestLayout(false)
        }))
        itemId += 1
    }

    if SGSimpleSettings.shared.showRegDate {
        var regDateString = ""
        if let cachedData = data.cachedData as? CachedUserData, let registrationDate = cachedData.peerStatusSettings?.registrationDate {
            let components = registrationDate.components(separatedBy: ".")
            if components.count == 2, let first = Int32(components[0]), let second = Int32(components[1]) {
                let month = first - 1
                let year = second - 1900
                regDateString = stringForMonth(strings: presentationData.strings, month: month, ofYear: year)
            }
        }
        if let regDate = data.regDate, regDateString.isEmpty {
            let regTimestamp = Int32((regDate.from + regDate.to) / 2)
            switch context.currentAppConfiguration.with({ $0 }).sgWebSettings.global.regdateFormat {
                case "year":
                    regDateString = stringForDateWithoutDayAndMonth(date: Date(timeIntervalSince1970: Double(regTimestamp)), strings: presentationData.strings)
                case "month":
                    regDateString = stringForDateWithoutDay(date: Date(timeIntervalSince1970: Double(regTimestamp)), strings: presentationData.strings)
                default:
                    regDateString = stringForDate(timestamp: regTimestamp, strings: presentationData.strings)
            }
        }
        if !regDateString.isEmpty {
            items.append(PeerInfoScreenLabeledValueItem(id: itemId, context: context, label: i18n("Chat.RegDate", presentationData.strings.baseLanguageCode), text: regDateString, textColor: .primary, action: { node, _ in
                interaction.openSgContextMenu(node, nil, .copy(text: regDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.RegDate.Copied", presentationData.strings.baseLanguageCode)))
            }, longTapAction: nil, contextAction: { node, gesture, _ in
                interaction.openSgContextMenu(node, gesture, .copy(text: regDateString, copyTitle: presentationData.strings.Chat_Context_Date_Copy, copiedTitle: i18n("Chat.RegDate.Copied", presentationData.strings.baseLanguageCode)))
            }, requestLayout: { _ in
                interaction.requestLayout(false)
            }))
            itemId += 1
        }
    }
    if isMutualContact && !isMyProfile {
        items.append(PeerInfoScreenLabeledValueItem(id: itemId, label: i18n("MutualContact.Label", presentationData.strings.baseLanguageCode), text: "", action: nil, longTapAction: { _ in }, requestLayout: { _ in
            interaction.requestLayout(false)
        }))
    }

    if isMyProfile {
        let defaults = UserDefaults.standard
        let localPremium = defaults.bool(forKey: "ayu.preferences.localPremium")
        let verification = defaults.integer(forKey: "ayu.preferences.verificationType")
        let level = defaults.object(forKey: "ayu.preferences.profileLevel") == nil ? 80 : defaults.integer(forKey: "ayu.preferences.profileLevel")
        let ghostMode = defaults.bool(forKey: "ayu.preferences.ghostMode")
        if verification == 2 || verification == 3 {
            let organization = verification == 2 ? "Major" : "Hold"
            let organizationIcon = verification == 2 ? "👑 " : "⭐ "
            items.append(PeerInfoScreenLabeledValueItem(
                id: itemId,
                context: context,
                label: organizationIcon + "Значок организации",
                text: "Аккаунт верифицирован организацией «\(organization)»",
                textColor: .primary,
                action: nil,
                longTapAction: nil,
                contextAction: nil,
                requestLayout: { _ in interaction.requestLayout(false) }
            ))
            itemId += 1
        }
        let stars = defaults.integer(forKey: "ayu.preferences.visualStars")
        let grams = defaults.double(forKey: "ayu.preferences.visualGrams")
        let localGifts: [[String: Any]] = {
            guard let data = defaults.data(forKey: "ayu.gifts.localCollection"),
                  let records = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }
            return records
        }()

        if localPremium || verification != 0 || level != 80 || ghostMode || stars > 0 || grams > 0 || !localGifts.isEmpty {
            var details: [String] = []
            if localPremium { details.append("Premium (local)") }
            switch verification {
            case 1: details.append("Verified (local)")
            case 2: details.append("Major (local)")
            case 3: details.append("Hold (local)")
            default: break
            }
            if level != 80 { details.append("Level \(level)") }
            if ghostMode { details.append("Ghost Mode preference") }
            if stars > 0 { details.append("\(stars) local Stars") }
            if grams > 0 { details.append("\(String(format: "%.4g", grams)) local Grams") }
            if !localGifts.isEmpty { details.append("\(localGifts.count) local gifts") }

            items.append(PeerInfoScreenLabeledValueItem(
                id: itemId,
                context: context,
                label: "AyuTweaks · local preview",
                text: details.joined(separator: "  •  "),
                textColor: .primary,
                action: nil,
                longTapAction: nil,
                contextAction: nil,
                requestLayout: { _ in interaction.requestLayout(false) }
            ))
            itemId += 1
        }

        if stars > 0 || grams > 0 {
            let balanceText = "Stars: \(stars.formatted())  •  Grams: \(String(format: "%.4g", grams))"
            items.append(PeerInfoScreenLabeledValueItem(
                id: itemId,
                context: context,
                label: "Ayu · balances (local)",
                text: balanceText,
                textColor: .primary,
                action: nil,
                longTapAction: nil,
                contextAction: nil,
                requestLayout: { _ in interaction.requestLayout(false) }
            ))
            itemId += 1
        }

        for gift in localGifts.prefix(12) {
            let title = gift["title"] as? String ?? "Ayu Gift"
            let rarity = (gift["rarity"] as? String ?? "common").capitalized
            let isNFT = gift["isNFT"] as? Bool ?? false
            let number = gift["nftNumber"] as? Int
            let giftDescription = isNFT
                ? "Local collectible #\(number ?? 0)  •  \(rarity)  •  animated frame"
                : "\(rarity)  •  local gift"

            items.append(PeerInfoScreenLabeledValueItem(
                id: itemId,
                context: context,
                label: title,
                text: giftDescription,
                textColor: .primary,
                action: nil,
                longTapAction: nil,
                contextAction: nil,
                requestLayout: { _ in interaction.requestLayout(false) }
            ))
            itemId += 1
        }
    }

    return items
}

func sgPeerInfoSettingsProfileIdItems(data: PeerInfoScreenData, interaction: PeerInfoInteraction) -> [PeerInfoScreenItem] {
    guard SGSimpleSettings.shared.showProfileId else {
        return []
    }

    let idText = data.peer.map { String($0.id.id._internalGetInt64Value()) } ?? ""
    return [PeerInfoScreenActionItem(id: 100, text: "ID: \(idText)", color: .accent, action: {
        UIPasteboard.general.string = idText
        interaction.notifyTextCopied()
    })]
}

func sgPeerInfoSettingsItems(context: AccountContext, paymentsEnabled: Bool, presentationData: PresentationData, interaction: PeerInfoInteraction) -> [PeerInfoScreenItem] {
    let hasNewFeatures = {
        return false
    }
    let swiftgramLabel: PeerInfoScreenDisclosureItem.Label
    if hasNewFeatures() {
        swiftgramLabel = .titleBadge(presentationData.strings.Settings_New, presentationData.theme.list.itemAccentColor)
    } else {
        swiftgramLabel = .none
    }

    let hasNewProFeatures = {
        return false
    }
    let swiftgramProLabel: PeerInfoScreenDisclosureItem.Label
    if hasNewProFeatures() {
        swiftgramProLabel = .titleBadge(presentationData.strings.Settings_New, presentationData.theme.list.itemAccentColor)
    } else {
        swiftgramProLabel = .none
    }

    var items: [PeerInfoScreenItem] = []
    if paymentsEnabled || context.sharedContext.immediateSGStatus.status > 1 {
        items.append(PeerInfoScreenDisclosureItem(id: 0, label: swiftgramProLabel, text: "Swiftgram Pro", icon: PresentationResourcesSettings.swiftgramPro, action: {
            interaction.openSettings(.swiftgramPro)
        }))
    }
    items.append(PeerInfoScreenDisclosureItem(id: 1, label: swiftgramLabel, text: "Swiftgram", icon: PresentationResourcesSettings.swiftgram, action: {
        interaction.openSettings(.swiftgram)
    }))
    return items
}
