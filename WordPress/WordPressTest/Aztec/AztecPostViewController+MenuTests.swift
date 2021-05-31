@testable import WordPress
import Aztec
import WordPressEditor
import Nimble
import UIKit
import XCTest

class AztecPostViewController_MenuTests: XCTestCase {

    class Mock: AztecPostViewController {
        var callback: ((UIAlertController) -> Void)?
        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            print(viewControllerToPresent)
            if let alertController = viewControllerToPresent as? UIAlertController {
                callback?(alertController)
            }
        }
    }

    private var aztecPostViewController: Mock!
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        contextManager = nil
        context = nil
    }

    private func blogPost(with content: String?) -> Post {
        let blog = ModelTestHelper.insertSelfHostedBlog(context: context)
        let post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as! Post
        post.blog = blog
        post.content = content
        let settings = GutenbergSettings(database: EphemeralKeyValueDatabase())
        settings.setGutenbergEnabled(true, for: blog)
        return post
    }

    func testMenuWillShowSwitchToBlockEditor() throws {
        // Arrange
        let post = blogPost(with: "")

        aztecPostViewController = Mock(post: post, replaceEditor: { (_, _) in })
        let exp = expectation(description: "Wait for alert controller")
        aztecPostViewController.callback = { alertController in

            // Assert
            expect(alertController.actions.contains(where: { action in
                action.title == "Switch to block editor"
            })).to(beTrue())

            exp.fulfill()
        }

        // Act
        aztecPostViewController.moreWasPressed()

        wait(for: [exp], timeout: 2.0)
    }
}
