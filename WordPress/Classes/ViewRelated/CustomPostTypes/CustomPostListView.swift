import Foundation
import SwiftUI
import UIKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData
import WordPressUI

/// Displays a paginated list of custom posts.
///
/// Used to show posts filtered by status or search results.
struct CustomPostListView<Header: View>: View {
    @ObservedObject var viewModel: CustomPostListViewModel
    let details: PostTypeDetailsWithEditContext
    let client: WordPressClient
    let mediaHost: MediaHost?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    @ViewBuilder let header: () -> Header

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        mediaHost: MediaHost? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void
    ) where Header == EmptyView {
        self.viewModel = viewModel
        self.details = details
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.header = { EmptyView() }
    }

    init(
        viewModel: CustomPostListViewModel,
        details: PostTypeDetailsWithEditContext,
        client: WordPressClient,
        mediaHost: MediaHost? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.viewModel = viewModel
        self.details = details
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.header = header
    }

    var body: some View {
        PaginatedList(
            viewModel: viewModel,
            items: viewModel.items,
            onLoadNextPage: { try await viewModel.loadNextPage() },
            client: client,
            onSelectPost: onSelectPost,
            mediaHost: mediaHost,
            indentationMap: viewModel.indentationMap,
            header: header
        )
        .overlay {
            if viewModel.shouldDisplayEmptyView {
                let emptyText = details.labels.notFound.isEmpty
                    ? String.localizedStringWithFormat(Strings.emptyStateMessage, details.name)
                    : details.labels.notFound
                EmptyStateView(emptyText, systemImage: "doc.text")
            } else if viewModel.shouldDisplayInitialLoading {
                ProgressView()
            } else if let error = viewModel.errorToDisplay() {
                EmptyStateView.failure(error: error)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .progressHUD(state: $viewModel.progressHUDState)
        .task(id: viewModel.filter) {
            await viewModel.loadCachedItems()
            await viewModel.refresh()
        }
        .task(id: viewModel.filter) {
            await viewModel.handleDataChanges()
        }
        .alert(
            Strings.deleteConfirmationTitle,
            isPresented: Binding(
                get: { viewModel.postToDelete != nil },
                set: { if !$0 { viewModel.postToDelete = nil } }
            ),
            presenting: viewModel.postToDelete
        ) { post in
            Button(SharedStrings.Button.cancel, role: .cancel) {}
            Button(Strings.deletePermanently, role: .destructive) {
                Task { await viewModel.deletePost(post) }
            }
        } message: { _ in
            Text(Strings.deleteConfirmationMessage)
        }
        .alert(
            Strings.trashConfirmationTitle,
            isPresented: Binding(
                get: { viewModel.postToTrash != nil },
                set: { if !$0 { viewModel.postToTrash = nil } }
            ),
            presenting: viewModel.postToTrash
        ) { post in
            Button(SharedStrings.Button.cancel, role: .cancel) {}
            Button(Strings.moveToTrash, role: .destructive) {
                Task { await viewModel.trashPost(post) }
            }
        } message: { _ in
            Text(Strings.trashConfirmationMessage)
        }
    }

}

private struct PaginatedList<Header: View>: View {
    let viewModel: CustomPostListViewModel
    let items: [CustomPostCollectionItem]
    let onLoadNextPage: () async throws -> Void
    let client: WordPressClient?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?
    let indentationMap: CustomPostListViewModel.IndentationMap
    @ViewBuilder let header: () -> Header

    @State var isLoadingMore = false
    @State var loadMoreError: Error?

    init(
        viewModel: CustomPostListViewModel,
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        client: WordPressClient? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil,
        indentationMap: CustomPostListViewModel.IndentationMap = [:]
    ) where Header == EmptyView {
        self.viewModel = viewModel
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.indentationMap = indentationMap
        self.header = { EmptyView() }
    }

    init(
        viewModel: CustomPostListViewModel,
        items: [CustomPostCollectionItem],
        onLoadNextPage: @escaping () async throws -> Void,
        client: WordPressClient? = nil,
        onSelectPost: @escaping (AnyPostWithEditContext) -> Void,
        mediaHost: MediaHost? = nil,
        indentationMap: CustomPostListViewModel.IndentationMap = [:],
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.viewModel = viewModel
        self.items = items
        self.onLoadNextPage = onLoadNextPage
        self.client = client
        self.onSelectPost = onSelectPost
        self.mediaHost = mediaHost
        self.indentationMap = indentationMap
        self.header = header
    }

    var body: some View {
        List {
            Section {
                header()
                    .listRowInsets(.zero)
            }
            .listSectionSpacing(0)
            .listSectionSeparator(.hidden)

            if indentationMap.isEmpty {
                flatList
            } else {
                hierarchicalList
            }

            Section {
                makeFooterView()
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private var flatList: some View {
        ForEach(items) { item in
            ForEachContent(
                item: item,
                client: client,
                onSelectPost: onSelectPost,
                mediaHost: mediaHost,
                viewModel: viewModel
            )
            .task {
                await onRowAppear(item: item)
            }
        }
    }

    private var hierarchicalList: some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            ForEachContentWithIndentation(
                item: item,
                client: client,
                onSelectPost: onSelectPost,
                mediaHost: mediaHost,
                viewModel: viewModel,
                indentationLevel: indentationMap[item.id]?.indentationLevel ?? 0,
                showSubdirectoryIcon: showSubdirectoryIcon(at: index)
            )
            .task {
                await onRowAppear(item: item)
            }
        }
    }

    private func showSubdirectoryIcon(at index: Int) -> Bool {
        let item = items[index]
        guard let entry = indentationMap[item.id], entry.indentationLevel > 0, index > 0 else {
            return false
        }
        let previousLevel = indentationMap[items[index - 1].id]?.indentationLevel ?? 0
        return entry.indentationLevel == previousLevel + 1
    }

    private func onRowAppear(item: CustomPostCollectionItem) async {
        if !isLoadingMore, items.suffix(5).contains(where: { $0.id == item.id }) {
            await loadNextPage()
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        self.loadMoreError = nil

        do {
            try await onLoadNextPage()
        } catch {
            DDLogError("Failed to load next page: \(error)")
            self.loadMoreError = error
        }
    }

    @ViewBuilder
    private func makeFooterView() -> some View {
        if isLoadingMore {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                .id(UUID()) // A hack to show the ProgressView after cell reusing.
        } else if let loadMoreError {
            VStack {
                Text(verbatim: loadMoreError.localizedDescription)
                Button {
                    Task { await loadNextPage() }
                } label: {
                    Text(verbatim: SharedStrings.Button.retry)
                }
                .buttonStyle(.borderedProminent)
            }.frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct ForEachContent: View {
    let item: CustomPostCollectionItem
    let client: WordPressClient?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?
    let viewModel: CustomPostListViewModel

    var body: some View {
        switch item {
        case .error(_, let message):
            ErrorRow(message: message)

        case .errorWithData(_, let message, let post):
            VStack(spacing: 4) {
                PostContent(post: post, client: client, mediaHost: mediaHost)
                ErrorRow(message: message)
            }

        case .fetching, .missing, .refreshing:
            PostContent(
                post: CustomPostCollectionDisplayPost(
                    date: Date(),
                    title: "Lorem ipsum dolor sit amet",
                    content: "Lorem ipsum dolor sit amet consectetur adipiscing elit"
                ),
                client: client,
                mediaHost: mediaHost
            )
            .redacted(reason: .placeholder)

        case .ready(_, let displayPost, let post):
            Button {
                onSelectPost(post)
            } label: {
                PostContent(post: displayPost, client: client, mediaHost: mediaHost)
            }
            .buttonStyle(.plain)
            .contextMenu {
                PostActionMenuContent(post: post, viewModel: viewModel)
            }
            .overlay(alignment: .topTrailing) {
                PostActionMenu(post: post, viewModel: viewModel)
                    .offset(y: -6)
            }

        case .stale(_, let post):
            PostContent(post: post, client: client, mediaHost: mediaHost)
        }
    }
}

private struct ForEachContentWithIndentation: View {
    let item: CustomPostCollectionItem
    let client: WordPressClient?
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let mediaHost: MediaHost?
    let viewModel: CustomPostListViewModel
    let indentationLevel: Int
    let showSubdirectoryIcon: Bool

    var body: some View {
        HStack(spacing: 0) {
            if indentationLevel > 0 {
                Image("subdirectory")
                    .foregroundStyle(.secondary)
                    .opacity(showSubdirectoryIcon ? 1 : 0)
                    .padding(.trailing, 8)
            }

            ForEachContent(
                item: item,
                client: client,
                onSelectPost: onSelectPost,
                mediaHost: mediaHost,
                viewModel: viewModel
            )
        }
        .padding(.leading, CGFloat(max(0, indentationLevel - 1)) * 32)
    }
}

private struct PostActionMenu: View {
    let post: AnyPostWithEditContext
    let viewModel: CustomPostListViewModel

    var body: some View {
        Menu {
            PostActionMenuContent(post: post, viewModel: viewModel)
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .tint(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
    }
}

private struct PostActionMenuContent: View {
    let post: AnyPostWithEditContext
    let viewModel: CustomPostListViewModel

    var body: some View {
        primarySection
        navigationSection
        trashSection
    }

    @ViewBuilder
    private var primarySection: some View {
        Section {
            if post.status == .publish {
                Button(action: { viewModel.viewPost(post) }) {
                    Label(SharedStrings.Button.view, systemImage: "safari")
                }
            }

            // FIXME: Preview requires Core Data preview infrastructure (PreviewNonceHandler, AbstractPost)

            if post.status == .draft || post.status == .pending {
                Button(action: { viewModel.publishPost(post) }) {
                    Label(Strings.publish, systemImage: "paperplane")
                }
            }

            if post.status != .draft {
                Button(action: { Task { await viewModel.moveToDraft(post) } }) {
                    Label(Strings.moveToDraft, systemImage: "pencil.line")
                }
            }

            // FIXME: Duplicate requires Core Data editor (Post.blog.createDraftPost, PostListEditorPresenter)

            if post.status == .publish, let url = URL(string: post.link) {
                ShareLink(item: url, subject: Text(post.title?.raw ?? "")) {
                    Label(SharedStrings.Button.share, systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private var navigationSection: some View {
        Section {
            ForEach(viewModel.navigationMenuItems(for: post)) { navigation in
                Button(action: { viewModel.handleMenuNavigation(navigation) }) {
                    Label(navigation.label, systemImage: navigation.systemImage)
                }
            }
        }
    }

    @ViewBuilder
    private var trashSection: some View {
        Section {
            if post.status != .trash {
                Button(role: .destructive, action: {
                    if post.status == .publish {
                        viewModel.confirmTrash(post)
                    } else {
                        Task { await viewModel.trashPost(post) }
                    }
                }) {
                    Label(Strings.moveToTrash, systemImage: "trash")
                }
            } else {
                Button(role: .destructive, action: { viewModel.confirmDelete(post) }) {
                    Label(Strings.deletePermanently, systemImage: "trash.fill")
                }
            }
        }
    }
}

private struct PostContent: View {
    let post: CustomPostCollectionDisplayPost
    let client: WordPressClient?
    let mediaHost: MediaHost?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            content
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var header: some View {
        HStack {
            Text(verbatim: post.headerBadges)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: post.titleForDisplay)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let content = post.content, !content.isEmpty {
                    Text(verbatim: content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if let featuredMedia = post.featuredMedia, let client {
                FeaturedMediaImage(mediaId: featuredMedia, client: client, mediaHost: mediaHost)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let badges = post.statusBadges {
            Text(verbatim: badges)
                .font(.footnote)
                .foregroundStyle(post.statusColor)
        }
    }
}

private struct ErrorRow: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")

            Text(message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.red)
        .padding(.vertical, 4)
    }
}

private enum Strings {
    static let emptyStateMessage = NSLocalizedString(
        "customPostList.emptyState.message",
        value: "No %1$@",
        comment: "Empty state message when no custom posts exist. %1$@ is the post type name (e.g., 'Podcasts', 'Products')."
    )
    static let publish = NSLocalizedString(
        "customPostList.action.publish",
        value: "Publish",
        comment: "Menu action to publish a draft or pending post"
    )
    static let moveToDraft = NSLocalizedString(
        "customPostList.action.moveToDraft",
        value: "Move to Draft",
        comment: "Menu action to change a post's status to draft"
    )
    static let moveToTrash = NSLocalizedString(
        "customPostList.action.moveToTrash",
        value: "Move to Trash",
        comment: "Menu action to move a post to trash"
    )
    static let deletePermanently = NSLocalizedString(
        "customPostList.action.deletePermanently",
        value: "Delete Permanently",
        comment: "Menu action to permanently delete a trashed post"
    )
    static let trashConfirmationTitle = NSLocalizedString(
        "customPostList.trashConfirmation.title",
        value: "Move to Trash?",
        comment: "Title for the confirmation alert when trashing a published post"
    )
    static let trashConfirmationMessage = NSLocalizedString(
        "customPostList.trashConfirmation.message",
        value: "This post is published and visible to visitors. Are you sure you want to move it to trash?",
        comment: "Message for the confirmation alert when trashing a published post"
    )
    static let deleteConfirmationTitle = NSLocalizedString(
        "customPostList.deleteConfirmation.title",
        value: "Delete Permanently?",
        comment: "Title for the confirmation alert when permanently deleting a post"
    )
    static let deleteConfirmationMessage = NSLocalizedString(
        "customPostList.deleteConfirmation.message",
        value: "This action cannot be undone.",
        comment: "Message for the confirmation alert when permanently deleting a post"
    )
}

// MARK: - Previews

#Preview("Status Variants") {
    List {
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now,
                title: "My Draft Post",
                content: "This post is still being worked on.",
                status: .draft
            ),
            client: nil,
            mediaHost: nil
        )
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now.addingTimeInterval(-86400),
                title: "Scheduled for Tomorrow",
                content: "This post will be published automatically.",
                status: .future
            ),
            client: nil,
            mediaHost: nil
        )
        PostContent(
            post: CustomPostCollectionDisplayPost(
                date: .now.addingTimeInterval(-86400 * 7),
                title: "Trashed Post",
                content: "This post was moved to trash.",
                status: .trash
            ),
            client: nil,
            mediaHost: nil
        )
    }
    .listStyle(.plain)
}
