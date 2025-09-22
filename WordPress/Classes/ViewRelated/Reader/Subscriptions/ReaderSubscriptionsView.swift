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

    @State private var isShowingMainAddSubscriptonPopover = false

    @State private var searchText = ""
    @State private var pendingSearchText: String?
    @State private var searchResults: [ReaderSiteTopic]?
    @State private var searchTask: Task<Void, Never>?

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
        guard !searchText.isEmpty else {
            searchResults = nil
            pendingSearchText = nil
            searchTask?.cancel()
            return
        }

        guard searchTask == nil else {
            pendingSearchText = searchText
            return
        }

        searchTask = Task { [searchText] in
            await performSearch(for: searchText)
        }
    }

    private func performSearch(for searchText: String) async {
        let searchableData = subscriptions.map(SearchableSubscription.init)

        let resultObjectIDs = Set(await StringRankedSearch(searchTerm: searchText)
            .parallelSearch(in: searchableData) { $0.searchableText }
            .map(\.objectID))

        searchResults = subscriptions.filter { resultObjectIDs.contains($0.objectID) }

        guard !Task.isCancelled else { return }

        searchTask = nil

        if let pendingSearchText {
            self.pendingSearchText = nil
            performBackgroundSearch(searchText: pendingSearchText)
        }
    }
}

private struct SearchableSubscription: Sendable {
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

private enum Strings {
    static let emptyStateDetails = NSLocalizedString("reader.subscriptions.emptyStateDetails", value: "The sites you discover and subscribe to will appear here", comment: "Empty state details")
}
