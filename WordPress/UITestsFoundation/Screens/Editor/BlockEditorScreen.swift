import ScreenObject
import XCTest
import XCUITestHelpers

public class BlockEditorScreen: ScreenObject {

    let editorCloseButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"]
    }

    let undoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Undo"]
    }

    let redoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Redo"]
    }

    let addBlockButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["add-block-button"]
    }

    let moreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["more_post_options"]
    }

    let insertFromUrlButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Insert from URL"]
    }

    let applyButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Apply"]
    }

    var editorCloseButton: XCUIElement { editorCloseButtonGetter(app) }
    var undoButton: XCUIElement { undoButtonGetter(app) }
    var redoButton: XCUIElement { redoButtonGetter(app) }
    var addBlockButton: XCUIElement { addBlockButtonGetter(app) }
    var moreButton: XCUIElement { moreButtonGetter(app) }
    var insertFromUrlButton: XCUIElement { insertFromUrlButtonGetter(app) }
    var applyButton: XCUIElement { applyButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // The block editor has _many_ elements but most are loaded on-demand. To verify the screen
        // is loaded, we rely only on the button to add a new block and on the navigation bar we
        // expect to encase the screen.
        try super.init(
            expectedElementGetters: [ editorCloseButtonGetter, undoButtonGetter, redoButtonGetter, addBlockButtonGetter ],
            app: app,
            waitTimeout: 10
        )
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    public func enterTextInTitle(text: String) -> BlockEditorScreen {
        let titleView = app.otherElements["Post title. Empty"].firstMatch // Uses a localized string
        XCTAssert(titleView.waitForExistence(timeout: 3), "Title View does not exist!")

        titleView.tap()
        titleView.typeText(text)

        return self
    }

    /**
    Adds a paragraph block with text.
     - Parameter withText: the text to enter in the paragraph block
     */
    public func addParagraphBlock(withText text: String) -> BlockEditorScreen {
        addBlock("Paragraph block")

        let paragraphView = app.otherElements["Paragraph Block. Row 1. Empty"].textViews.element(boundBy: 0)
        paragraphView.typeText(text)

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
        app.textFields.element.typeText(UrlPath)
        applyButton.tap()
    }

    @discardableResult
    public func verifyMediaBlocksDisplayed() -> Self {
        let imagePredicate = NSPredicate(format: "label == 'Image Block. Row 1'")
        let videoPredicate = NSPredicate(format: "label == 'Video Block. Row 2'")
        let audioPredicate = NSPredicate(format: "label == 'Audio Block. Row 3'")

        XCTAssertTrue(app.buttons.containing(imagePredicate).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(videoPredicate).firstMatch.exists)
        XCTAssertTrue(app.buttons.containing(audioPredicate).firstMatch.exists)

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
                guard app.staticTexts["You have unsaved changes."].waitForIsHittable(timeout: 3) else { return }

                Logger.log(message: "Discarding unsaved changes", event: .v)
                let discardButton = app.buttons["Discard"] // Uses a localized string
                discardButton.tap()
            }

            let editorNavBar = app.navigationBars["Gutenberg Editor Navigation Bar"]
            let waitForEditorToClose = editorNavBar.waitFor(predicateString: "isEnabled == false")
            XCTAssertEqual(waitForEditorToClose, .completed, "Block editor should be closed but is still loaded.")
        }
    }

    // Sometimes ScreenObject times out due to long loading time making the Editor Screen evaluate to `nil`.
    // This function adds the ability to still close the Editor Screen when that happens.
    public static func closeEditorDiscardingChanges(app: XCUIApplication = XCUIApplication()) {
        let closeButton = app.buttons["Close"]
        if closeButton.waitForIsHittable() { closeButton.tap() }

        let discardChangesButton = app.buttons["Discard"]
        if discardChangesButton.waitForIsHittable() { discardChangesButton.tap() }
    }

    public func publish() throws -> EditorNoticeComponent {
        let publishButton = app.buttons["Publish"]
        let publishNowButton = app.buttons["Publish Now"]
        var tries = 0
        // This loop to check for Publish Now Button is an attempt to confirm that the publishButton.tap() call took effect.
        // The tests would fail sometimes in the pipeline with no apparent reason.
        repeat {
            publishButton.tap()
            tries += 1
        } while !publishNowButton.waitForIsHittable(timeout: 3) && tries <= 3
        try confirmPublish()

        return try EditorNoticeComponent(withNotice: "Post published", andAction: "View")
    }

    public func openPostSettings() throws -> EditorPostSettings {
        moreButton.tap()
        let postSettingsButton = app.buttons["Post Settings"] // Uses a localized string
        postSettingsButton.tap()

        return try EditorPostSettings()
    }

    private func getContentStructure() -> String {
        moreButton.tap()
        let contentStructure = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'Content Structure'")).label
        dismissBlockEditorPopovers()

        return contentStructure
    }

    private func dismissBlockEditorPopovers() {
        if XCUIDevice.isPad {
            app.otherElements["PopoverDismissRegion"].tap()
            dismissImageViewIfNeeded()
        } else {
            app.buttons["Keep Editing"].tap()
        }
    }

    private func dismissImageViewIfNeeded() {
        let fullScreenImage = app.images["Fullscreen view of image. Double tap to dismiss"]
        if fullScreenImage.exists { fullScreenImage.tap() }
    }

    @discardableResult
    public func verifyContentStructure(blocks: Int, words: Int, characters: Int) throws -> BlockEditorScreen {
        let expectedStructure = "Content Structure Blocks: \(blocks), Words: \(words), Characters: \(characters)"
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
        XCTAssertTrue(undoButton.waitForIsHittable(timeout: 3))
        undoButton.tap()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func undoIsDisabled() throws -> BlockEditorScreen {
        XCTAssertFalse(undoButton.isEnabled)

        return try BlockEditorScreen()
    }

    @discardableResult
    public func redo() throws -> BlockEditorScreen {
        XCTAssertTrue(redoButton.waitForIsHittable(timeout: 3))
        redoButton.tap()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func redoIsDisabled() throws -> BlockEditorScreen {
        XCTAssertFalse(redoButton.isEnabled)

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

    private func chooseFromDevice() throws -> MediaPickerAlbumScreen {
        let imageDeviceButton = app.buttons["Choose from device"] // Uses a localized string

        imageDeviceButton.tap()

        // Allow access to device media
        app.tap() // trigger the media permissions alert handler

        return try MediaPickerAlbumListScreen()
                    .selectAlbum(atIndex: 0)
    }

    private func confirmPublish() throws {
        if FancyAlertComponent.isLoaded() {
            try FancyAlertComponent().acceptAlert()
        } else {
            let publishNowButton = app.buttons["Publish Now"]
            publishNowButton.tap()
            dismissBloggingRemindersAlertIfNeeded()
        }
    }

    public func dismissBloggingRemindersAlertIfNeeded() {
        guard app.buttons["Set reminders"].waitForExistence(timeout: 3) else { return }

        if XCUIDevice.isPad {
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
}
