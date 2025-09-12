import SwiftUI
import WordPressData
import WordPressUI
import WordPressShared
import CoreData

struct ReaderSubscriptionsView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    @State private var searchText = ""
    @State private var isShowingMainAddSubscriptonPopover = false

    @State private var searchResults: [ReaderSiteTopic]?
    @State private var searchTask: Task<Void, Never>?
    @State private var pendingSearchText: String?

    @StateObject private var viewModel = ReaderSubscriptionsViewModel()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var onSelection: (_ subscription: ReaderSiteTopic) -> Void = { _ in }

    var body: some View {
        Group {
            if subscriptions.isEmpty {
                GeometryReader { proxy in
                    ScrollView { // Makes it compatible with refreshable()
                        stateView.frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            } else {
                main
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ReaderSubscriptionAddButton(style: .navigation)
            if !subscriptions.isEmpty {
                EditButton()
            }
        }
        .navigationTitle(SharedStrings.Reader.subscriptions)
    }

    @ViewBuilder
    private var stateView: some View {
        if let error = viewModel.error {
            EmptyStateView.failure(error: error) {
                Task { await viewModel.refresh() }
            }
        } else if viewModel.isRefreshing {
            ProgressView()
        } else {
            emptyStateView
        }
    }

    private var emptyStateView: some View {
        EmptyStateView {
            Label(SharedStrings.Reader.subscriptions, systemImage: "doc.text.magnifyingglass")
        } description: {
            Text(Strings.emptyStateDetails)
        } actions: {
            ReaderSubscriptionAddButton(style: .compact)
        }
    }

    private var main: some View {
        List {
            if let searchResults {
                ForEach(searchResults, id: \.objectID, content: makeSubscriptionCell)
                    .onDelete(perform: delete)
            } else {
                ForEach(subscriptions, id: \.objectID, content: makeSubscriptionCell)
                    .onDelete(perform: delete)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText)
        .onReceive(subscriptions.publisher) { _ in
            if !searchText.isEmpty {
                performBackgroundSearch(searchText: searchText)
            }
        }
        .onChange(of: searchText) {
            performBackgroundSearch(searchText: $0)
        }
    }

    private func makeSubscriptionCell(for site: ReaderSiteTopic) -> some View {
        Button {
            onSelection(site)
        } label: {
            ReaderSubscriptionCell(site: site, onDelete: delete)
        }
        .swipeActions(edge: .leading) {
            if let siteURL = URL(string: site.siteURL) {
                ShareLink(item: siteURL).tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(SharedStrings.Reader.unfollow, role: .destructive) {
                ReaderSubscriptionHelper().unfollow(site)
            }.tint(.red)
        }
    }

    private func delete(at offsets: IndexSet) {
        for site in offsets.map(getSubscription) {
            delete(site)
        }
    }

    private func getSubscription(at index: Int) -> ReaderSiteTopic {
        if let searchResults {
            searchResults[index]
        } else {
            subscriptions[index]
        }
    }

    private func delete(_ site: ReaderSiteTopic) {
        ReaderSubscriptionHelper().unfollow(site)
    }

    private func performBackgroundSearch(searchText: String) {
        struct SearchableSubscription: Sendable {
            let objectID: NSManagedObjectID
            let title: String
            let siteURL: String

            var searchableText: String {
                "\(title) \(siteURL)"
            }

            init(_ subscription: ReaderSiteTopic) {
                self.objectID = subscription.objectID
                self.title = subscription.title
                self.siteURL = subscription.siteURL
            }
        }

        // Cancel any existing search task
        searchTask?.cancel()

        // Clear results immediately if search text is empty
        if searchText.isEmpty {
            searchResults = nil
            pendingSearchText = nil
            return
        }

        // Start new background search task
        searchTask = Task {
            // Store the search text we're processing
            let currentSearchText = searchText

            // Create searchable data on main thread to avoid Core Data context issues
            let searchableData = subscriptions.map(SearchableSubscription.init)

            // Perform the search on a background queue with parallel processing
            let resultObjectIDs = await StringRankedSearch(searchTerm: currentSearchText)
                .parallelSearch(in: searchableData) { $0.searchableText }
                .map(\.objectID)

            // Check if we were cancelled or if search text changed during search
            guard !Task.isCancelled else { return }

            // Update results on main thread
            await MainActor.run {
                // Only update if this search is still relevant
                if currentSearchText == searchText {
                    searchResults = subscriptions.filter { resultObjectIDs.contains($0.objectID) }
                    pendingSearchText = nil
                } else {
                    // Search text changed during our search, mark that we need a new search
                    pendingSearchText = searchText
                }

                // If there's a pending search, start it now
                if let pendingSearchText {
                    performBackgroundSearch(searchText: pendingSearchText)
                }
            }
        }
    }
}

private enum Strings {
    static let emptyStateDetails = NSLocalizedString("reader.subscriptions.emptyStateDetails", value: "The sites you discover and subscribe to will appear here", comment: "Empty state details")
}
