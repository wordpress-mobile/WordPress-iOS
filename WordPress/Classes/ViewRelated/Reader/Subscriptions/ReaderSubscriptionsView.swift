import SwiftUI
import WordPressUI

struct ReaderSubscriptionsView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    @State private var searchText = ""
    @State private var isShowingMainAddSubscriptonPopover = false

    @State private var searchResults: [ReaderSiteTopic] = []

    @StateObject private var viewModel = ReaderSubscriptionsViewModel()

    var isShowingSearchResuts: Bool { !searchText.isEmpty }

    var onSelection: (_ subscription: ReaderSiteTopic) -> Void = { _ in }

    var body: some View {
        Group {
            if subscriptions.isEmpty {
                GeometryReader { proxy in
                    ScrollView { // Make it compatible with refreshable()
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
            ReaderAddSubscriptionButton(style: .navigation)
            if !subscriptions.isEmpty {
                EditButton()
            }
        }
        .navigationTitle(Strings.title)
        .tint(Color(UIAppColor.primary))
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
            Label(Strings.title, systemImage: "doc.text.magnifyingglass")
        } description: {
            Text(Strings.emptyStateDetails)
        } actions: {
            ReaderAddSubscriptionButton(style: .compact)
        }
    }

    private var main: some View {
        List {
            if !isShowingSearchResuts {
                ReaderAddSubscriptionButton(style: .expanded)
                    .listRowSeparator(.hidden)
                ForEach(subscriptions, id: \.objectID, content: makeSubscriptionCell)
                    .onDelete(perform: delete)
            } else {
                ForEach(searchResults, id: \.objectID, content: makeSubscriptionCell)
                    .onDelete(perform: delete)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText)
        .onReceive(subscriptions.publisher) { _ in
            if !searchText.isEmpty {
                reloadSearchResults(searchText: searchText)
            }
        }
        .onChange(of: searchText) {
            reloadSearchResults(searchText: $0)
        }
    }

    private func makeSubscriptionCell(for site: ReaderSiteTopic) -> some View {
        Button {
            onSelection(site)
        } label: {
            ReaderSubscriptionCell(site: site, onDelete: delete)
        }
    }

    private func delete(at offsets: IndexSet) {
        for site in offsets.map(getSubscription) {
            delete(site)
        }
    }

    private func getSubscription(at index: Int) -> ReaderSiteTopic {
        if isShowingSearchResuts {
            searchResults[index]
        } else {
            subscriptions[index]
        }
    }

    private func delete(_ site: ReaderSiteTopic) {
        ReaderSubscriptionHelper.unfollow(site)
    }

    private func reloadSearchResults(searchText: String) {
        let ranking = StringRankedSearch(searchTerm: searchText)
        searchResults = ranking.search(in: subscriptions) { "\($0.title) \($0.siteURL)" }
    }
}

enum ReaderSubscriptionHelper {
    static func unfollow(_ site: ReaderSiteTopic, in context: CoreDataStackSwift = ContextManager.shared) {
        NotificationCenter.default.post(name: .ReaderTopicUnfollowed, object: nil, userInfo: [ReaderNotificationKeys.topic: site])

        let service = ReaderTopicService(coreDataStack: context)
        service.toggleFollowing(forSite: site, success: { _ in
            // Do nothing
        }, failure: { _, error in
            DDLogError("Could not unfollow site: \(String(describing: error))")
            Notice(title: ReaderFollowedSitesViewController.Strings.failedToUnfollow, message: error?.localizedDescription, feedbackType: .error).post()
        })
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.subscriptions.title", value: "Subscriptions", comment: "Navigation bar title")
    static let emptyStateDetails = NSLocalizedString("reader.subscriptions.emptyStateDetails", value: "The sites you discover and subscribe to will appear here", comment: "Empty state details")
}
