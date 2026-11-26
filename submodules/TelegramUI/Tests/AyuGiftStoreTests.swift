import Foundation
import XCTest
import AyuGiftStoreTestSupport

@MainActor
final class AyuGiftStoreTests: XCTestCase {
    private func makeStore() -> (AyuGiftStore, UserDefaults, String) {
        let suite = "AyuGiftStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (AyuGiftStore(defaults: defaults), defaults, suite)
    }

    func testUpgradeCreatesOneLocalCollectibleAndCannotUpgradeTwice() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.addGift(title: "  Sample gift  ", rarity: .rare)
        let gift = try! XCTUnwrap(store.gifts.first)

        XCTAssertEqual(gift.title, "Sample gift")
        XCTAssertTrue(store.upgradeToLocalCollectible(id: gift.id))
        XCTAssertFalse(store.upgradeToLocalCollectible(id: gift.id))
        XCTAssertEqual(store.gifts.first?.nftNumber, 1)
        XCTAssertEqual(store.gifts.first?.rarity, .epic)
        XCTAssertTrue(store.gifts.first?.isNFT == true)
        XCTAssertTrue(store.gifts.first?.hasAnimatedFrame == true)
    }

    func testGiftCollectionPersistsAndNumbersIncreaseAcrossStoreInstances() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.addGift(title: "First")
        let first = try! XCTUnwrap(store.gifts.first)
        XCTAssertTrue(store.upgradeToLocalCollectible(id: first.id))

        let reloaded = AyuGiftStore(defaults: defaults)
        XCTAssertEqual(reloaded.gifts, store.gifts)
        reloaded.addGift(title: "Second")
        let second = try! XCTUnwrap(reloaded.gifts.last)
        XCTAssertTrue(reloaded.upgradeToLocalCollectible(id: second.id))
        XCTAssertEqual(reloaded.gifts.last?.nftNumber, 2)
    }

    func testEmptyGiftNamesAreIgnoredAndRemovingGiftPersists() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.addGift(title: " \n ")
        XCTAssertTrue(store.gifts.isEmpty)
        store.addGift(title: "Keep")
        let id = try! XCTUnwrap(store.gifts.first?.id)
        store.removeGift(id: id)

        XCTAssertTrue(store.gifts.isEmpty)
        XCTAssertTrue(AyuGiftStore(defaults: defaults).gifts.isEmpty)
    }
}
