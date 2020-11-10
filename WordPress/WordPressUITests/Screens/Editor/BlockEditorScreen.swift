import Foundation
import XCTest

class BlockEditorScreen: BaseScreen {

    // Navigation bar
    let editorNavBar = XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"]
    let editorCloseButton = XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"]
    let publishButton = XCUIApplication().buttons["Publish"]
    let publishNowButton = XCUIApplication().buttons["Publish Now"]
    let moreButton = XCUIApplication().buttons["more_post_options"]

    // Editor area
    // Title
    let titleView = XCUIApplication().otherElements["Post title. Empty"].firstMatch // Uses a localized string
    // Paragraph block
    let paragraphView = XCUIApplication().otherElements["Paragraph Block. Row 1. Empty"].textViews.element(boundBy: 0)
    // Image block
    let imagePlaceholder = XCUIApplication().buttons["Image block. Empty"] // Uses a localized string

    // Toolbar
    let addBlockButton = XCUIApplication().buttons["add-block-button"] // Uses a testID

    // Action sheets
    let actionSheet = XCUIApplication().sheets.element(boundBy: 0)
    let imageDeviceButton = XCUIApplication().sheets.buttons["Choose from device"] // Uses a localized string
    let discardButton = XCUIApplication().buttons["Discard"] // Uses a localized string
    let postSettingsButton = XCUIApplication().sheets.buttons["Post Settings"] // Uses a localized string
    let keepEditingButton = XCUIApplication().sheets.buttons["Keep Editing"] // Uses a localized string

    init() {
        // Check addBlockButton element to ensure block editor is fully loaded
        super.init(element: addBlockButton)
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> BlockEditorScreen {
        titleView.tap()
        titleView.typeText(text)

        return self
    }

    /**
    Adds a paragraph block with text.
     - Parameter withText: the text to enter in the paragraph block
     */
    func addParagraphBlock(withText text: String) -> BlockEditorScreen {
        addBlock("Paragraph block")
        paragraphView.typeText(text)

        return self
    }

    /**
     Adds an image block with latest image from device.
     */
    func addImage() -> BlockEditorScreen {
        addBlock("Image block")
        addImageByOrder(id: 0)

        return self
    }

    /**
    Selects a block based on part of the block label (e.g. partial text in a paragraph block)
     */
    @discardableResult
    func selectBlock(containingText text: String) -> BlockEditorScreen {
        let predicate = NSPredicate(format: "label CONTAINS[c] '\(text)'")
        XCUIApplication().buttons.containing(predicate).firstMatch.tap()
        return self
    }

    // returns void since return screen depends on from which screen it loaded
    func closeEditor() {
        XCTContext.runActivity(named: "Close the block editor") { (activity) in
            XCTContext.runActivity(named: "Close the More menu if needed") { (activity) in
                if actionSheet.exists {
                    if isIpad {
                        app.otherElements["PopoverDismissRegion"].tap()
                    } else {
                        keepEditingButton.tap()
                    }
                }
            }

            // Wait for close button to be hittable (i.e. React "Loading from pre-bundled file" message is gone)
            editorCloseButton.waitForHittability(timeout: 3)
            editorCloseButton.tap()

            XCTContext.runActivity(named: "Discard any local changes") { (activity) in
                let notSavedState = app.staticTexts["You have unsaved changes."]
                if notSavedState.exists {
                    Logger.log(message: "Discarding unsaved changes", event: .v)
                    discardButton.tap()
                }
            }

            let editorClosed = waitFor(element: editorNavBar, predicate: "isEnabled == false")
            XCTAssert(editorClosed, "Block editor should be closed but is still loaded.")
        }
    }

    func publish() -> EditorNoticeComponent {
        publishButton.tap()
        confirmPublish()

        return EditorNoticeComponent(withNotice: "Post published", andAction: "View")
    }

    func openPostSettings() -> EditorPostSettings {
        moreButton.tap()
        postSettingsButton.tap()

        return EditorPostSettings()
    }

    private func addBlock(_ blockLabel: String) {
        addBlockButton.tap()
        XCUIApplication().buttons[blockLabel].tap()
    }

    /*
     Select Image from Camera Roll by its ID. Starts with 0
     */
    private func addImageByOrder(id: Int) {
        imagePlaceholder.tap()
        imageDeviceButton.tap()

        // Allow access to device media
        app.tap() // trigger the media permissions alert handler

        // Inject the first picture
        MediaPickerAlbumListScreen()
            .selectAlbum(atIndex: 0)
            .selectImage(atIndex: 0)
    }

    private func confirmPublish() {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().acceptAlert()
        } else {
            publishNowButton.tap()
        }
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"].exists
    }
    @discardableResult
    func openBlockPicker() -> BlockEditorScreen {
        addBlockButton.tap()
        return BlockEditorScreen()
    }
    @discardableResult
    func closeBlockPicker() -> BlockEditorScreen {
        editorCloseButton.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).tap()
        return BlockEditorScreen()
    }
}
