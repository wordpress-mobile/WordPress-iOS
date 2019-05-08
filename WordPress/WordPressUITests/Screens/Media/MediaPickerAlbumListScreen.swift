import XCTest

class MediaPickerAlbumListScreen: BaseScreen {
    let albumList: XCUIElement

    init() {
        let app = XCUIApplication()
        albumList = app.tables["AlbumTable"]

        super.init(element: albumList)
    }

    func selectAlbum(atIndex index: Int) -> MediaPickerAlbumScreen {
        albumList.cells.element(boundBy: index).tap()

        return MediaPickerAlbumScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["AlbumTable"].exists
    }
}
