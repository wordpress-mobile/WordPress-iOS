import XCTest

/// The site's pages list.
final class PagesScreen: ScreenObject {
    enum Filter: String, CaseIterable {
        case published, drafts, scheduled, trashed
    }

    private let tableGetter: ElementGetter = {
        $0.tables["PagesTable"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter, Self.navigationBarTitle("Pages")], app: app)
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

    func goToFirstPage() throws -> EditorScreen {
        try tapFirst(tableGetter(app).cells.firstMatch, named: "pages under this filter")
        return try EditorScreen(app: app)
    }

    private func tab(for filter: Filter) -> XCUIElement {
        // The list exposes its filter tabs twice in the accessibility tree.
        tableGetter(app).buttons[filter.rawValue].firstMatch
    }
}
