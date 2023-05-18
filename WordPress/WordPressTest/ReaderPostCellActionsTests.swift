import XCTest

@testable import WordPress

final class ReaderPostCellActionsTests: CoreDataTestCase {

    // MARK: - Tests

    /// Tests the block and report actions are visible for posts in the Following feed.
    func testActionSheetContainsReportAndBlockActions() throws {
        // Given
        let viewController = MockViewController()
        let post = makePost()
        let cell = makeCell()
        let actionsHandler = makePostCellActionsWithFollowingTopic(origin: viewController)
        let expectedActions = ["Block this site", "Block this user", "Report this post", "Report this user"]

        // When
        actionsHandler.readerCell(cell, menuActionForProvider: post, fromView: cell)

        // Then
        let presentedAlertController = try XCTUnwrap(viewController.presentedAlertController)
        let actions = presentedAlertController.actions.compactMap { $0.title }
        XCTAssertTrue(Set(expectedActions).isSubset(of: actions))
    }

    // MARK: - Helpers

    private func makePostCellActionsWithFollowingTopic(origin: UIViewController) -> ReaderPostCellActions {
        let topic = makeFollowingTopic()
        let actions = ReaderPostCellActions(context: mainContext, origin: origin, topic: topic, visibleConfirmation: false)
        actions.isLoggedIn = true
        return actions
    }

    private func makeFollowingTopic() -> ReaderAbstractTopic {
        let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderDefaultTopic.entityName(), into: mainContext) as! ReaderDefaultTopic
        topic.inUse = true
        topic.following = true
        topic.path = "https://wordpress.com/read/following"
        return topic
    }

    private func makeCell() -> ReaderPostCardCell {
        return Bundle.loadRootViewFromNib(type: ReaderPostCardCell.self)!
    }

    private func makePost() -> ReaderPost {
        let builder = ReaderPostBuilder()
        let post: ReaderPost = builder.build()
        post.isWPCom = true
        return post
    }
}

// MARK: - Mocks

private class MockViewController: UIViewController {

    var presentedAlertController: UIAlertController?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.presentedAlertController = viewControllerToPresent as? UIAlertController
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
