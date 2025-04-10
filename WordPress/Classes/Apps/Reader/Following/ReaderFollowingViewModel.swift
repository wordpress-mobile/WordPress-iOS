import Foundation
import SwiftUI
import WordPressData

@MainActor
final class ReaderFollowingViewModel: ObservableObject {
    // TODO: extract to a service (store fetches both subscription and menus)
    private let store = ReaderMenuStore()

    @Published private(set) var error: Error?
    @Published private(set) var isRefreshing = false

    private var refreshTask: Task<Void, Never>? {
        didSet { isRefreshing = refreshTask != nil }
    }

    deinit {
        refreshTask?.cancel()
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

        await withUnsafeContinuation { continuation in
            store.onCompletion = { [weak self]
                // TODO: (reader) add error handling
                self?.refreshTask = nil
                self?.store.onCompletion = nil
                continuation.resume()
            }
            store.refreshMenu()
        }
    }
}
