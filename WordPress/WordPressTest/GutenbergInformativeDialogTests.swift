import XCTest
import UIKit
@testable import WordPress

fileprivate class MockUserDefaults: GutenbergFlagsUserDefaultsProtocol {

    private var boolDictionary: [String: Bool] = [:]

    func set(_ value: Bool, forKey defaultName: String) {
        boolDictionary[defaultName] = value
    }

    func bool(forKey defaultName: String) -> Bool {
        return boolDictionary[defaultName] ?? false
    }
}

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
        let mockUserDefaults = MockUserDefaults()
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.Const.Key.informativeDialog))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults, on: viewController, animated: false)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.Const.Key.informativeDialog))
        XCTAssertNotNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    func testShowInformativeDialogNotNecessary() {
        let mockUserDefaults = MockUserDefaults()
        mockUserDefaults.set(true, forKey: GutenbergViewController.Const.Key.informativeDialog)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.Const.Key.informativeDialog))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults, on: viewController, animated: false)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.Const.Key.informativeDialog))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
    }
}
