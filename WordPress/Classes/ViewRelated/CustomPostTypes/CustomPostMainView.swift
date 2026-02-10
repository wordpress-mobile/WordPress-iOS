import Foundation
import SwiftUI
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressUI
import WordPressData

/// The top-level screen for browsing custom posts of a specific type.
///
/// Provides search, status filtering, and navigation to the post editor.
struct CustomPostMainView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    let blog: Blog

    @State private var filter = CustomPostListFilter.default
    @State private var searchText = ""
    @State private var selectedPost: AnyPostWithEditContext?
    @State private var filteredViewModel: CustomPostListViewModel

    init(
        client: WordPressClient,
        service: WpSelfHostedService,
        endpoint: PostEndpointType,
        details: PostTypeDetailsWithEditContext,
        blog: Blog
    ) {
        self.client = client
        self.service = service
        self.endpoint = endpoint
        self.details = details
        self.blog = blog

        _filteredViewModel = State(initialValue: CustomPostListViewModel(
            client: client,
            service: service,
            endpoint: endpoint,
            filter: .default
        ))
    }

    private var isFiltered: Bool {
        filter.status != .custom("any")
    }

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                CustomPostListView(
                    viewModel: filteredViewModel,
                    details: details,
                    onSelectPost: { selectedPost = $0 }
                )
            } else {
                CustomPostSearchResultView(
                    client: client,
                    service: service,
                    endpoint: endpoint,
                    details: details,
                    searchText: $searchText,
                    onSelectPost: { selectedPost = $0 }
                )
            }
        }
        .onChange(of: filter) {
            filteredViewModel = CustomPostListViewModel(
                client: client,
                service: service,
                endpoint: endpoint,
                filter: filter
            )
        }
        .searchable(text: $searchText)
        .fullScreenCover(item: $selectedPost) { post in
            // TODO: Check if the post supports Gutenberg first?
            CustomPostEditor(client: client, post: post, details: details, blog: blog) {
                Task {
                    _ = try await service.posts().refreshPost(postId: post.id, endpointType: endpoint)
                }
            }
        }
        .navigationTitle(details.labels.itemsList)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("", selection: $filter.status) {
                Text(Strings.filterAll).tag(PostStatus.custom("any"))
                Text(Strings.filterPublished).tag(PostStatus.publish)
                Text(Strings.filterDraft).tag(PostStatus.draft)
                Text(Strings.filterScheduled).tag(PostStatus.future)
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
        .foregroundStyle(isFiltered ? Color.white : .primary)
        .background {
            if isFiltered {
                Circle()
                    .fill(Color.accentColor)
            }
        }
    }
}

private struct CustomPostSearchResultView: View {
    let client: WordPressClient
    let service: WpSelfHostedService
    let endpoint: PostEndpointType
    let details: PostTypeDetailsWithEditContext
    @Binding var searchText: String
    let onSelectPost: (AnyPostWithEditContext) -> Void

    @State private var finalSearchText = ""

    var body: some View {
        CustomPostListView(
            viewModel: CustomPostListViewModel(
                client: client,
                service: service,
                endpoint: endpoint,
                filter: CustomPostListFilter.default.with(search: finalSearchText)
            ),
            details: details,
            onSelectPost: onSelectPost
        )
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(100))
                finalSearchText = searchText
            } catch {
                // Do nothing.
            }
        }
    }
}

private enum Strings {
    static let sortByDateCreated = NSLocalizedString(
        "postList.menu.sortByDateCreated",
        value: "Sort by Date Created",
        comment: "Menu item to sort posts by creation date"
    )
    static let sortByDateModified = NSLocalizedString(
        "postList.menu.sortByDateModified",
        value: "Sort by Date Modified",
        comment: "Menu item to sort posts by modification date"
    )
    static let filter = NSLocalizedString(
        "postList.menu.filter",
        value: "Filter",
        comment: "Menu item to access filter options"
    )
    static let filterAll = NSLocalizedString(
        "postList.menu.filter.all",
        value: "All",
        comment: "Filter option to show all posts"
    )
    static let filterPublished = NSLocalizedString(
        "postList.menu.filter.published",
        value: "Published",
        comment: "Filter option to show only published posts"
    )
    static let filterDraft = NSLocalizedString(
        "postList.menu.filter.draft",
        value: "Draft",
        comment: "Filter option to show only draft posts"
    )
    static let filterScheduled = NSLocalizedString(
        "postList.menu.filter.scheduled",
        value: "Scheduled",
        comment: "Filter option to show only scheduled posts"
    )
}
