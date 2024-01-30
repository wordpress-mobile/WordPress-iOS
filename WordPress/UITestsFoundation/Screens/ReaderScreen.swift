import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {

    private let readerNavigationButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["reader-navigation-button"]
    }

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

    private let firstPostLikeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["reader-like-button"].firstMatch
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

    private let subscriptionsMenuButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Subscriptions"]
    }

    private let likesTabButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Likes"]
    }

    private let topicCellButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["topics-card-cell-button"]
    }

    private let noResultsViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["no-results-label-stack-view"]
    }

    private let moreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["More"]
    }

    private let savePostButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Save"]
    }

    private let ghostLoadingGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Reader Ghost Loading"]
    }

    var readerNavigationMenuButton: XCUIElement { readerNavigationButtonGetter(app) }
    var backButton: XCUIElement { backButtonGetter(app) }
    var discoverButton: XCUIElement { discoverButtonGetter(app) }
    var dismissButton: XCUIElement { dismissButtonGetter(app) }
    var firstPostLikeButton: XCUIElement { firstPostLikeButtonGetter(app) }
    var followButton: XCUIElement { followButtonGetter(app) }
    var followingButton: XCUIElement { followingButtonGetter(app) }
    var subscriptionsMenuButton: XCUIElement { subscriptionsMenuButtonGetter(app) }
    var likesTabButton: XCUIElement { likesTabButtonGetter(app) }
    var noResultsView: XCUIElement { noResultsViewGetter(app) }
    var readerButton: XCUIElement { readerButtonGetter(app) }
    var readerTable: XCUIElement { readerTableGetter(app) }
    var moreButton: XCUIElement { moreButtonGetter(app) }
    var savePostButton: XCUIElement { savePostButtonGetter(app) }
    var savedButton: XCUIElement { savedButtonGetter(app) }
    var topicCellButton: XCUIElement { topicCellButtonGetter(app) }
    var visitButton: XCUIElement { visitButtonGetter(app) }
    var ghostLoading: XCUIElement { ghostLoadingGetter(app) }

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
        let commentButton = getLastPost().buttons["Comment"]
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

    public func verifyPostContentEquals(_ expected: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(postContentEquals(expected), file: file, line: line)
    }

    public func dismissPost() {
        if dismissButton.isHittable { dismissButton.tap() }
        if backButton.isHittable { backButton.tap() }
    }

    public func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func selectTopic() -> Self {
        topicCellButton.firstMatch.tap()

        return self
    }

    public func verifyTopicLoaded(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(readerButton.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertTrue(followButton.waitForExistence(timeout: 3), file: file, line: line)

        return self
    }

    public func followTopic() -> Self {
        waitForExistenceAndTap(followButton, timeout: 3)

        return self
    }

    // MARK: Stream switching actions

    public enum ReaderStream: String {
        case discover
        case subscriptions
        case saved
        case liked

        var buttonIdentifier: String {
            "Reader Navigation Menu Item, \(rawValue.capitalized)"
        }

        func menuButton(_ app: XCUIApplication) -> XCUIElement {
            return app.buttons[buttonIdentifier].firstMatch
        }
    }

    private func openNavigationMenu() {
        readerNavigationMenuButton.tap()
    }

    public func switchToStream(_ stream: ReaderStream) -> Self {
        openNavigationMenu()

        let menuButton = stream.menuButton(app)
        guard menuButton.waitForIsHittable(timeout: 3) else {
            fatalError("ReaderScreen: Discover menu button not loaded")
        }
        menuButton.tap()

        waitForLoadingToFinish()

        return self
    }

    // wait for the ghost loading view to be removed.
    private func waitForLoadingToFinish() {
        let doesNotExistPredicate = NSPredicate(format: "exists == FALSE")
        let expectation = XCTNSPredicateExpectation(predicate: doesNotExistPredicate, object: ghostLoading)
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(result, .completed)
    }

    @discardableResult
    public func verifyTopicFollowed(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(followingButton.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertTrue(followingButton.isSelected, file: file, line: line)

        return self
    }

    public func saveFirstPost() throws -> (ReaderScreen, String) {
        XCTAssertTrue(readerTable.waitForExistence(timeout: 3))
        let postLabel = readerTable.cells.firstMatch.label
        moreButton.firstMatch.tap()
        savePostButton.firstMatch.tap()

        // An alert about saved post is displayed the first time a post is saved
        if let alert = try? FancyAlertComponent() {
            alert.acceptAlert()
        }

        return (self, postLabel)
    }

    public func likeFirstPost() -> Self {
        var tries = 0

        while !firstPostLikeButton.exists && firstPostLikeButton.label.hasPrefix(.postNotLiked) && tries < 5 {
            usleep(500000) // Wait for 0.5 seconds
            tries += 1
        }

        firstPostLikeButton.tap()
        return self
    }

    public func verifyPostLikedOnFollowingTab(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(readerTable.cells.firstMatch.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertGreaterThan(readerTable.cells.count, 1, .postNotGreaterThanOneError, file: file, line: line)
        XCTAssertTrue(firstPostLikeButton.label.hasPrefix(.postLiked), file: file, line: line)

        return self
    }

    @discardableResult
    public func verifySavedPosts(state: String, postLabel: String? = nil, file: StaticString = #file, line: UInt = #line) -> Self {
        if state == .withPosts {
            verifyNotEmptyPostList()
            XCTAssertEqual(readerTable.cells.firstMatch.label, postLabel, .postNotEqualSavedPostError, file: file, line: line)
        } else if state == .withoutPosts {
            verifyEmptyPostList()
        }

        return self
    }

    @discardableResult
    public func verifyLikedPosts(state: String, file: StaticString = #file, line: UInt = #line) -> Self {
        if state == .withPosts {
            verifyNotEmptyPostList()
            XCTAssertTrue(firstPostLikeButton.label.hasPrefix(.postLiked), file: file, line: line)
        } else if state == .withoutPosts {
            verifyEmptyPostList()
        }

        return self
    }

    private func verifyNotEmptyPostList(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(readerTable.cells.firstMatch.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(readerTable.cells.count, 1, .postNotEqualOneError, file: file, line: line)
    }

    private func verifyEmptyPostList(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(noResultsView.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(readerTable.label == .emptyListLabel, file: file, line: line)
    }
}

private extension String {
    static let emptyListLabel = "Empty list"
    static let postLiked = "Liked"
    static let postNotEqualOneError = "There should only be 1 post!"
    static let postNotEqualSavedPostError = "Post displayed does not match saved post!"
    static let postNotGreaterThanOneError = "There shouldn't only be 1 post!"
    static let postNotLiked = "Like"
    static let withoutPosts = "without posts"
    static let withPosts = "with posts"
}
