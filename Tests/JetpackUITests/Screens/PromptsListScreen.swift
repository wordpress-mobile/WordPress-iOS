import XCTest

/// The list of recent blogging prompts.
final class PromptsListScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["Blogging Prompts List"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter], app: app)
    }
}
