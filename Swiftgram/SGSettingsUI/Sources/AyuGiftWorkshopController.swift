import Foundation
import UIKit

/// Visual prototype of Telegram collectible-gift workflows.
/// Actions are deliberately local: no Stars payments, transfers, marketplace listings or TON exports are submitted.
public final class AyuGiftWorkshopController: UIViewController {
    private let defaults = UserDefaults.standard
    private let stack = UIStackView()
    private let scroll = UIScrollView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gift Workshop"
        view.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.065, alpha: 1)
        navigationItem.largeTitleDisplayMode = .never
        buildLayout()
        buildSections()
    }

    private func buildLayout() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func buildSections() {
        let intro = UILabel()
        intro.text = "Collectibles"
        intro.font = .systemFont(ofSize: 30, weight: .bold)
        intro.textColor = .white
        stack.addArrangedSubview(intro)

        let subtitle = UILabel()
        subtitle.text = "Upgrade gifts, reveal rare attributes, craft collections and manage collectible previews."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)

        addSection(
            title: "Upgrade to collectible",
            description: "Telegram selects a random model, pattern and backdrop. The preview can show possible attributes and the current Stars price before confirmation.",
            symbol: "sparkles.rectangle.stack.fill",
            tint: UIColor(red: 0.78, green: 0.57, blue: 0.19, alpha: 1),
            buttonTitle: "Open upgrade preview",
            action: #selector(showUpgradePreview)
        )
        addSection(
            title: "Craft collectibles",
            description: "Play a local merge animation with sample collectibles. No real gifts are selected, consumed or crafted.",
            symbol: "wand.and.stars",
            tint: UIColor(red: 0.24, green: 0.68, blue: 0.53, alpha: 1),
            buttonTitle: "Play local merge animation",
            action: #selector(playCraftAnimation)
        )
        addSection(
            title: "Gift marketplace",
            description: "Preview a sale listing in Stars or TON, unlist an item, browse by model, backdrop and symbol, and inspect purchase offers.",
            symbol: "tag.fill",
            tint: UIColor(red: 0.31, green: 0.55, blue: 0.91, alpha: 1),
            buttonTitle: "Manage sale preview",
            action: #selector(showMarketplace)
        )
        addSection(
            title: "Transfer collectible",
            description: "Transfer to another Telegram user. Telegram may require a Stars fee or a waiting period before the gift can be transferred.",
            symbol: "arrowshape.turn.up.right.fill",
            tint: UIColor(red: 0.62, green: 0.47, blue: 0.83, alpha: 1),
            buttonTitle: "Open transfer preview",
            action: #selector(showTransfer)
        )
        addSection(
            title: "TON blockchain export",
            description: "Telegram provides a withdrawal URL for eligible collectibles. Export requires the account's 2-step verification and may be time-locked.",
            symbol: "link",
            tint: UIColor(red: 0.18, green: 0.65, blue: 0.72, alpha: 1),
            buttonTitle: "Open TON export preview",
            action: #selector(showTonExport)
        )
        let note = UILabel()
        note.text = "Prototype mode: this screen demonstrates the official Telegram workflow. No payment, ownership change, marketplace listing or blockchain transaction is performed."
        note.font = .systemFont(ofSize: 12)
        note.textColor = UIColor.white.withAlphaComponent(0.48)
        note.numberOfLines = 0
        note.textAlignment = .center
        note.layer.borderWidth = 1
        note.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        note.layer.cornerRadius = 14
        note.layer.masksToBounds = true
        note.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.addArrangedSubview(note)
    }

    private func addSection(title: String, description: String, symbol: String, tint: UIColor, buttonTitle: String, action: Selector) {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.13, alpha: 1)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        let heading = UILabel()
        heading.text = title
        heading.textColor = .white
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        let body = UILabel()
        body.text = description
        body.textColor = UIColor.white.withAlphaComponent(0.62)
        body.font = .systemFont(ofSize: 13)
        body.numberOfLines = 0
        let button = UIButton(type: .system)
        button.setTitle(buttonTitle + "  ›", for: .normal)
        button.setTitleColor(tint, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        let views: [UIView] = [icon, heading, body, button]
        views.forEach { card.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 17),
            icon.widthAnchor.constraint(equalToConstant: 25), icon.heightAnchor.constraint(equalToConstant: 25),
            heading.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 11),
            heading.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            heading.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            body.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 12),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])
        stack.addArrangedSubview(card)
    }

    @objc private func showUpgradePreview() {
        let gifts = localGifts()
        let ordinaryCount = gifts.filter { !($0["isNFT"] as? Bool ?? false) }.count
        let alert = UIAlertController(
            title: "Upgrade preview",
            message: "Eligible gifts: \(ordinaryCount) local sample(s)\n\nPossible attributes\n• Model — random collectible artwork\n• Pattern — artist-designed motif\n• Backdrop — color palette and rarity\n\nUpgrade price: live Stars quote unavailable in prototype mode. Telegram's preview endpoint supplies sample attributes and current/future prices.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Preview upgrade animation", style: .default) { [weak self] _ in
            self?.playGiftAnimation(symbol: "gift.fill", title: "Local upgrade preview")
        })
        alert.addAction(UIAlertAction(title: "Upgrade requires Telegram payment", style: .destructive) { [weak self] _ in
            self?.showNotice("Payment not submitted", message: "The real upgrade flow requires an eligible saved gift, Telegram's upgrade preview, a Stars payment form and the resulting Telegram update. This prototype does not spend Stars.")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func playCraftAnimation() {
        guard defaults.object(forKey: "ayu.preferences.giftAnimations") == nil || defaults.bool(forKey: "ayu.preferences.giftAnimations") else {
            showNotice("Animations are off", message: "Turn on Gift upgrade and merge animations in Settings › Visual to preview this effect.")
            return
        }
        let count = localGifts().filter { $0["isNFT"] as? Bool == true }.count
        guard count >= 2 else {
            showNotice("Add local collectibles", message: "Create at least two sample collectibles in the local gift collection to preview the merge animation. These samples are not Telegram gifts.")
            return
        }
        playGiftAnimation(symbol: "sparkles", title: "Local merge preview")
    }

    private func playGiftAnimation(symbol: String, title: String) {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        overlay.alpha = 0
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        let result = UIImageView(image: UIImage(systemName: symbol))
        result.tintColor = UIColor(red: 0.78, green: 0.57, blue: 0.19, alpha: 1)
        result.contentMode = .scaleAspectFit
        result.alpha = 0
        result.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        let sourceA = UIImageView(image: UIImage(systemName: "gift.fill"))
        let sourceB = UIImageView(image: UIImage(systemName: "gift.fill"))
        [sourceA, sourceB].forEach { $0.tintColor = .white; $0.contentMode = .scaleAspectFit }
        let content = UIStackView(arrangedSubviews: [titleLabel, result])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 20
        overlay.addSubview(content)
        overlay.addSubview(sourceA)
        overlay.addSubview(sourceB)
        view.addSubview(overlay)
        [content, result, sourceA, sourceB].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor), overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor), overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.centerXAnchor.constraint(equalTo: overlay.centerXAnchor), content.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            result.widthAnchor.constraint(equalToConstant: 90), result.heightAnchor.constraint(equalToConstant: 90),
            sourceA.centerYAnchor.constraint(equalTo: content.centerYAnchor), sourceA.trailingAnchor.constraint(equalTo: overlay.centerXAnchor, constant: -20),
            sourceB.centerYAnchor.constraint(equalTo: content.centerYAnchor), sourceB.leadingAnchor.constraint(equalTo: overlay.centerXAnchor, constant: 20),
            sourceA.widthAnchor.constraint(equalToConstant: 46), sourceA.heightAnchor.constraint(equalToConstant: 46),
            sourceB.widthAnchor.constraint(equalToConstant: 46), sourceB.heightAnchor.constraint(equalToConstant: 46)
        ])
        UIView.animate(withDuration: 0.18, animations: { overlay.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.42, delay: 0.08, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
                sourceA.transform = CGAffineTransform(translationX: 45, y: -18).scaledBy(x: 0.4, y: 0.4)
                sourceB.transform = CGAffineTransform(translationX: -45, y: 18).scaledBy(x: 0.4, y: 0.4)
                sourceA.alpha = 0
                sourceB.alpha = 0
            } completion: { _ in
                UIView.animate(withDuration: 0.48, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.4, options: [.curveEaseOut]) {
                    result.alpha = 1
                    result.transform = .identity
                } completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        UIView.animate(withDuration: 0.2, animations: { overlay.alpha = 0 }) { _ in overlay.removeFromSuperview() }
                    }
                }
            }
        }
    }

    @objc private func showMarketplace() {
        let alert = UIAlertController(title: "Marketplace preview", message: "Choose a local listing action. A real listing uses Telegram's resale price method and the gift's resale eligibility; offers and purchases are handled by Telegram's protected payment flow.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Set sale price (Stars)", style: .default) { [weak self] _ in self?.showPriceEditor(currency: "Stars") })
        alert.addAction(UIAlertAction(title: "Set sale price (TON)", style: .default) { [weak self] _ in self?.showPriceEditor(currency: "TON") })
        alert.addAction(UIAlertAction(title: "Unlist gift", style: .destructive) { [weak self] _ in
            self?.showNotice("Unlist preview", message: "The local preview is unchanged. Telegram unlists a real gift by setting its resale price to zero.")
        })
        alert.addAction(UIAlertAction(title: "Browse filters", style: .default) { [weak self] _ in
            self?.showNotice("Marketplace filters", message: "Model · Backdrop · Symbol · Price · Gift number. These match Telegram collectible resale filters.")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showPriceEditor(currency: String) {
        let editor = UIAlertController(title: "List for sale", message: "Local listing preview · \(currency)", preferredStyle: .alert)
        editor.addTextField { field in
            field.placeholder = "Price in \(currency)"
            field.keyboardType = .decimalPad
        }
        editor.addAction(UIAlertAction(title: "Preview listing", style: .default) { [weak self, weak editor] _ in
            let price = editor?.textFields?.first?.text ?? ""
            self?.showNotice("Listing preview", message: price.isEmpty ? "No price entered." : "Draft price: \(price) \(currency). Nothing has been published to Telegram.")
        })
        editor.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(editor, animated: true)
    }

    @objc private func showTransfer() {
        let alert = UIAlertController(title: "Transfer collectible", message: "A real transfer requires the recipient peer, the gift's transfer eligibility and possibly a Stars payment.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "@username" }
        alert.addAction(UIAlertAction(title: "Preview transfer", style: .default) { [weak self, weak alert] _ in
            let recipient = alert?.textFields?.first?.text ?? ""
            self?.showNotice("Transfer not sent", message: recipient.isEmpty ? "Enter a recipient to preview the transfer." : "Recipient: \(recipient)\nThis is only a draft. No gift ownership was changed.")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showTonExport() {
        showNotice("TON export", message: "Eligible collectibles can request a withdrawal URL from Telegram. The real flow requires the gift's export eligibility date and the account's 2-step verification password. No wallet connection or blockchain export is performed here.")
    }

    private func localGifts() -> [[String: Any]] {
        guard let data = defaults.data(forKey: "ayu.gifts.localCollection"),
              let records = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return records
    }

    private func showNotice(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
