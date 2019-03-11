import XCTest
import UIKit
import CoreData
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

    enum PostContent {
        static let classic = """
        Text <strong>bold</strong> <em>italic</em>
        """

        static let gutenberg = """
        <!-- wp:image {"id":-181231834} -->
        <figure class="wp-block-image"><img src="file://tmp/EC856C66-7B79-4631-9503-2FB9FF0E6C66.jpg" alt="" class="wp-image--181231834"/></figure>
        <!-- /wp:image -->
        """
    }

    private var rootWindow: UIWindow!
    private var viewController: MockUIViewController!
    private var mockUserDefaults: MockUserDefaults!
    private var context: NSManagedObjectContext!

    override func setUp() {
        viewController = MockUIViewController()
        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = viewController
        context = setUpInMemoryManagedObjectContext()
        mockUserDefaults = MockUserDefaults()
    }

    override func tearDown() {
        rootWindow.rootViewController = nil
        rootWindow.isHidden = true
        rootWindow = nil
        viewController = nil
        context = nil
        mockUserDefaults = nil
    }

    func testShowInformativeDialogWithUserDefaultsFlagWithGutenbergContent() {
        let post = insertPost()
        post.content = PostContent.gutenberg
        mockUserDefaults.set(true, forKey: GutenbergViewController.InfoDialog.key)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults,
                                                                 showing: post,
                                                                 on: viewController,
                                                                 animated: false)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithGutenbergContent() {
        let post = insertPost()
        post.content = PostContent.gutenberg
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults,
                                                                 showing: post,
                                                                 on: viewController,
                                                                 animated: false)
        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNotNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithEmptyContent() {
        let post = insertPost()
        post.content = ""
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults,
                                                                 showing: post,
                                                                 on: viewController,
                                                                 animated: false)
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithClassicContent() {
        let post = insertPost()
        post.content = PostContent.classic
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults,
                                                                 showing: post,
                                                                 on: viewController,
                                                                 animated: false)
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
    }

    private func insertPost() -> AbstractPost {
        return NSEntityDescription.insertNewObject(forEntityName: "Post", into: context) as! AbstractPost
    }

    private func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }
}
