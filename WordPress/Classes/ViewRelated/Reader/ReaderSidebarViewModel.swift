import SwiftUI
import UIKit
import WordPressUI

final class ReaderSidebarViewModel: ObservableObject {
    @Published var selection: ReaderSidebarItem?

    private let tabItemsStore: ReaderTabItemsStoreProtocol
    private let contextManager: CoreDataStackSwift

    init(tabItemsStore: ReaderTabItemsStoreProtocol = ReaderTabItemsStore(),
         contextManager: CoreDataStackSwift = ContextManager.shared) {
        self.tabItemsStore = tabItemsStore
        self.contextManager = contextManager

        // TODO: (wpsidebar) reload when appropriate
        tabItemsStore.getItems()

        self.selection = .main(.recent)
    }

    func getTopic(for topicType: ReaderTopicType) -> ReaderAbstractTopic? {
        return try? ReaderAbstractTopic.lookupAllMenus(in: contextManager.mainContext).first {
            ReaderHelpers.topicType($0) == topicType
        }
    }
}

enum ReaderSidebarItem: Identifiable, Hashable {
    /// One of the main navigation areas.
    case main(ReaderStaticScreen)
    case allSubscriptions
    case subscription(TaggedManagedObjectID<ReaderSiteTopic>)

    var id: ReaderSidebarItem { self }
}

/// One of the predefined main navigation areas in the reader. The app displays
/// these even if the respective "topics" were not loaded yet.
enum ReaderStaticScreen: CaseIterable, Identifiable, Hashable {
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
}
