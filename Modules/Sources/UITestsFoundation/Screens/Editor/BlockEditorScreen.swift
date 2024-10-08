import ScreenObject
import XCTest
import XCUITestHelpers

public class BlockEditorScreen: ScreenObject {

    private let addBlockButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-block-button"]
    }

    private let chooseFromDeviceButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Choose from device"]
    }

    private let closeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Close"]
    }

    private let discardButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Discard"]
    }

    private let dismissPopoverRegionGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["PopoverDismissRegion"]
    }

    private let editorCloseButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"]
    }

    private let editorNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"]
    }

    private let firstParagraphBlockGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["Paragraph Block. Row 1. Empty"]
    }

    private let fullScreenImageGetter: (XCUIApplication) -> XCUIElement = {
        $0.images["Fullscreen view of image. Double tap to dismiss"]
    }

    private let insertFromUrlButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Insert from URL"]
    }

    private let moreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["more_post_options"]
    }

    private let noticeViewButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["View"]
    }

    private let noticeViewTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["notice_title_and_message"]
    }

    private let pageTitleViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["Page title. Empty"]
    }

    private let postSettingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Post Settings"]
    }

    private let postTitleViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["Post title. Empty"]
    }

    private let redoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Redo"]
    }

    private let returnButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Return"]
    }

    private let setRemindersButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Set reminders"]
    }

    private let switchToHTMLModeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Code Editor"]
    }

    private let undoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Undo"]
    }

    private let unsavedChangesLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["You have unsaved changes."]
    }

    private let publishButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Publish"]
    }

    var addBlockButton: XCUIElement { addBlockButtonGetter(app) }
    var chooseFromDeviceButton: XCUIElement { chooseFromDeviceButtonGetter(app) }
    var closeButton: XCUIElement { closeButtonGetter(app) }
    var discardButton: XCUIElement { discardButtonGetter(app) }
    var dismissPopoverRegion: XCUIElement { dismissPopoverRegionGetter(app) }
    var editorCloseButton: XCUIElement { editorCloseButtonGetter(app) }
    var editorNavigationBar: XCUIElement { editorNavigationBarGetter(app) }
    var firstParagraphBlock: XCUIElement { firstParagraphBlockGetter(app) }
    var fullScreenImage: XCUIElement { fullScreenImageGetter(app) }
    var insertFromUrlButton: XCUIElement { insertFromUrlButtonGetter(app) }
    var moreButton: XCUIElement { moreButtonGetter(app) }
    var noticeViewButton: XCUIElement { noticeViewButtonGetter(app) }
    var noticeViewTitle: XCUIElement { noticeViewTitleGetter(app) }
    var pageTitleView: XCUIElement { pageTitleViewGetter(app) }
    var postSettingsButton: XCUIElement { postSettingsButtonGetter(app) }
    var postTitleView: XCUIElement { postTitleViewGetter(app) }
    var redoButton: XCUIElement { redoButtonGetter(app) }
    var returnButton: XCUIElement { returnButtonGetter(app) }
    var setRemindersButton: XCUIElement { setRemindersButtonGetter(app) }
    var switchToHTMLModeButton: XCUIElement { switchToHTMLModeButtonGetter(app) }
    var undoButton: XCUIElement { undoButtonGetter(app) }
    var unsavedChangesLabel: XCUIElement { unsavedChangesLabelGetter(app) }
    var publishButton: XCUIElement { publishButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // The block editor has _many_ elements but most are loaded on-demand. To verify the screen
        // is loaded, we rely only on the button to add a new block and on the navigation bar we
        // expect to encase the screen.
        try super.init(
            expectedElementGetters: [
                editorNavigationBarGetter,
                addBlockButtonGetter,
                editorCloseButtonGetter,
                redoButtonGetter,
                undoButtonGetter
            ],
            app: app
        )
    }

    public enum postAction: String {
        case publish = "Publish"
        case schedule = "Schedule"
    }

    public enum postType: String {
        case page = "page"
        case post = "post"
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    public func enterTextInTitle(text: String, postType: postType = .post) -> BlockEditorScreen {
        let titleView = postType == .post ? postTitleView.firstMatch : pageTitleView.firstMatch
        XCTAssert(titleView.waitForExistence(timeout: 3), "Title View does not exist!")
        type(text: text, in: titleView)

        return self
    }

    /**
    Adds a paragraph block with text.
     - Parameter withText: the text to enter in the paragraph block
     */
    public func addParagraphBlock(withText text: String) -> BlockEditorScreen {
        addBlock("Paragraph block")

        let paragraphView = firstParagraphBlock.textViews.element(boundBy: 0)
        type(text: text, in: paragraphView)

        return self
    }

    /**
     Adds an image block with latest image from device.
     */
    public func addImage() throws -> BlockEditorScreen {
        addBlock("Image block")
        try addImageByOrder(id: 0)

        return self
    }

    /**
     Adds a gallery block with multiple images from device.
     */
    public func addImageGallery() throws -> BlockEditorScreen {
        addBlock("Gallery block")
        try addMultipleImages(numberOfImages: 3)

        return self
    }

    public func addVideoFromUrl(urlPath: String) -> Self {
        addMediaBlockFromUrl(
            blockType: "Video block",
            UrlPath: urlPath
        )

        return self
    }

    public func addAudioFromUrl(urlPath: String) -> Self {
        addMediaBlockFromUrl(
            blockType: "Audio block",
            UrlPath: urlPath
        )

        return self
    }

    private func addMediaBlockFromUrl(blockType: String, UrlPath: String) {
        addBlock(blockType)
        insertFromUrlButton.tap()
        type(text: UrlPath, in: app.textFields.element)
        // to dismiss media block URL prompt
        tapTopOfScreen()
    }

    @discardableResult
    public func verifyMediaBlocksDisplayed() -> Self {
        let imageBlock = NSPredicate(format: "label == 'Image Block. Row 1'")
        let imageCaption = NSPredicate(format: "label == 'Image caption. Empty'")
        let videoBlock = NSPredicate(format: "label == 'Video Block. Row 2'")
        let videoCaption = NSPredicate(format: "label == 'Video caption. Empty'")
        let audioBlock = NSPredicate(format: "label == 'Audio Block. Row 3'")
        let audioPlayer = NSPredicate(format: "label == 'Audio Player'")

        XCTAssertTrue(app.buttons.containing(imageBlock).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(imageCaption).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(videoBlock).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(audioBlock).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(videoCaption).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(audioPlayer).firstMatch.exists)

        return self
    }

    /**
    Selects a block based on part of the block label (e.g. partial text in a paragraph block)
     */
    @discardableResult
    public func selectBlock(containingText text: String) -> BlockEditorScreen {
        let predicate = NSPredicate(format: "label CONTAINS[c] '\(text)'")
        XCUIApplication().buttons.containing(predicate).firstMatch.tap()
        return self
    }

    // returns void since return screen depends on from which screen it loaded
    public func closeEditor() {
        XCTContext.runActivity(named: "Close the block editor") { (activity) in
            XCTContext.runActivity(named: "Close the More menu if needed") { (activity) in
                let actionSheet = app.sheets.element(boundBy: 0)
                if actionSheet.exists {
                    dismissBlockEditorPopovers()
                }
            }

            // Wait for close button to be hittable (i.e. React "Loading from pre-bundled file" message is gone)
            editorCloseButton.waitForIsHittable(timeout: 3)
            editorCloseButton.tap()

            XCTContext.runActivity(named: "Discard any local changes") { (activity) in
                guard unsavedChangesLabel.waitForIsHittable(timeout: 3) else { return }

                Logger.log(message: "Discarding unsaved changes", event: .v)
                discardButton.tap()
            }

            let waitForEditorToClose = editorNavigationBar.waitFor(predicateString: "isEnabled == false")
            XCTAssertEqual(waitForEditorToClose, .completed, "Block editor should be closed but is still loaded.")
        }
    }

    public func postAndViewEpilogue(action: postAction) throws -> EditorPublishEpilogueScreen {
        try publish().confirm()
        waitAndTap(noticeViewButton)

        return try EditorPublishEpilogueScreen()
    }

    public func publish() throws -> PrepublishingSheetScreen {
        waitForExistenceAndTap(publishButton)
        return try PrepublishingSheetScreen()
    }

    public func waitForNoticeToDisappear() throws {
        waitForElementToDisappear(noticeViewButton)
    }

    @discardableResult
    public func openPostSettings() throws -> EditorPostSettings {
        waitAndTap(moreButton)
        waitAndTap(postSettingsButton)

        return try EditorPostSettings()
    }

    @discardableResult
    public func switchToHTMLMode() throws -> HTMLEditorScreen {
        moreButton.tap()
        switchToHTMLModeButton.tap()

        return try HTMLEditorScreen()
    }

    private func getContentStructure() -> String {
        // Gutenberg takes a bit of time to generate this info
        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true
        _ = XCTWaiter.wait(for: [delayExpectation], timeout: 3)

        moreButton.tap()
        let contentStructure = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Blocks:'")).label
        dismissBlockEditorPopovers()

        return contentStructure
    }

    private func dismissBlockEditorPopovers() {
        // TODO: Find a better way to reliably dismiss a UIMenu without interacting with it
        waitAndTap(postSettingsButton)
        _ = try? EditorPostSettings().closePostSettings()

        dismissImageViewIfNeeded()
    }

    private func dismissImageViewIfNeeded() {
        if fullScreenImage.exists { fullScreenImage.tap() }
    }

    @discardableResult
    public func verifyContentStructure(blocks: Int, words: Int, characters: Int) throws -> BlockEditorScreen {
        let expectedStructure = "Blocks: \(blocks), Words: \(words), Characters: \(characters)"
        let actualStructure = getContentStructure()

        XCTAssertEqual(actualStructure, expectedStructure, "Unexpected post structure.")

        return try BlockEditorScreen()
    }

    private func addBlock(_ blockLabel: String) {
        addBlockButton.tap()
        let blockButton = app.buttons[blockLabel]
        if !blockButton.isHittable { app.scrollDownToElement(element: blockButton) }
        blockButton.tap()
    }

    @discardableResult
    public func undo() throws -> BlockEditorScreen {
        undoButton.tap()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func verifyUndoIsDisabled() throws -> BlockEditorScreen {
        XCTAssertFalse(undoButton.isEnabled)

        return try BlockEditorScreen()
    }

    @discardableResult
    public func verifyUndoIsVisible() throws -> BlockEditorScreen {
        XCTAssertTrue(undoButton.exists)

        return try BlockEditorScreen()
    }

    @discardableResult
    public func redo() throws -> BlockEditorScreen {
        redoButton.tap()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func verifyRedoIsDisabled() throws -> BlockEditorScreen {
        XCTAssertFalse(redoButton.isEnabled)

        return try BlockEditorScreen()
    }

    @discardableResult
    public func verifyRedoIsVisible() throws -> BlockEditorScreen {
        XCTAssertTrue(redoButton.exists)

        return try BlockEditorScreen()
    }

    /// Some tests might fail during the block picking flow. In such cases, we need to dismiss the
    /// block picker itself before being able to interact with the rest of the app again.
    public func dismissBlocksPickerIfNeeded() {
        // Determine whether the block picker is on screen using the visibility of the add block
        // button as a proxy
        guard addBlockButton.isFullyVisibleOnScreen() == false else { return }

        // Dismiss the block picker by swiping down
        app.swipeDown()

        XCTAssertTrue(addBlockButton.waitForIsHittable(timeout: 3))
    }

    /*
     Select Image from Camera Roll by its ID. Starts with 0
     */
    private func addImageByOrder(id: Int) throws {
        try chooseFromDevice()
            .selectImage(atIndex: 0)
    }

    /*
     Select Sequencial Images from Camera Roll by its ID. Starts with 0
     */
    private func addMultipleImages(numberOfImages: Int) throws {
        try chooseFromDevice()
            .selectMultipleImages(numberOfImages)
    }

    private func chooseFromDevice() throws -> PHPickerScreen {
        chooseFromDeviceButton.tap()

        return try PHPickerScreen()
    }

    public func dismissBloggingRemindersAlertIfNeeded() {
        guard setRemindersButton.waitForExistence(timeout: 5) else { return }

        if XCTestCase.isPad {
            app.swipeDown(velocity: .fast)
        } else {
            let dismissBloggingRemindersAlertButton = app.buttons.element(boundBy: 0)
            dismissBloggingRemindersAlertButton.tap()
        }
    }

    static func isLoaded() -> Bool {
        (try? BlockEditorScreen().isLoaded) ?? false
    }

    @discardableResult
    public func openBlockPicker() throws -> BlockEditorScreen {
        addBlockButton.tap()
        return try BlockEditorScreen()
    }

    @discardableResult
    public func closeBlockPicker() throws -> BlockEditorScreen {
        editorCloseButton.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).tap()
        return try BlockEditorScreen()
    }

    // This could be moved as an XCUIApplication method via an extension if needed elsewhere.
    private func type(text: String, in element: XCUIElement) {
        // A simple implementation here would be:
        //
        // element.tap()
        // element.typeText(text)
        //
        // But as of a recent (but not pinpointed at the time of writing) Gutenberg update, that is not enough.
        // The test would fail with: Neither element nor any descendant has keyboard focus.
        // (E.g.: https://buildkite.com/automattic/wordpress-ios/builds/15598)
        //
        // The following is a convoluted but seemingly robust approach that bypasses the keyboard by using the pasteboard instead.
        UIPasteboard.general.string = text

        // Safety check
        XCTAssertTrue(element.waitForExistence(timeout: 1))

        element.doubleTap()

        let pasteButton = app.menuItems["Paste"]

        if pasteButton.waitForExistence(timeout: 1) == false {
            // Drill in hierarchy looking for it
            var found = false
            element.descendants(matching: .any).enumerated().forEach { e in
                guard found == false else { return }

                e.element.firstMatch.doubleTap()

                if pasteButton.waitForExistence(timeout: 1) {
                    found = true
                }
            }
        }

        XCTAssertTrue(pasteButton.exists, "Could not find menu item paste button.")

        pasteButton.tap()
    }
}
