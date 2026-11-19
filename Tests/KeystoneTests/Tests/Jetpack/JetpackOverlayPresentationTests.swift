import Testing
import UIKit

@testable import WordPress

@MainActor
@Suite("Jetpack overlay presentation style")
struct JetpackOverlayPresentationTests {
    /// Returns a window of the given size class whose root view controller reports `presenterSizeClass`,
    /// the way a split view column on a full-screen iPad reports compact inside a regular window.
    private func makePresenter(
        windowSizeClass: UIUserInterfaceSizeClass,
        presenterSizeClass: UIUserInterfaceSizeClass
    ) -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.horizontalSizeClass = windowSizeClass
        let presenter = UIViewController()
        presenter.traitOverrides.horizontalSizeClass = presenterSizeClass
        // Add the view directly: a root view controller's view only joins a window once it's shown.
        window.addSubview(presenter.view)
        presenter.view.updateTraitsIfNeeded()
        return (window, presenter)
    }

    @Test(
        "a full-screen overlay follows the window's size class, not the presenter's",
        arguments: [
            (UIUserInterfaceSizeClass.regular, UIUserInterfaceSizeClass.compact, UIModalPresentationStyle.formSheet),
            (.regular, .regular, .formSheet),
            (.compact, .compact, .fullScreen)
        ]
    )
    func fullScreenOverlay(
        windowSizeClass: UIUserInterfaceSizeClass,
        presenterSizeClass: UIUserInterfaceSizeClass,
        expectedStyle: UIModalPresentationStyle
    ) {
        let (window, presenter) = makePresenter(
            windowSizeClass: windowSizeClass,
            presenterSizeClass: presenterSizeClass
        )
        #expect(presenter.traitCollection.horizontalSizeClass == presenterSizeClass)
        let overlay = UINavigationController(rootViewController: UIViewController())

        JetpackFeaturesRemovalCoordinator.presentOverlay(
            navigationViewController: overlay,
            in: presenter,
            fullScreen: true
        )

        #expect(overlay.modalPresentationStyle == expectedStyle)
        withExtendedLifetime(window) {}
    }

    @Test("an overlay that isn't full screen is always a form sheet")
    func sheetOverlay() {
        let (window, presenter) = makePresenter(windowSizeClass: .compact, presenterSizeClass: .compact)
        let overlay = UINavigationController(rootViewController: UIViewController())

        JetpackFeaturesRemovalCoordinator.presentOverlay(navigationViewController: overlay, in: presenter)

        #expect(overlay.modalPresentationStyle == .formSheet)
        withExtendedLifetime(window) {}
    }
}
