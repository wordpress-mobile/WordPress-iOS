import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let backButton = "Back"
    static let createStoryPostButton = "AnnouncementsContinueButton"
    static let mediaPickerButton = "Media Picker Button"
    static let closeIconButton = "Close Button"
}

class StoryPageScreen: BaseScreen {
    let backButton: XCUIElement
    let createStoryPostButton: XCUIElement
    let mediaPickerButton: XCUIElement
    let closeIconButton: XCUIElement
    static var isVisible: Bool {
        let app = XCUIApplication()
        let mediaPickerButton = app.buttons[ElementStringIDs.mediaPickerButton]
        return mediaPickerButton.exists && mediaPickerButton.isHittable
    }
    init() {
        let app = XCUIApplication()
        createStoryPostButton = app.buttons[ElementStringIDs.createStoryPostButton]
        backButton = app.buttons[ElementStringIDs.backButton]
        mediaPickerButton = app.buttons[ElementStringIDs.mediaPickerButton]
        closeIconButton = app.buttons[ElementStringIDs.closeIconButton]
        super.init(element: mediaPickerButton)
    }

    func clickOnBackButton() {
        XCTAssert(backButton.waitForExistence(timeout: 3))
        XCTAssert(backButton.waitForHittability(timeout: 3))
        XCTAssert(backButton.isHittable)
        backButton.tap()
    }

    func clickOnCreateStoryPostButton() {
        XCTAssert(createStoryPostButton.waitForExistence(timeout: 3))
        XCTAssert(createStoryPostButton.waitForHittability(timeout: 3))
        XCTAssert(createStoryPostButton.isHittable)

        createStoryPostButton.tap()
    }

    func pickAnImageFromMedia() {
        XCTAssert(mediaPickerButton.waitForExistence(timeout: 3))
        XCTAssert(mediaPickerButton.waitForHittability(timeout: 3))
        XCTAssert(mediaPickerButton.isHittable)
        mediaPickerButton.tap()
        MediaPickerAlbumListScreen()
            .selectAlbum(atIndex: 0)
            .selectImage(atIndex: 0)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.createStoryPostButton].exists
    }
}
