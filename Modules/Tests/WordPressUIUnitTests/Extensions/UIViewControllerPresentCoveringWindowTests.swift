import Testing
import UIKit

@testable import WordPressUI

@MainActor
@Suite("presentCoveringWindow")
struct UIViewControllerPresentCoveringWindowTests {
    @Test(
        "the presentation style follows the window's size class, not the presenter's",
        arguments: [
            (UIUserInterfaceSizeClass.regular, UIUserInterfaceSizeClass.compact, UIModalPresentationStyle.fullScreen),
            (.regular, .regular, .fullScreen),
            (.compact, .compact, .pageSheet)
        ]
    )
    func presentationStyle(
        windowSizeClass: UIUserInterfaceSizeClass,
        presenterSizeClass: UIUserInterfaceSizeClass,
        expectedStyle: UIModalPresentationStyle
    ) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.traitOverrides.horizontalSizeClass = windowSizeClass
        let presenter = UIViewController()
        presenter.traitOverrides.horizontalSizeClass = presenterSizeClass
        // Add the view directly: a root view controller's view only joins a window once it's shown.
        window.addSubview(presenter.view)
        presenter.view.updateTraitsIfNeeded()
        #expect(presenter.traitCollection.horizontalSizeClass == presenterSizeClass)
        let content = UIViewController()

        let navigationController = presenter.presentCoveringWindow(content, animated: false)

        #expect(navigationController.modalPresentationStyle == expectedStyle)
        #expect(navigationController.viewControllers == [content])
        withExtendedLifetime(window) {}
    }

    @Test("a presenter that isn't in a window gets a page sheet")
    func noWindow() {
        let navigationController = UIViewController().presentCoveringWindow(UIViewController(), animated: false)

        #expect(navigationController.modalPresentationStyle == .pageSheet)
    }
}
