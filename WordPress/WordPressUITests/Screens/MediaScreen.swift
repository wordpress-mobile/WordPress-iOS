import UITestsFoundation
import XCTest

class MediaScreen: BaseScreen {

    private struct ElementIDs {
        static let mediaGridView = "MediaCollection"
    }

    init() {
        let mediaGrid = XCUIApplication().collectionViews[ElementIDs.mediaGridView]
        super.init(element: mediaGrid)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables[ElementIDs.mediaGridView].exists
    }
}
