import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {
    var readerNavigationMenuButton: XCUIElement { app.buttons["reader-navigation-button"] }
    var backButton: XCUIElement { app.buttons["Back"] }
    var dismissButton: XCUIElement { app.buttons["Dismiss"] }
    var firstPostLikeButton: XCUIElement { app.buttons["reader-like-button"].firstMatch }
    var followButton: XCUIElement { app.buttons["Follow"] }
    var followingButton: XCUIElement { app.buttons["Following"] }
    var subscriptionsMenuButton: XCUIElement { app.buttons["Subscriptions"] }
    var likesTabButton: XCUIElement { app.buttons["Likes"] }
    var noResultsView: XCUIElement { app.staticTexts["no-results-label-stack-view"].firstMatch }
    var readerButton: XCUIElement { app.buttons["Reader"] }
    var readerTable: XCUIElement { app.tables["reader_table_view"] }
    var moreButton: XCUIElement {  app.buttons["More"] }
    var savePostButton: XCUIElement { app.buttons["Save"] }
    var savedButton: XCUIElement { app.buttons["Saved"] }
    var tagCellButton: XCUIElement { app.cells["topics-card-cell-button"] }
    var visitButton: XCUIElement { app.buttons["Visit"] }
    var ghostLoading: XCUIElement { app.tables["Reader Ghost Loading"] }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.tables["reader_table_view"].firstMatch
        }
    }

    public func openLastPost() throws -> ReaderScreen {
        try getLastPost().tap()
        return self
    }

    public func openLastPostInSafari() throws -> ReaderScreen {
        try getLastPost().buttons["More"].tap()
        visitButton.tap()
        return self
    }

    public func openLastPostComments() throws -> CommentsScreen {
        let commentButton = try getLastPost().buttons["Comment"]
        guard commentButton.waitForIsHittable() else {
            throw UIElementNotFoundError(message: "ReaderScreen.Post: Comments button not loaded")
        }
        commentButton.tap()
        return try CommentsScreen()
    }

    @discardableResult
    public func getLastPost() throws -> XCUIElement {
        guard let post = app.cells.lastMatch else {
            throw UIElementNotFoundError(message: "ReaderScreen: No posts loaded")
        }
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

    @discardableResult
    public func verifyPostContentEquals(_ expected: String, file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(postContentEquals(expected), file: file, line: line)
        return self
    }

    public func dismissPost() {
        if dismissButton.isHittable { dismissButton.tap() }
        if backButton.isHittable { backButton.tap() }
    }

    public func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func selectTag() -> Self {
        tagCellButton.firstMatch.tap()

        return self
    }

    public func verifyTagLoaded(file: StaticString = #file, line: UInt = #line) -> Self {
        if XCTestCase.isPhone {
            XCTAssertTrue(readerButton.waitForExistence(timeout: 10), file: file, line: line)
        }
        XCTAssertTrue(followButton.waitForExistence(timeout: 10), file: file, line: line)
        return self
    }

    public func followTag() -> Self {
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
            if XCTestCase.isPad {
                return app.staticTexts["reader_sidebar_\(rawValue)"].firstMatch
            } else {
                return app.buttons[buttonIdentifier].firstMatch
            }
        }
    }

    private func openNavigationMenu() {
        if XCTestCase.isPad {
            // In some scenarios, the sidebar will already be on screen.
            if !app.collectionViews["reader_sidebar"].firstMatch.isHittable {
                app.buttons["ToggleSidebar"].tap()
            }
        } else {
            readerNavigationMenuButton.tap()
        }
    }

    private func closeNavigationMenu() {
        // TODO: this should not be needed, but the code that hides the
        // sidebar appears to be a bit flaky when animations are off
        if XCTestCase.isPad, !readerTable.isHittable {
            app.swipeLeft()
        }
    }

    public func switchToStream(_ stream: ReaderStream) -> Self {
        openNavigationMenu()
        stream.menuButton(app).tap()
        closeNavigationMenu()
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
    public func verifyTagFollowed(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(followingButton.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertTrue(followingButton.isSelected, file: file, line: line)

        return self
    }

    public func saveFirstPost() throws -> (ReaderScreen, String) {
        XCTAssertTrue(readerTable.isHittable)
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
