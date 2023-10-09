import XCTest

@testable import WordPress

final class ReaderPostCellActionsTests: CoreDataTestCase {

    // MARK: - Constants

    private enum Constants {
        static let blockAndReportActions = ["Block this site", "Block this user", "Report this post", "Report this user"]
    }

    // MARK: - Tests

    /// Tests the block and report actions are visible for posts in the Discover feed.
    func testBlockAndReportActionsVisibleInDiscoverFeed() throws {
        // Given
        let viewController = MockViewController()
        let topic = makeDiscoverTopic()

        // When
        self.triggerPostMenuPresentation(in: viewController, topic: topic)
        let presentedAlertController = try XCTUnwrap(viewController.presentedAlertController)
        let actualActions = presentedAlertController.actions.compactMap { $0.title }

        // Then
        let expectedActions = Constants.blockAndReportActions
        XCTAssertTrue(Set(expectedActions).isSubset(of: actualActions))
    }

    /// Tests the block and report actions are visible for posts in the Following feed.
    func testBlockAndReportActionsVisibleInFollowingFeed() throws {
        // Given
        let viewController = MockViewController()
        let topic = makeFollowingTopic()

        // When
        self.triggerPostMenuPresentation(in: viewController, topic: topic)
        let presentedAlertController = try XCTUnwrap(viewController.presentedAlertController)
        let actualActions = presentedAlertController.actions.compactMap { $0.title }

        // Then
        let expectedActions = Constants.blockAndReportActions
        XCTAssertTrue(Set(expectedActions).isSubset(of: actualActions))
    }

    // MARK: - Helpers

    /// Triggers the post menu presentation logic.
    private func triggerPostMenuPresentation(in viewController: UIViewController, topic: ReaderAbstractTopic) {
        let post = makePost()
        let cell = makeCell()
        let followingTopic = makeFollowingTopic()
        let actionsHandler = makePostCellActions(topic: followingTopic, origin: viewController)
        actionsHandler.readerCell(cell, menuActionForProvider: post, fromView: cell)
    }

    private func makePostCellActions(topic: ReaderAbstractTopic, origin: UIViewController) -> ReaderPostCellActions {
        let actions = ReaderPostCellActions(context: mainContext, origin: origin, topic: topic, visibleConfirmation: false)
        actions.isLoggedIn = true
        return actions
    }

    private func makeFollowingTopic() -> ReaderAbstractTopic {
        let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderDefaultTopic.entityName(), into: mainContext) as! ReaderDefaultTopic
        topic.path = "https://wordpress.com/read/following"
        return topic
    }

    private func makeDiscoverTopic() -> ReaderAbstractTopic {
        let topic = NSEntityDescription.insertNewObject(forEntityName: ReaderDefaultTopic.entityName(), into: mainContext) as! ReaderDefaultTopic
        topic.path = "https://wordpress.com/read/sites/53424024/posts"
        return topic
    }

    private func makeCell() -> OldReaderPostCardCell {
        return Bundle.loadRootViewFromNib(type: OldReaderPostCardCell.self)!
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
