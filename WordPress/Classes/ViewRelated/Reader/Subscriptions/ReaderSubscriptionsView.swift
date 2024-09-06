import SwiftUI
import WordPressUI

struct ReaderSubscriptionsView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: NSPredicate(format: "following = YES")
    )
    private var subscriptions: FetchedResults<ReaderSiteTopic>

    @State private var searchText = ""
    @State private var isAddingSubscription = false

    @State private var searchResults: [ReaderSiteTopic] = []

    @StateObject private var viewModel = ReaderSubscriptionsViewModel()

    var isShowingSearchResuts: Bool { !searchText.isEmpty }

    var onSelection: (_ subscription: ReaderSiteTopic) -> Void = { _ in }

    private var visibleSubscriptions: any RandomAccessCollection<ReaderSiteTopic> {
        if searchText.isEmpty {
            return subscriptions
        } else {
            return searchResults
        }
    }

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
        .navigationTitle(Strings.title)
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
            buttonAddSubscription
                .fixedSize(horizontal: true, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 8, trailing: 10))
                .background(Color(.secondarySystemBackground).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var main: some View {
        List {
            if !isShowingSearchResuts {
                buttonAddSubscription
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
        .toolbar {
            EditButton()
        }
    }

    private func makeSubscriptionCell(for site: ReaderSiteTopic) -> some View {
        Button {
            onSelection(site)
        } label: {
            ReaderSubscriptionCell(site: site, onDelete: delete)
        }
    }

    private var buttonAddSubscription: some View {
        Button {
            isAddingSubscription = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppColor.brand, Color(.secondarySystemFill))
                    .font(.largeTitle.weight(.light))
                    .frame(width: 40)
                    .padding(.leading, 4)
                VStack(alignment: .leading) {
                    Text(Strings.addSubscription)
                        .font(.callout.weight(.medium))
                    Text(Strings.addSubscriptionSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isAddingSubscription) {
            ReaderAddSubscriptionView()
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

private struct ReaderAddSubscriptionView: View {
    @State private var url = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls
            Text(Strings.addSubscriptionSubtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("", text: $url, prompt: Text(verbatim: "example.com"))
                .keyboardType(.URL)
                .textContentType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .labelsHidden()
                .padding(.top, 12)
        }
        .padding()
        .onAppear {
            isFocused = true
        }
        .frame(width: 420)
        .interactiveDismissDisabled(!url.isEmpty)
    }

    private var controls: some View {
        HStack {
            Button(SharedStrings.Button.cancel) {
                dismiss()
            }
            Spacer()
            Text(Strings.addSubscription)
                .font(.headline)
            Spacer()
            Button(SharedStrings.Button.add) {
                // TODO: implement
            }
            .disabled(url.isEmpty)
            .font(.headline)
        }
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
    static let addSubscription = NSLocalizedString("reader.subscriptions.addSubscriptionButtonTitle", value: "Add Subscription", comment: "Button title")
    static let addSubscriptionSubtitle = NSLocalizedString("reader.subscriptions.addSubscriptionButtonSubtitle", value: "Subscribe to sites, newsletters, or RSS feeds", comment: "Button subtitle")
    static let emptyStateDetails = NSLocalizedString("reader.subscriptions.emptyStateDetails", value: "The sites you discover and subscribe to will appear here", comment: "Empty state details")
}
