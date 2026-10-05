import XCTest

/// The site's posts list.
final class PostsScreen: ScreenObject {
    enum Filter: String, CaseIterable {
        case published, drafts, scheduled, trashed
    }

    private let tableGetter: ElementGetter = {
        $0.tables["PostsTable"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter, Self.navigationBarTitle("Posts")], app: app)
    }

    @discardableResult
    func select(_ filter: Filter) throws -> Self {
        try select(tab: tab(for: filter))
        return self
    }

    /// Waits for `filter` to be the selected one, without tapping it.
    @discardableResult
    func waitForSelection(of filter: Filter) throws -> Self {
        try waitForSelection(of: tab(for: filter))
        return self
    }

    func goToFirstPost() throws -> EditorScreen {
        try tapFirst(tableGetter(app).cells.firstMatch, named: "posts under this filter")
        return try EditorScreen(app: app)
    }

    private func tab(for filter: Filter) -> XCUIElement {
        // The list exposes its filter tabs twice in the accessibility tree.
        tableGetter(app).buttons[filter.rawValue].firstMatch
    }
}
