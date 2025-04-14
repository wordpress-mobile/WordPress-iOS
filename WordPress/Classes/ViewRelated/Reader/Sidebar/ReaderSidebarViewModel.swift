import SwiftUI
import UIKit
import WordPressData
import WordPressUI

final class ReaderSidebarViewModel: ObservableObject {
    @Published var selection: ReaderSidebarItem? {
        didSet { persistenSelection() }
    }

    private let tabItemsStore: ReaderMenuStoreProtocol
    private let contextManager: CoreDataStackSwift
    private var previousReloadTimestamp: Date?
    private var isRestoringSelection = false

    @Published var isCompact = false
    let isReaderAppModeEnabled: Bool

    var navigate: (ReaderSidebarNavigation) -> Void = { _ in }

    let menu: [ReaderStaticScreen]

    init(menuStore: ReaderMenuStoreProtocol = ReaderMenuStore(),
         contextManager: CoreDataStackSwift = ContextManager.shared,
         isReaderAppModeEnabled: Bool = false) {
        self.tabItemsStore = menuStore
        self.contextManager = contextManager

        self.isReaderAppModeEnabled = isReaderAppModeEnabled
        if isReaderAppModeEnabled {
            menu = [.subscrtipions, .lists, .tags, .saved, .likes]
        } else {
            menu = [.recent, .discover, .saved, .likes, .search]
            restoreSelection(defaultValue: .main(.recent))
        }

        self.reloadMenuIfNeeded()
    }

    func restoreSelection(defaultValue: ReaderSidebarItem?) {
        isRestoringSelection = true // TODO: refactor this
        defer { isRestoringSelection = false }
        if let selection = UserDefaults.standard.readerSidebarSelection {
            self.selection = .main(selection)
        } else {
            self.selection = defaultValue
        }
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
            tabItemsStore.refreshMenu()
        }
    }

    private func persistenSelection() {
        if !isRestoringSelection, case .main(let screen)? = selection,
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
enum ReaderStaticScreen: String, Identifiable, Hashable, CaseIterable {
    case recent
    case discover
    case saved
    case likes
    case search
    case subscrtipions
    case lists
    case tags

    var id: ReaderStaticScreen { self }

    var localizedTitle: String {
        switch self {
        case .recent: SharedStrings.Reader.recent
        case .discover: SharedStrings.Reader.discover
        case .saved: SharedStrings.Reader.saved
        case .likes: SharedStrings.Reader.likes
        case .search: SharedStrings.Reader.search
        case .subscrtipions: SharedStrings.Reader.subscriptions
        case .lists: SharedStrings.Reader.lists
        case .tags: SharedStrings.Reader.tags
        }
    }

    var imageName: String {
        switch self {
        case .recent: "reader-menu-home"
        case .discover: "reader-menu-explorer"
        case .saved: "reader-menu-bookmark"
        case .likes: "reader-menu-star"
        case .search: "reader-menu-search"
        case .subscrtipions: "reader-menu-subscriptions"
        case .lists: "reader-menu-list"
        case .tags: "reader-menu-tag"
        }
    }

    var topicType: ReaderTopicType? {
        switch self {
        case .recent: .following
        case .discover: .discover
        case .saved: nil
        case .likes: .likes
        case .search: nil
        case .subscrtipions, .tags, .lists: nil
        }
    }

    var accessibilityIdentifier: String {
        "reader_sidebar_\(rawValue)"
    }
}

enum ReaderContentType {
    case saved
    case topic
}
