import Testing

@testable import WordPressMediaLibrary

struct MediaGridLayoutMathTests {
    @Test func fourPerRowBelowFiveHundredPoints() {
        let layout = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: false)
        #expect(layout.itemsPerRow == 4)
    }

    @Test func fivePerRowAtAndAboveFiveHundredPoints() {
        let layout = MediaGridLayoutMath(availableWidth: 500, isAspectRatioMode: false)
        #expect(layout.itemsPerRow == 5)
    }

    @Test func defaultSpacingIsTwo() {
        let layout = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: false)
        #expect(layout.spacing == 2)
    }

    @Test func aspectRatioSpacingIsEight() {
        let layout = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: true)
        #expect(layout.spacing == 8)
    }

    @Test func cellSizeRoundsDownForPhoneDefault() {
        // 390 - 2 * 3 = 384; / 4 = 96.0
        let layout = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: false)
        #expect(layout.cellSize == 96)
    }

    @Test func cellSizeRoundsDownForPhoneAspectRatio() {
        // 390 - 8 * 3 = 366; / 4 = 91.5 → rounds down to 91
        let layout = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: true)
        #expect(layout.cellSize == 91)
    }

    @Test func cellSizeRoundsDownForPad() {
        // 768 - 2 * 4 = 760; / 5 = 152
        let layout = MediaGridLayoutMath(availableWidth: 768, isAspectRatioMode: false)
        #expect(layout.cellSize == 152)
    }

    @Test func columnsCountMatchesItemsPerRow() {
        let phone = MediaGridLayoutMath(availableWidth: 390, isAspectRatioMode: false)
        let pad = MediaGridLayoutMath(availableWidth: 768, isAspectRatioMode: false)
        #expect(phone.columns.count == 4)
        #expect(pad.columns.count == 5)
    }
}
