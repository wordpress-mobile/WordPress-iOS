import Foundation
import Testing
import WordPressData

@testable import WordPress

/// Saved posts are kept in the WordPress.com account, so Saved is only listed with one.
@MainActor
@Suite(.serialized)
struct ReaderSidebarSavedTests {

    @Test("Saved is listed when signed in to WordPress.com", arguments: [false, true])
    func savedListedWhenSignedIn(isReaderAppModeEnabled: Bool) {
        let viewModel = makeViewModel(isReaderAppModeEnabled: isReaderAppModeEnabled, isLoggedIn: true)

        #expect(viewModel.menu.contains(.saved))
    }

    @Test("Saved isn't listed when signed out", arguments: [false, true])
    func savedHiddenWhenSignedOut(isReaderAppModeEnabled: Bool) {
        let viewModel = makeViewModel(isReaderAppModeEnabled: isReaderAppModeEnabled, isLoggedIn: false)

        #expect(!viewModel.menu.contains(.saved))
        #expect(viewModel.menu.count == 4)
    }

    @Test("A restored Saved selection falls back to Recent when signed out")
    func restoredSavedSelectionWhenSignedOut() {
        let previous = UserDefaults.standard.readerSidebarSelection
        defer { UserDefaults.standard.readerSidebarSelection = previous }
        UserDefaults.standard.readerSidebarSelection = .saved

        #expect(makeViewModel(isLoggedIn: false).selection == .main(.recent))
        #expect(makeViewModel(isLoggedIn: true).selection == .main(.saved))
    }

    private func makeViewModel(isReaderAppModeEnabled: Bool = false, isLoggedIn: Bool) -> ReaderSidebarViewModel {
        ReaderSidebarViewModel(
            menuStore: EmptyReaderMenuStore(),
            contextManager: ContextManager.forTesting(),
            isReaderAppModeEnabled: isReaderAppModeEnabled,
            isLoggedIn: isLoggedIn
        )
    }
}

private struct EmptyReaderMenuStore: ReaderMenuStoreProtocol {
    func refreshMenu() {}
}

@MainActor
struct ReaderPostToolbarBookmarkTests {

    @Test("A post card's bookmark is only shown when signed in to WordPress.com", arguments: [false, true])
    func bookmarkNeedsAnAccount(isLoggedIn: Bool) {
        let post = ContextManager.forTesting().mainContext.insertNewObject(ofType: ReaderPost.self)

        let toolbar = ReaderPostToolbarViewModel.make(post: post, isLoggedIn: isLoggedIn)

        #expect(toolbar.isBookmarkEnabled == isLoggedIn)
    }
}
