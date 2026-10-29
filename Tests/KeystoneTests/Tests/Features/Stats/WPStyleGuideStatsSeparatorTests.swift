import Testing
import UIKit
import WordPressShared
@testable import WordPress

@MainActor
struct WPStyleGuideStatsSeparatorTests {

    @Test func separatorStaysOnePixelWhenTheDisplayScaleChanges() {
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 10).isActive = true

        // Cells configure their separators again every time they're reused.
        WPStyleGuide.Stats.configureViewAsSeparator(separator)
        WPStyleGuide.Stats.configureViewAsSeparator(separator)

        separator.traitOverrides.displayScale = 1
        separator.updateTraitsIfNeeded()
        #expect(activeHeights(of: separator) == [1])

        separator.traitOverrides.displayScale = 2
        separator.updateTraitsIfNeeded()
        #expect(activeHeights(of: separator) == [0.5])
    }

    private func activeHeights(of view: UIView) -> [CGFloat] {
        view.constraints
            .filter { $0.firstAttribute == .height && $0.isActive }
            .map(\.constant)
    }
}
