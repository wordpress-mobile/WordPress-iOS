import Foundation
import Testing

@testable import WordPressMediaLibrary

struct MediaGridColumnCountTests {
    private func columns(_ width: CGFloat) -> Int {
        MediaGridLayout.columnCount(forWidth: width)
    }

    @Test(arguments: [320, 375, 402, 440] as [CGFloat])
    func portraitIPhonesKeepFourColumns(width: CGFloat) {
        #expect(columns(width) == 4)
    }

    @Test(arguments: [466, 499] as [CGFloat])
    func iPadPortraitSplitViewKeepsFourColumns(width: CGFloat) {
        #expect(columns(width) == 4)
    }

    @Test func widerLayoutsAddColumnsInsteadOfGrowingTiles() {
        #expect(columns(750) == 7) // iPhone landscape, inside the safe area
        #expect(columns(860) == 8) // iPad landscape split view
        #expect(columns(1180) == 11) // iPad landscape, full width
    }

    @Test func zeroWidthFallsBackToMinimum() {
        #expect(columns(0) == 4)
    }
}
