import Testing
import UIKit
import WordPressReader

@testable import WordPress

@MainActor
struct ReaderTopicCollectionViewCoordinatorTests {
    /// A post opened in dark mode must not keep the dark-mode border after the
    /// device switches to light mode, where it is almost invisible.
    @Test func chipBorderFollowsInterfaceStyleChanges() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
        window.overrideUserInterfaceStyle = .dark

        let collectionView = TopicsCollectionView(
            frame: window.bounds,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.coordinator?.displaySetting = .standard
        collectionView.topics = ["wordpress"]
        window.addSubview(collectionView)
        window.isHidden = false
        window.layoutIfNeeded()

        let cell = try #require(collectionView.visibleCells.first)
        #expect(cell.layer.borderColor == borderColor(for: .dark))

        window.overrideUserInterfaceStyle = .light
        window.layoutIfNeeded()

        #expect(cell.layer.borderColor == borderColor(for: .light))
    }

    private func borderColor(for style: UIUserInterfaceStyle) -> CGColor {
        ReaderDisplaySettings.standard.color.secondaryForeground
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            .cgColor
    }
}
