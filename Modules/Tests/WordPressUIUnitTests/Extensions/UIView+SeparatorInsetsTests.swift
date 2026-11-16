import Testing
import UIKit
import WordPressUI

@MainActor
struct UIViewSeparatorInsetsTests {
    @Test func withoutSideSafeAreasTheInsetsAreUnchanged() {
        let view = SafeAreaView(safeAreaInsets: .zero)

        #expect(view.separatorInsets(leading: 68) == UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0))
    }

    @Test func leftToRightAddsEachSideSafeArea() {
        let view = SafeAreaView(safeAreaInsets: UIEdgeInsets(top: 82, left: 10, bottom: 34, right: 84))

        #expect(view.separatorInsets(leading: 68, trailing: 4) == UIEdgeInsets(top: 0, left: 78, bottom: 0, right: 88))
    }

    @Test func rightToLeftSwapsTheSafeAreaSides() {
        let view = SafeAreaView(safeAreaInsets: UIEdgeInsets(top: 82, left: 10, bottom: 34, right: 84))
        view.semanticContentAttribute = .forceRightToLeft

        // The leading side is on the right, where the 84 pt inset is.
        #expect(view.separatorInsets(leading: 68, trailing: 4) == UIEdgeInsets(top: 0, left: 152, bottom: 0, right: 14))
    }
}

private final class SafeAreaView: UIView {
    private let stubbedSafeAreaInsets: UIEdgeInsets

    init(safeAreaInsets: UIEdgeInsets) {
        self.stubbedSafeAreaInsets = safeAreaInsets
        super.init(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var safeAreaInsets: UIEdgeInsets {
        stubbedSafeAreaInsets
    }
}
