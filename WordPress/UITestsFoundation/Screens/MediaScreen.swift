import ScreenObject
import XCTest

public class MediaScreen: ScreenObject {

    private let mediaCollectionGetter: (XCUIApplication) -> XCUIElement = {
        $0.collectionViews["MediaCollection"]
    }

    var mediaCollection: XCUIElement { mediaCollectionGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ mediaCollectionGetter ],
            app: app
        )
    }

    static func isLoaded() -> Bool {
        (try? MediaScreen().isLoaded) ?? false
    }
}
