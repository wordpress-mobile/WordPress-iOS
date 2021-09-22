import XCTest

public class MediaPickerAlbumListScreen: BaseScreen {
    let albumList: XCUIElement

    public init() {
        let app = XCUIApplication()
        albumList = app.tables["AlbumTable"]

        super.init(element: albumList)
    }

    public func selectAlbum(atIndex index: Int) -> MediaPickerAlbumScreen {
        let selectedAlbum = albumList.cells.element(boundBy: index)
        XCTAssertTrue(selectedAlbum.waitForExistence(timeout: 5), "Selected album did not load")
        selectedAlbum.tap()

        return MediaPickerAlbumScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().tables["AlbumTable"].exists
    }
}
