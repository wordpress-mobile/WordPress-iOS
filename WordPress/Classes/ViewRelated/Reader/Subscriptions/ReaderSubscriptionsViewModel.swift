import Foundation
import SwiftUI
import WordPressData

@MainActor
final class ReaderSubscriptionsViewModel: ObservableObject {
    private let store: CoreDataStackSwift

    @Published private(set) var error: Error?
    @Published private(set) var isRefreshing = false

    private var refreshTask: Task<Void, Never>? {
        didSet { isRefreshing = refreshTask != nil }
    }

    init(store: CoreDataStackSwift = ContextManager.shared) {
        self.store = store
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
            let service = ReaderTopicService(coreDataStack: self.store)
            service.fetchAllFollowedSites(success: { [weak self] in
                self?.refreshTask = nil
                continuation.resume()
            }, failure: { [weak self] error in
                self?.error = error
                self?.refreshTask = nil
                continuation.resume()
            })
        }
    }
}
