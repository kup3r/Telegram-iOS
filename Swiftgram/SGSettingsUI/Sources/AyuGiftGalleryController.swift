import Foundation
import UIKit

private struct AyuGalleryGift: Codable {
    var id: UUID
    var title: String
    var rarity: String
    var isNFT: Bool
    var nftNumber: Int?
    var hasAnimatedFrame: Bool
    var isWorn: Bool?
}

private enum AyuGiftPalette {
    static func colors(for rarity: String) -> (UIColor, UIColor, UIColor) {
        switch rarity.lowercased() {
        case "legendary": return (UIColor(red: 0.62, green: 0.37, blue: 0.10, alpha: 1), UIColor(red: 0.91, green: 0.66, blue: 0.20, alpha: 1), UIColor(red: 1.0, green: 0.84, blue: 0.42, alpha: 1))
        case "epic": return (UIColor(red: 0.12, green: 0.42, blue: 0.34, alpha: 1), UIColor(red: 0.18, green: 0.66, blue: 0.52, alpha: 1), UIColor(red: 0.47, green: 0.91, blue: 0.72, alpha: 1))
        case "rare": return (UIColor(red: 0.17, green: 0.32, blue: 0.58, alpha: 1), UIColor(red: 0.28, green: 0.49, blue: 0.82, alpha: 1), UIColor(red: 0.58, green: 0.76, blue: 1, alpha: 1))
        default: return (UIColor(white: 0.30, alpha: 1), UIColor(white: 0.54, alpha: 1), UIColor(white: 0.82, alpha: 1))
        }
    }
}

private final class AyuGiftGalleryCell: UICollectionViewCell {
    static let reuseIdentifier = "AyuGiftGalleryCell"
    private let artView = UIImageView()
    private let numberLabel = UILabel()
    private let pinView = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let shineView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 19
        contentView.layer.masksToBounds = true
        artView.translatesAutoresizingMaskIntoConstraints = false
        artView.contentMode = .scaleAspectFit
        artView.tintColor = .white
        artView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 57, weight: .regular)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 13, weight: .bold)
        numberLabel.textColor = .white
        pinView.translatesAutoresizingMaskIntoConstraints = false
        pinView.tintColor = .white
        pinView.contentMode = .scaleAspectFit
        shineView.translatesAutoresizingMaskIntoConstraints = false
        shineView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        contentView.addSubview(shineView)
        contentView.addSubview(artView)
        contentView.addSubview(numberLabel)
        contentView.addSubview(pinView)
        NSLayoutConstraint.activate([
            shineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            shineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            shineView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            shineView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.36),
            artView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            artView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 5),
            artView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.66),
            artView.heightAnchor.constraint(equalTo: artView.widthAnchor),
            numberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),
            pinView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 11),
            pinView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            pinView.widthAnchor.constraint(equalToConstant: 17),
            pinView.heightAnchor.constraint(equalToConstant: 17)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ gift: AyuGalleryGift) {
        let palette = AyuGiftPalette.colors(for: gift.rarity)
        contentView.backgroundColor = palette.0
        shineView.backgroundColor = palette.1.withAlphaComponent(0.34)
        artView.image = UIImage(systemName: gift.title.localizedCaseInsensitiveContains("ring") ? "seal.fill" : "gift.fill")
        artView.tintColor = palette.2
        numberLabel.text = gift.isNFT ? "#\(gift.nftNumber ?? 0)" : "NEW"
        pinView.isHidden = !(gift.isWorn ?? false)
    }
}

public final class AyuGiftGalleryController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let defaults = UserDefaults.standard
    private var gifts: [AyuGalleryGift] = []
    private var collectionView: UICollectionView!

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Collectibles"
        view.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.065, alpha: 1)
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(reloadGifts))
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 18, left: 16, bottom: 28, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(AyuGiftGalleryCell.self, forCellWithReuseIdentifier: AyuGiftGalleryCell.reuseIdentifier)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        reloadGifts()
    }

    @objc private func reloadGifts() {
        if let data = defaults.data(forKey: "ayu.gifts.localCollection"),
           let decoded = try? JSONDecoder().decode([AyuGalleryGift].self, from: data) {
            gifts = decoded.filter { $0.isNFT }
        } else {
            gifts = []
        }
        collectionView?.reloadData()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(gifts) else { return }
        defaults.set(data, forKey: "ayu.gifts.localCollection")
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifts.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AyuGiftGalleryCell.reuseIdentifier, for: indexPath) as! AyuGiftGalleryCell
        cell.configure(gifts[indexPath.item])
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 44) / 3)
        return CGSize(width: width, height: width)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard gifts.indices.contains(indexPath.item) else { return }
        let gift = gifts[indexPath.item]
        let detail = AyuGiftDetailController(gift: gift) { [weak self] worn in
            guard let self, let index = self.gifts.firstIndex(where: { $0.id == gift.id }) else { return }
            self.gifts[index].isWorn = worn
            self.persist()
            self.collectionView.reloadItems(at: [indexPath])
        }
        navigationController?.pushViewController(detail, animated: true)
    }
}

private final class AyuGiftDetailController: UIViewController {
    private var gift: AyuGalleryGift
    private let onWearChanged: (Bool) -> Void

    init(gift: AyuGalleryGift, onWearChanged: @escaping (Bool) -> Void) {
        self.gift = gift
        self.onWearChanged = onWearChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gift"
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1)
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let palette = AyuGiftPalette.colors(for: gift.rarity)
        let hero = UIView()
        hero.backgroundColor = palette.0
        hero.layer.cornerRadius = 26
        hero.heightAnchor.constraint(equalToConstant: 330).isActive = true
        let art = UIImageView(image: UIImage(systemName: "gift.fill"))
        art.translatesAutoresizingMaskIntoConstraints = false
        art.contentMode = .scaleAspectFit
        art.tintColor = palette.2
        art.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 116, weight: .regular)
        let name = UILabel()
        name.translatesAutoresizingMaskIntoConstraints = false
        name.text = gift.isNFT ? "\(gift.title) #\(gift.nftNumber ?? 0)" : gift.title
        name.textColor = .white
        name.font = .systemFont(ofSize: 25, weight: .bold)
        name.textAlignment = .center
        let model = UILabel()
        model.translatesAutoresizingMaskIntoConstraints = false
        model.text = gift.isNFT ? "\(gift.rarity.capitalized) Collectible" : "Ordinary gift · local preview"
        model.textColor = UIColor.white.withAlphaComponent(0.8)
        model.textAlignment = .center
        let actions = UIStackView()
        actions.translatesAutoresizingMaskIntoConstraints = false
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8
        let transfer = actionButton("Transfer", symbol: "diamond.inset.filled")
        let wear = actionButton(gift.isWorn ?? false ? "Unwear" : "Wear", symbol: "crown.fill")
        let sell = actionButton("Sell", symbol: "tag.fill")
        [transfer, wear, sell].forEach { actions.addArrangedSubview($0) }
        wear.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let next = !(self.gift.isWorn ?? false)
            self.gift.isWorn = next
            self.onWearChanged(next)
            wear.setTitle(next ? "Unwear" : "Wear", for: .normal)
        }, for: .touchUpInside)
        [transfer, sell].forEach { button in
            button.addAction(UIAction { [weak self] _ in self?.showLocalOnlyNotice() }, for: .touchUpInside)
        }
        hero.addSubview(art); hero.addSubview(name); hero.addSubview(model); hero.addSubview(actions)
        NSLayoutConstraint.activate([
            art.centerXAnchor.constraint(equalTo: hero.centerXAnchor), art.topAnchor.constraint(equalTo: hero.topAnchor, constant: 26),
            art.widthAnchor.constraint(equalToConstant: 190), art.heightAnchor.constraint(equalToConstant: 170),
            name.topAnchor.constraint(equalTo: art.bottomAnchor, constant: 8), name.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 8), name.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -8),
            model.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 5), model.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 8), model.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -8),
            actions.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 12), actions.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -12), actions.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -16), actions.heightAnchor.constraint(equalToConstant: 58)
        ])
        stack.addArrangedSubview(hero)
        let details = UIStackView()
        details.axis = .vertical
        details.spacing = 0
        details.layer.cornerRadius = 18
        details.layer.borderWidth = 1
        details.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        details.clipsToBounds = true
        let rows = [
            ("Owner", "You · local preview"),
            ("Model", gift.isNFT ? gift.rarity.capitalized + " Collectible" : "Standard Gift"),
            ("Pattern", gift.hasAnimatedFrame ? "Animated frame" : "Classic"),
            ("Background", gift.rarity.capitalized),
            ("Availability", gift.isNFT ? "1 local collectible issued" : "Not upgraded"),
            ("Value", "Not available · local preview")
        ]
        for (index, row) in rows.enumerated() {
            let line = UIStackView()
            line.axis = .horizontal
            line.spacing = 10
            let key = UILabel()
            key.text = row.0
            key.textColor = UIColor.white.withAlphaComponent(0.68)
            key.font = .systemFont(ofSize: 15)
            key.widthAnchor.constraint(equalToConstant: 112).isActive = true
            let value = UILabel()
            value.text = row.1
            value.textColor = .white
            value.font = .systemFont(ofSize: 15, weight: .medium)
            value.numberOfLines = 0
            line.addArrangedSubview(key); line.addArrangedSubview(value)
            line.isLayoutMarginsRelativeArrangement = true
            line.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
            line.backgroundColor = index.isMultiple(of: 2) ? UIColor.white.withAlphaComponent(0.035) : .clear
            details.addArrangedSubview(line)
        }
        stack.addArrangedSubview(details)
        let note = UILabel()
        note.text = "AyuTweaks local collectible. Transfer, marketplace sale, blockchain ownership and Telegram gift actions are not connected."
        note.textColor = UIColor.white.withAlphaComponent(0.55)
        note.font = .systemFont(ofSize: 13)
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
    }

    private func actionButton(_ title: String, symbol: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .top
        config.imagePadding = 3
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.22)
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 13
        return button
    }

    private func showLocalOnlyNotice() {
        let alert = UIAlertController(title: "Local preview only", message: "This prototype does not transfer or sell Telegram gifts and does not interact with a blockchain marketplace.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
