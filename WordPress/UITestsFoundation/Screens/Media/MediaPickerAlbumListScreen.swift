import ScreenObject
import XCTest

public class MediaPickerAlbumListScreen: ScreenObject {

    private let albumListGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["AlbumTable"]
    }

    var albumList: XCUIElement { albumListGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: albumListGetter,
            app: app
        )
    }

    public func selectAlbum(atIndex index: Int) throws -> MediaPickerAlbumScreen {
        let selectedAlbum = albumList.cells.element(boundBy: index)
        XCTAssertTrue(selectedAlbum.waitForExistence(timeout: 5), "Selected album did not load")
        waitAndTap(selectedAlbum)

        return try MediaPickerAlbumScreen()
    }

    public static func isLoaded() -> Bool {
        (try? MediaPickerAlbumListScreen().isLoaded) ?? false
    }
}
