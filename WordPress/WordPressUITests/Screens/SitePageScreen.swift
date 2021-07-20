import UITestsFoundation
import XCTest


private struct ElementStringIDs {
    static let closeIcon = "Close"
    static let createBlankPageButton = "Create Blank Page"
    static let chooseALaytoutTitle = "Choose a Layout"
    static let blogButton = "Blog"
    static let titleView = "Page title. Empty"
    static let publishButton = "Publish"
    static let moreButton = "more_post_options"
    static let pageSettingsButton = "Page Settings"
    static let keepEditingButton = "Keep Editing"
    static let popUpPublishButton = "Publish"
    static let createPageButton = "Create Page"
    static let titleViewBlog = "Page title. Empty"
}

/// This screen object is for the Site Page section. In the app, it is where we can create a new Site Page from My Site view.

class SitePageScreen: BaseScreen {
    let closeIcon: XCUIElement
    let createBlankPageButton: XCUIElement
    let chooseALaytoutTitle: XCUIElement
    let blogButton: XCUIElement
    let selectedTemplate = XCUIApplication().cells.firstMatch
    let createPageButton = XCUIApplication().buttons[ElementStringIDs.createPageButton]
//    Navigation Bar
    let publishButton = XCUIApplication().buttons[ElementStringIDs.publishButton].firstMatch
    let keepEditingButton = XCUIApplication().buttons[ElementStringIDs.keepEditingButton]
    let moreButton = XCUIApplication().buttons[ElementStringIDs.moreButton]
    let pageSettingsButton = XCUIApplication().buttons[ElementStringIDs.pageSettingsButton]
//    Editor area
    let titleView = XCUIApplication().otherElements[ElementStringIDs.titleView].firstMatch
    let titleViewBlog = XCUIApplication().otherElements[ElementStringIDs.titleViewBlog]
    static var isVisible: Bool {
        let app = XCUIApplication()
        let createBlankPageButton = app.tables[ElementStringIDs.createBlankPageButton]
        return createBlankPageButton.exists && createBlankPageButton.isHittable
    }
    // Check createBlankPageButton, closeIcon, blogButton elements to ensure Site Page is fully loaded
    init() {
        let app = XCUIApplication()
        closeIcon = app.buttons[ElementStringIDs.closeIcon]
        blogButton = app.textViews[ElementStringIDs.blogButton]
        chooseALaytoutTitle = app.textViews[ElementStringIDs.chooseALaytoutTitle]
        createBlankPageButton = app.buttons[ElementStringIDs.createBlankPageButton]
        super.init(element: createBlankPageButton)
    }

    /**
     Tap on "Create Blank Page button" to create a new blank page.
     */
    @discardableResult
    func tapOnCreateBlankPageButton() -> SitePageScreen {
        XCTAssert(createBlankPageButton.waitForExistence(timeout: 3))
        XCTAssert(createBlankPageButton.waitForHittability(timeout: 3))
        XCTAssert(createBlankPageButton.isHittable)
        createBlankPageButton.tap()
        return self
    }

    /**
     Select the first available template to create a page from a layout.
     */
    func selectALayout() -> BlockEditorScreen {
        selectedTemplate.tap()
        XCTAssert(createPageButton.waitForExistence(timeout: 3))
        createPageButton.tap()
        return BlockEditorScreen()
    }

    /**
     Tap on "Close" icon to close the activity.
     */
    func clickOnCloseIcon() {
        XCTAssert(closeIcon.waitForExistence(timeout: 3))
        XCTAssert(closeIcon.waitForHittability(timeout: 3))
        XCTAssert(closeIcon.isHittable)
        closeIcon.tap()
    }

    /**
     Tap on "Publish" button to publish content.
     */
    func publish() -> EditorNoticeComponent {
        XCTAssert(publishButton.waitForExistence(timeout: 3))
        XCTAssert(publishButton.waitForHittability(timeout: 3))
        publishButton.tap()
        let secondPublishButton = XCUIApplication().descendants(matching: .button).containing(.button, identifier: "Publish").element(boundBy: 1)
        secondPublishButton.tap()
        return EditorNoticeComponent(withNotice: "Page published", andAction: "View")
    }

    /**
     Open "Page Settings" page to custom content from EditorPostSettings.
     */
    func openPageSettings() -> EditorPostSettings {
        moreButton.tap()
        pageSettingsButton.tap()
        return EditorPostSettings()
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> SitePageScreen {
        if titleViewBlog.exists {
            titleViewBlog.tap()
            titleViewBlog.clearTextIfNeeded()
            titleViewBlog.typeText(text)
        } else {
        titleView.tap()
        titleView.typeText(text)
        }
        return self
    }

    /**
     Tap on second "Publish" button, to confirm publication.
     */
    private func confirmPublish() {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().acceptAlert()} else {
            XCTAssert(publishButton.waitForExistence(timeout: 3))
            publishButton.tap()
        }
    }

    static func isLoaded() -> Bool {
        return
            XCUIApplication().textViews[ElementStringIDs.chooseALaytoutTitle].exists
    }
}
