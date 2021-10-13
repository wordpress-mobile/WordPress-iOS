import ScreenObject
import XCTest

public class MediaPickerAlbumListScreen: ScreenObject {

    private let albumListGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["AlbumTable"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetter: albumListGetter,
            app: app
        )
    }

    public func selectAlbum(atIndex index: Int) -> MediaPickerAlbumScreen {
        let selectedAlbum = albumListGetter(app).cells.element(boundBy: index)
        XCTAssertTrue(selectedAlbum.waitForExistence(timeout: 5), "Selected album did not load")
        selectedAlbum.tap()

        return MediaPickerAlbumScreen()
    }

    public static func isLoaded() -> Bool {
        (try? MediaPickerAlbumListScreen().isLoaded) ?? false
    }
}
