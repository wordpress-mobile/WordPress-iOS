import XCTest
@testable import WordPress

final class FeatureHighlightStoreTests: XCTestCase {
    private class MockUserDefaults: UserDefaults {
        var didDismiss = false
        var tooltipPresentCounter = 0

        override func bool(forKey defaultName: String) -> Bool {
            didDismiss
        }

        override func set(_ value: Bool, forKey defaultName: String) {
            didDismiss = value
        }

        override func integer(forKey defaultName: String) -> Int {
            tooltipPresentCounter
        }

        override func set(_ integer: Int, forKey defaultName: String) {
            tooltipPresentCounter = integer
        }
    }

    func testShouldShowTooltipReturnsTrueWhenCounterIsBelow3() {
        var sut = FeatureHighlightStore(userStore: MockUserDefaults())
        sut.didDismissTooltip = false
        sut.followConversationTooltipCounter = 2

        XCTAssert(sut.shouldShowTooltip)
    }

    func testShouldShowTooltipReturnsFalseWhenCounterIs3() {
        var sut = FeatureHighlightStore(userStore: MockUserDefaults())
        sut.didDismissTooltip = false
        sut.followConversationTooltipCounter = 3

        XCTAssertFalse(sut.shouldShowTooltip)
    }

    func testShouldShowTooltipReturnsFalseWhenCounterIsBelow3DidDismissIsTrue() {
        var sut = FeatureHighlightStore(userStore: MockUserDefaults())
        sut.didDismissTooltip = true
        sut.followConversationTooltipCounter = 0

        XCTAssertFalse(sut.shouldShowTooltip)
    }

    func testShouldShowTooltipReturnsFalseWhenCounterIsAbove3DidDismissIsTrue() {
        var sut = FeatureHighlightStore(userStore: MockUserDefaults())
        sut.didDismissTooltip = true
        sut.followConversationTooltipCounter = 7

        XCTAssertFalse(sut.shouldShowTooltip)
    }
}
