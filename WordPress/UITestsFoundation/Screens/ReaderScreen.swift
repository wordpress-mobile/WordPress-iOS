import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {

    private let discoverButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Discover"]
    }

    private let readerTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Reader"]
    }

    private let readerButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Reader"]
    }

    private let savedButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Saved"]
    }

    private let visitButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Visit"]
    }

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Back"]
    }

    private let dismissButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Dismiss"]
    }

    private let followButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Follow"]
    }

    private let followingButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Following"]
    }

    private let topicNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Topic"]
    }

    private let topicCellButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["topics-card-cell-button"]
    }

    private let noResultsViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["no-results-label-stack-view"]
    }

    private let savePostButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Save post"]
    }

    var backButton: XCUIElement { backButtonGetter(app) }
    var discoverButton: XCUIElement { discoverButtonGetter(app) }
    var dismissButton: XCUIElement { dismissButtonGetter(app) }
    var followButton: XCUIElement { followButtonGetter(app) }
    var followingButton: XCUIElement { followingButtonGetter(app) }
    var noResultsView: XCUIElement { noResultsViewGetter(app) }
    var readerButton: XCUIElement { readerButtonGetter(app) }
    var readerTable: XCUIElement { readerTableGetter(app) }
    var savePostButton: XCUIElement { savePostButtonGetter(app) }
    var savedButton: XCUIElement { savedButtonGetter(app) }
    var topicCellButton: XCUIElement { topicCellButtonGetter(app) }
    var topicNavigationBar: XCUIElement { topicNavigationBarGetter(app) }
    var visitButton: XCUIElement { visitButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                readerTableGetter,
                discoverButtonGetter
            ],
            app: app
        )
    }

    public func openLastPost() -> ReaderScreen {
        getLastPost().tap()
        return self
    }

    public func openLastPostInSafari() -> ReaderScreen {
        getLastPost().buttons["More"].tap()
        visitButton.tap()
        return self
    }

    public func openLastPostComments() throws -> CommentsScreen {
        let commentButton = getLastPost().buttons["0 comment"]
        guard commentButton.waitForIsHittable() else { fatalError("ReaderScreen.Post: Comments button not loaded") }
        commentButton.tap()
        return try CommentsScreen()
    }

    @discardableResult
    public func getLastPost() -> XCUIElement {
        guard let post = app.cells.lastMatch else { fatalError("ReaderScreen: No posts loaded") }
        scrollDownUntilElementIsFullyVisible(element: post)
        return post
    }

    private func scrollDownUntilElementIsFullyVisible(element: XCUIElement) {
        var loopCount = 0
        // Using isFullyVisibleOnScreen instead of waitForIsHittable to solve a problem on iPad where the desired post
        // was already hittable but the comments button was still not visible.
        while !element.isFullyVisibleOnScreen() && loopCount < 10 {
            loopCount += 1
            app.swipeUp(velocity: .fast)
        }
    }

    private func postContentEquals(_ expected: String) -> Bool {
        let equalsPostContent = NSPredicate(format: "label == %@", expected)
        let isPostContentEqual = app.staticTexts.element(matching: equalsPostContent).waitForIsHittable(timeout: 3)

        return isPostContentEqual
    }

    public func verifyPostContentEquals(_ expected: String) {
        XCTAssertTrue(postContentEquals(expected))
    }

    public func dismissPost() {
        if dismissButton.isHittable { dismissButton.tap() }
        if backButton.isHittable { backButton.tap() }
    }

    public func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func openDiscover() -> Self {
        discoverButton.tap()

        return self
    }

    public func selectTopic() -> Self {
        topicCellButton.firstMatch.tap()

        return self
    }

    public func openSavedPosts() -> Self {
        savedButton.tap()

        return self
    }

    public func verifyTopicLoaded() -> Self {
        XCTAssertTrue(topicNavigationBar.waitForExistence(timeout: 3))
        XCTAssertTrue(readerButton.waitForExistence(timeout: 3))
        XCTAssertTrue(followButton.waitForExistence(timeout: 3))

        return self
    }

    public func openFollowing() -> Self {
        followingButton.tap()

        return self
    }

    public func followTopic() -> Self {
        followButton.tap()

        return self
    }

    @discardableResult
    public func verifyTopicFollowed() -> Self {
        XCTAssertTrue(followingButton.waitForExistence(timeout: 3))
        XCTAssertTrue(followingButton.isSelected)

        return self
    }

    public func saveFirstPost() -> (ReaderScreen, String) {
        XCTAssertTrue(readerTable.waitForExistence(timeout: 3))
        let postLabel = readerTable.cells.firstMatch.label
        savePostButton.firstMatch.tap()

        return (self, postLabel)
    }

    @discardableResult
    public func verifySavedPosts(state: String, postLabel: String? = nil) -> Self {
        if readerTable.cells.count > 0 {
            XCTAssertEqual(readerTable.cells.firstMatch.label, postLabel, "Post displayed does not match saved post!")
            XCTAssertEqual(readerTable.cells.count, 1, "There should only be 1 post!")
            XCTAssertEqual(state, .withSavedPosts)
        } else {
            XCTAssertTrue(noResultsView.waitForExistence(timeout: 3))
            XCTAssertTrue(readerTable.label == .emptyListLabel)
            XCTAssertEqual(state, .withoutSavedPosts)
        }

        return self
    }
}

private extension String {
    static let emptyListLabel = "Empty list"
    static let withoutSavedPosts = "without posts"
    static let withSavedPosts = "with posts"
}
