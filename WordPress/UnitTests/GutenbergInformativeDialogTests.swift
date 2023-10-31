import XCTest
import UIKit
@testable import WordPress

fileprivate class MockUIViewController: UIViewController, UIViewControllerTransitioningDelegate {
    @objc func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class GutenbergInformativeDialogTests: XCTestCase {
    private var rootWindow: UIWindow!
    private var viewController: MockUIViewController!

    override func setUp() {
        viewController = MockUIViewController()
        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = viewController
    }

    override func tearDown() {
        rootWindow.rootViewController = nil
        rootWindow.isHidden = true
        rootWindow = nil
        viewController = nil
    }

    func testShowInformativeDialog() {
        showInformativeDialog()
        XCTAssertNotNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    private func showInformativeDialog() {
        GutenbergViewController.showInformativeDialog(
            on: viewController,
            message: GutenbergViewController.InfoDialog.postMessage,
            animated: false
        )
    }
}
