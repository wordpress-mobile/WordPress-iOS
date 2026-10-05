import XCTest

/// The Reader tab's menu of streams: Recent, Discover, Saved and so on, then the subscriptions,
/// lists and tags.
final class ReaderScreen: ScreenObject {
    enum Stream: String, CaseIterable {
        case recent
        case saved
        case likes
        case search
        // The app's identifier is misspelled.
        case subscriptions = "subscrtipions"

        var title: String {
            switch self {
            case .recent: "Recent"
            case .saved: "Saved"
            case .likes: "Likes"
            case .search: "Search"
            case .subscriptions: "Subscriptions"
            }
        }
    }

    private let menuGetter: ElementGetter = {
        $0.collectionViews["reader_sidebar"]
    }

    var menu: XCUIElement { menuGetter(app) }

    init(app: XCUIApplication) throws {
        Self.returnToMenu(in: app, menu: menuGetter(app))
        try super.init(expectedElementGetters: [menuGetter], app: app)
    }

    func goTo(_ stream: Stream) throws -> ReaderStreamScreen {
        try tap(app.descendants(matching: .any).matching(identifier: "reader_sidebar_\(stream.rawValue)").firstMatch)
        return try ReaderStreamScreen(title: stream.title, app: app)
    }

    /// Opens the stream of a site the account is subscribed to.
    func goToSubscription(named name: String) throws -> ReaderStreamScreen {
        let row = menu.staticTexts[name]
        try scroll(to: row, in: menu)
        row.tap()
        return try ReaderStreamScreen(title: name, app: app)
    }

    /// Switches the menu to and from the mode for reordering and removing its items.
    @discardableResult
    func toggleEditing() throws -> Self {
        let editButton = app.navigationBars["Reader"].buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            try waitFor(app.navigationBars["Reader"].buttons["checkmark"])
        } else {
            try tap(app.navigationBars["Reader"].buttons["checkmark"])
            try waitFor(editButton)
        }
        return self
    }

    /// The tab reopens on the stream it last showed, so this goes back from that to the menu.
    private static func returnToMenu(in app: XCUIApplication, menu: XCUIElement) {
        let backButton = app.navigationBars.buttons["BackButton"].firstMatch
        let deadline = Date(timeIntervalSinceNow: defaultWaitTimeout)

        while !menu.exists, Date() < deadline {
            if backButton.exists {
                backButton.tap()
            }
        }
    }
}
