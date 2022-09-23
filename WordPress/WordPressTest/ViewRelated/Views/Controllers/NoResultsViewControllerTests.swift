import XCTest
@testable import WordPress

class NoResultsViewControllerTests: XCTestCase {

    private enum Constants {
        static let shortText = "This is a text"
        static let longText = """
        This is a long Text. This is a long Text. This is a long Text. This is a long Text. This is a long Text.
        This is a long Text. This is a long Text. This is a long Text. This is a long Text. This is a long Text.
        This is a long Text. This is a long Text. This is a long Text. This is a long Text. This is a long Text.
        """
        static let iPhoneSeSize = CGSize(width: 320, height: 568)
        static let iPadProSize = CGSize(width: 1024, height: 1366)
        static let resultViewMaxWidth: CGFloat = 360
    }

    private var resultViewController: NoResultsViewController!
    private var parentViewController: UIViewController!

    override func setUpWithError() throws {
        self.resultViewController = NoResultsViewController.controller()
        self.parentViewController = UIViewController()
    }

    override func tearDownWithError() throws {
        self.resultViewController = nil
        self.parentViewController = nil
    }

    func testTitleLabelWidthForLongTextInSmallScreen() {
        // Given
        let parentViewSize = Constants.iPhoneSeSize
        let title = Constants.longText

        // When
        parentViewController.view.frame = CGRect(origin: .zero, size: parentViewSize)
        resultViewController.configure(title: title)
        addResultViewControllerToParent()

        // Then
        XCTAssertEqual(resultViewController.titleLabel.text, title)
        XCTAssertTrue(resultViewController.titleLabel.frame.width < parentViewSize.width)
    }

    func testTitleLabelWidthForLongTextInLargeScreen() {
        // Given
        let parentViewSize = Constants.iPadProSize
        let title = Constants.longText

        // When
        parentViewController.view.frame = CGRect(origin: .zero, size: parentViewSize)
        resultViewController.configure(title: title)
        addResultViewControllerToParent()

        // Then
        XCTAssertEqual(resultViewController.titleLabel.text, title)
        XCTAssertTrue(resultViewController.titleLabel.frame.width < parentViewSize.width)
        XCTAssertTrue(resultViewController.titleLabel.frame.width < Constants.resultViewMaxWidth)
    }

    func testSubtitleLabelWidthForLongTextInSmallScreen() {
        // Given
        let parentViewSize = Constants.iPhoneSeSize
        let subtitle = Constants.longText

        // When
        parentViewController.view.frame = CGRect(origin: .zero, size: parentViewSize)
        resultViewController.configure(title: Constants.shortText, subtitle: subtitle)
        addResultViewControllerToParent()

        // Then
        XCTAssertEqual(resultViewController.subtitleTextView.text, subtitle)
        XCTAssertTrue(resultViewController.subtitleTextView.frame.width < parentViewSize.width)
    }

    func testSubtitleLabelWidthForLongTextInLargeScreen() {
        // Given
        let parentViewSize = Constants.iPadProSize
        let subtitle = Constants.longText

        // When
        parentViewController.view.frame = CGRect(origin: .zero, size: parentViewSize)
        resultViewController.configure(title: Constants.shortText, subtitle: subtitle)
        addResultViewControllerToParent()

        // Then
        XCTAssertEqual(resultViewController.subtitleTextView.text, subtitle)
        XCTAssertTrue(resultViewController.subtitleTextView.frame.width < parentViewSize.width)
        XCTAssertTrue(resultViewController.subtitleTextView.frame.width < Constants.resultViewMaxWidth)
    }

}

private extension NoResultsViewControllerTests {
    func addResultViewControllerToParent() {
        parentViewController.view.addSubview(resultViewController.view)
        resultViewController.view.frame = parentViewController.view.bounds
        resultViewController.didMove(toParent: parentViewController)
    }
}
