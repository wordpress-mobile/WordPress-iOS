import Foundation
import XCTest

class BlockEditorScreen: BaseScreen {

    // Navigation bar
    let editorNavBar = XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"]
    let editorCloseButton = XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"]
    let publishButton = XCUIApplication().buttons["Publish"]
    let moreButton = XCUIApplication().buttons["More"]

    // Editor area
    // Title
//    let titleView = XCUIApplication().textViews.containing(.staticText, identifier: "Add title").element(boundBy: 0) // identifier is localizable
    let titleView = XCUIApplication().textViews.containing(.staticText, identifier: localizedString("Add title")).element(boundBy: 0)
    // Paragraph block
    let paragraphView = XCUIApplication().otherElements["block-0-core/paragraph"].textViews.element(boundBy: 0)
    // Image block
    let imagePlaceholder = XCUIApplication().buttons["Image block. Empty"] // identifier is localizable

    // Toolbar
//    let addBlockButton = XCUIApplication().buttons["Add block"] // identifier is localizable
    let addBlockButton = XCUIApplication().buttons[localizedString("Add block")]

    // Action sheets
    let actionSheet = XCUIApplication().sheets.element(boundBy: 0)
    let imageDeviceButton = XCUIApplication().sheets.buttons["Choose from device"] // identifier is localizable
    let discardButton = XCUIApplication().buttons["Discard"] // identifier is localizable
    let postSettingsButton = XCUIApplication().sheets.buttons["Post Settings"] // identifier is localizable
    let keepEditingButton = XCUIApplication().sheets.buttons["Keep Editing"] // identifier is localizable

    init() {
        super.init(element: editorNavBar)
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
        addBlock("Paragraph")
        paragraphView.typeText(text)

        return self
    }

    /**
     Adds an image block with latest image from device.
     */
    func addImage() -> BlockEditorScreen {
        addBlock("Image")
        addImageByOrder(id: 0)
        
        return self
    }

    // returns void since return screen depends on from which screen it loaded
    func closeEditor() {
        // Close the More menu if needed
        if actionSheet.exists {
            if isIpad {
                app.otherElements["PopoverDismissRegion"].tap()
            } else {
                keepEditingButton.tap()
            }
        }
        // Close the editor and discard any local changes
        editorCloseButton.tap()
        let notSavedState = app.staticTexts["You have unsaved changes."]
        if notSavedState.exists {
            Logger.log(message: "Discarding unsaved changes", event: .v)
            discardButton.tap()
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
        XCUIApplication().otherElements[blockLabel].tap()
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
            if isIpad {
                app.alerts.buttons["Publish"].tap()
            } else {
                app.sheets.buttons["Publish"].tap()
            }
        }
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["Gutenberg Editor Navigation Bar"].buttons["Close"].exists
    }
}
