import XCTest
import UIKit
import CoreData
@testable import WordPress

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
    private var mockUserDefaults: EphemeralKeyValueDatabase!
    private var context: NSManagedObjectContext!

    override func setUp() {
        viewController = MockUIViewController()
        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = viewController
        context = setUpInMemoryManagedObjectContext()
        mockUserDefaults = EphemeralKeyValueDatabase()
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
        showInformativeDialog(with: post)

        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
        XCTAssertFalse(GutenbergSettings(database: mockUserDefaults).isGutenbergEnabled())
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithGutenbergContent() {
        let post = insertPost()
        post.content = PostContent.gutenberg
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        showInformativeDialog(with: post)

        XCTAssertTrue(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNotNil(viewController.presentedViewController as? FancyAlertViewController)
        XCTAssertTrue(GutenbergSettings(database: mockUserDefaults).isGutenbergEnabled())
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithEmptyContent() {
        let post = insertPost()
        post.content = ""
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        showInformativeDialog(with: post)

        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
        XCTAssertFalse(GutenbergSettings(database: mockUserDefaults).isGutenbergEnabled())
    }

    func testShowInformativeDialogWithNoUserDefaultsFlagWithClassicContent() {
        let post = insertPost()
        post.content = PostContent.classic
        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        showInformativeDialog(with: post)

        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
        XCTAssertFalse(GutenbergSettings(database: mockUserDefaults).isGutenbergEnabled())
    }

    func testShowInformativeDialogWithGutenbergSetAsDefaultShouldNotShowDialog() {
        let post = insertPost()
        post.content = PostContent.gutenberg
        GutenbergSettings(database: mockUserDefaults).toggleGutenberg()

        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        showInformativeDialog(with: post)

        XCTAssertFalse(mockUserDefaults.bool(forKey: GutenbergViewController.InfoDialog.key))
        XCTAssertNil(viewController.presentedViewController as? FancyAlertViewController)
        XCTAssertTrue(GutenbergSettings(database: mockUserDefaults).isGutenbergEnabled())
    }

    private func showInformativeDialog(with post: AbstractPost) {
        GutenbergViewController.showInformativeDialogIfNecessary(using: mockUserDefaults,
                                                                 showing: post,
                                                                 on: viewController,
                                                                 animated: false)
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
