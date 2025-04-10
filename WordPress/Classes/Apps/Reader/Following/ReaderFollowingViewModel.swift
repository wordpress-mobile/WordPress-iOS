import Foundation
import SwiftUI
import WordPressData

@MainActor
final class ReaderFollowingViewModel: ObservableObject {
    // TODO: extract to a service (store fetches both subscription and menus)
    private let store = ReaderMenuStore()

    @Published var selectedTab: ReaderFollowingTab = .subscriptions

    @Published private(set) var error: Error?
    @Published private(set) var isRefreshing = false

    private var refreshTask: Task<Void, Never>? {
        didSet { isRefreshing = refreshTask != nil }
    }

    private let _navigate: (ReaderFollowingNavigation) -> Void

    deinit {
        refreshTask?.cancel()
    }

    init(navigate: @escaping (ReaderFollowingNavigation) -> Void) {
        self._navigate = navigate
    }

    func refresh() async {
        if let task = refreshTask {
            await task.value
        }
        let task = Task {
            await _refresh()
        }
        refreshTask = task
        return await task.value
    }

    private func _refresh() async {
        error = nil
        isRefreshing = true

        return await withUnsafeContinuation { continuation in
            store.onCompletion = { [weak self] in
                // TODO: (reader) add error handling
                self?.refreshTask = nil
                self?.store.onCompletion = nil
                continuation.resume()
            }
            store.refreshMenu()
        }
    }

    func navigate(to route: ReaderFollowingNavigation) {
        _navigate(route)
    }
}

enum ReaderFollowingNavigation {
    case topic(ReaderAbstractTopic)
}

enum ReaderFollowingTab: CaseIterable {
    case subscriptions, lists, tags

    var title: String {
        switch self {
        case .subscriptions: NSLocalizedString("reader.following.subscriptions", value: "Subscriptions", comment: "Tabs on Reader Following screen")
        case .lists: NSLocalizedString("reader.following.lists", value: "Lists", comment: "Tabs on Reader Following screen")
        case .tags: NSLocalizedString("reader.following.tags", value: "Tags", comment: "Tabs on Reader Following screen")
        }
    }
}
