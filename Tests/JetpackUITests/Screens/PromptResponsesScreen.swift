import XCTest

/// The Reader's list of posts answering a blogging prompt.
final class PromptResponsesScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["reader_table_view"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter], app: app)
    }
}
