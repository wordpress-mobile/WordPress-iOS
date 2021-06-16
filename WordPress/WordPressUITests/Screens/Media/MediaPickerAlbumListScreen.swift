import UITestsFoundation
import XCTest

class MediaPickerAlbumListScreen: BaseScreen {
    let albumList: XCUIElement

    init() {
        let app = XCUIApplication()
        albumList = app.tables["AlbumTable"]

        super.init(element: albumList)
    }

    func selectAlbum(atIndex index: Int) -> MediaPickerAlbumScreen {
        let selectedAlbum = albumList.cells.element(boundBy: index)
        XCTAssertTrue(selectedAlbum.waitForExistence(timeout: 5), "Selected album did not load")
        selectedAlbum.tap()

        return MediaPickerAlbumScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["AlbumTable"].exists
    }
}
