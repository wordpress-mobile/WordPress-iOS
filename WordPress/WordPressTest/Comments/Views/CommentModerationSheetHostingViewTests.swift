import XCTest

@testable import WordPress

final class CommentModerationSheetHostingViewTests: CoreDataTestCase {

    enum Constants {
        static let viewFrame = CGRect(x: 0, y: 0, width: 375, height: 667)
        static let touchPoint = CGPoint(x: 187.5, y: 110.0)
    }

    private var viewController: CommentDetailViewController!

    override func setUp() {
        let viewController = CommentDetailViewController(
            comment: .init(context: contextManager.mainContext),
            isLastInList: true,
            managedObjectContext: contextManager.mainContext
        )
        viewController.loadViewIfNeeded()
        viewController.view.frame = Constants.viewFrame
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        self.viewController = viewController
    }

    override func tearDown() {
        self.viewController = nil
    }

    /// Tests that the CommentModerationSheetHostingView exists and is correctly framed within the view controller.
    func testModerationViewExists() throws {
        let moderationView = try XCTUnwrap(viewController.view.subviews.last as? CommentModerationSheetHostingView)
        XCTAssertEqual(moderationView.frame, viewController.view.bounds)
    }

    /// Tests that touch events pass through to the UITableView correctly.
    func testTouchPassesThroughToTableView() throws {
        // Given
        let tableView = try XCTUnwrap(viewController.view.subviews.first as? UITableView)
        let moderationView = try XCTUnwrap(viewController.view.subviews.last as? CommentModerationSheetHostingView)
        let expectedView = try XCTUnwrap(tableView.hitTest(Constants.touchPoint, with: nil))

        // When
        let hitView = try XCTUnwrap(moderationView.hitTest(Constants.touchPoint, with: nil))

        // Then
        XCTAssertEqual(hitView, expectedView)
    }
}
