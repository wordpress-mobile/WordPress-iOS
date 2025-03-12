import ScreenObject
import XCTest

public final class ReaderMenuScreen: ScreenObject {
    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init {
            $0.collectionViews["reader_sidebar"].firstMatch
        }
    }

    public enum ReaderStream: String {
        case recent
        case discover
        case saved
        case likes
        case search

        func menuButton(_ app: XCUIApplication) -> XCUIElement {
            app.otherElements["reader_sidebar_\(rawValue)"].firstMatch
        }
    }

    @discardableResult
    public func open(_ stream: ReaderStream) throws -> ReaderScreen {
        stream.menuButton(app).tap()
        return try ReaderScreen()
    }
}
