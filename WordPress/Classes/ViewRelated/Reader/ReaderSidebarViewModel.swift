import SwiftUI
import UIKit
import WordPressUI

final class ReaderSidebarViewModel: ObservableObject {
    @Published var selection: ReaderSidebarItem? {
        didSet { persistenSelection() }
    }

    private let tabItemsStore: ReaderTabItemsStoreProtocol
    private let contextManager: CoreDataStackSwift
    private var previousReloadTimestamp: Date?

    var navigate: (ReaderSidebarNavigation) -> Void = { _ in }

    init(tabItemsStore: ReaderTabItemsStoreProtocol = ReaderTabItemsStore(),
         contextManager: CoreDataStackSwift = ContextManager.shared) {
        self.tabItemsStore = tabItemsStore
        self.contextManager = contextManager
        let selection = UserDefaults.standard.readerSidebarSelection
        self.selection = .main(selection ?? .recent)
        self.reloadMenuIfNeeded()
    }

    func getTopic(for topicType: ReaderTopicType) -> ReaderAbstractTopic? {
        return try? ReaderAbstractTopic.lookupAllMenus(in: contextManager.mainContext).first {
            ReaderHelpers.topicType($0) == topicType
        }
    }

    func onAppear() {
        reloadMenuIfNeeded()
    }

    private func reloadMenuIfNeeded() {
        if Date.now.timeIntervalSince(previousReloadTimestamp ?? .distantPast) > 60 {
            previousReloadTimestamp = .now
            tabItemsStore.getItems()
        }
    }

    private func persistenSelection() {
        if case .main(let screen)? = selection,
           screen == .recent || screen == .discover {
            UserDefaults.standard.readerSidebarSelection = screen
        }
    }
}

enum ReaderSidebarItem: Identifiable, Hashable {
    /// One of the main navigation areas.
    case main(ReaderStaticScreen)
    case allSubscriptions
    case subscription(TaggedManagedObjectID<ReaderSiteTopic>)
    case list(TaggedManagedObjectID<ReaderListTopic>)
    case tag(TaggedManagedObjectID<ReaderTagTopic>)
    case organization(TaggedManagedObjectID<ReaderTeamTopic>)

    var id: ReaderSidebarItem { self }
}

enum ReaderSidebarNavigation {
    case addTag
    case discoverTags
}

/// One of the predefined main navigation areas in the reader. The app displays
/// these even if the respective "topics" were not loaded yet.
enum ReaderStaticScreen: String, CaseIterable, Identifiable, Hashable {
    case recent
    case discover
    case saved
    case likes
    case search

    var id: ReaderStaticScreen { self }

    var localizedTitle: String {
        switch self {
        case .recent: NSLocalizedString("reader.sidebar.recent", value: "Recent", comment: "Reader sidebar menu item")
        case .discover: NSLocalizedString("reader.sidebar.discover", value: "Discover", comment: "Reader sidebar menu item")
        case .saved: NSLocalizedString("reader.sidebar.saved", value: "Saved", comment: "Reader sidebar menu item")
        case .likes: NSLocalizedString("reader.sidebar.likes", value: "Likes", comment: "Reader sidebar menu item")
        case .search: NSLocalizedString("reader.sidebar.search", value: "Search", comment: "Reader sidebar menu item")
        }
    }

    var systemImage: String {
        switch self {
        case .recent: "newspaper"
        case .discover: "safari"
        case .saved: "bookmark"
        case .likes: "star"
        case .search: "magnifyingglass"
        }
    }

    var topicType: ReaderTopicType? {
        switch self {
        case .recent: .following
        case .discover: .discover
        case .saved: nil
        case .likes: .likes
        case .search: nil
        }
    }

    // TODO: replace these values ones the sidebar gets integrated on iPhone
    var accessibilityIdentifier: String {
        switch self {
        case .recent: "reader_sidebar_subscriptions"
        case .discover: "reader_sidebar_discover"
        case .saved: "reader_sidebar_saved"
        case .likes: "reader_sidebar_liked"
        case .search: "reader_sidebar_search"
        }
    }
}
