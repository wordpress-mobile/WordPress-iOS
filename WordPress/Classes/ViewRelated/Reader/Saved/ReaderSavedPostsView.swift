import AsyncImageKit
import SwiftUI
import UIKit
import WordPressAPI
import WordPressApiCache
import WordPressCore
import WordPressData
import WordPressShared
import WordPressUI

/// The Reader's Saved screen when saved posts are kept in the WordPress.com account.
final class ReaderSavedPostsViewController: UIHostingController<ReaderSavedPostsView> {
    private let viewModel: ReaderSavedPostsViewModel

    /// Returns `nil` without a WordPress.com account, which is where saved posts are kept.
    @MainActor
    static func makeIfAvailable() -> ReaderSavedPostsViewController? {
        let store = ReaderSavedPostsStore.shared
        guard let service = store.service, let savedPosts = store.savedPosts else { return nil }
        let viewModel = ReaderSavedPostsViewModel(
            service: service,
            collection: savedPosts,
            cacheUpdates: WordPressApiCache.shared.databaseUpdatesPublisher(),
            presentError: { message in
                ActionDispatcherFacade().dispatch(NoticeAction.post(Notice(title: message, feedbackType: .error)))
            }
        )
        return ReaderSavedPostsViewController(viewModel: viewModel)
    }

    init(viewModel: ReaderSavedPostsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReaderSavedPostsView(viewModel: viewModel, onOpen: { _ in }))
        rootView = ReaderSavedPostsView(viewModel: viewModel) { [weak self] row in
            self?.open(row)
        }
        title = SharedStrings.Reader.saved
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let settingsButton = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "ellipsis"),
            primaryAction: UIAction { [weak self] _ in
                let settingsVC = UIHostingController(rootView: ReaderSavedPostsSettingsView())
                self?.navigationController?.pushViewController(settingsVC, animated: true)
            }
        )
        settingsButton.accessibilityLabel = Strings.settingsAccessibilityLabel
        navigationItem.rightBarButtonItem = settingsButton

        WPAnalytics.trackReader(
            .readerSavedListShown,
            properties: ["source": ReaderSaveForLaterOrigin.readerMenu.viewAllPostsValue]
        )
    }

    private func open(_ row: ReaderSavedPostRow) {
        WPAppAnalytics.track(
            .readerSavedPostOpened,
            withProperties: ["source": ReaderSaveForLaterOrigin.savedStream.openPostValue]
        )

        switch row.destination {
        case let .post(postID, siteID):
            let controller = ReaderDetailViewController.controllerWithPostID(
                NSNumber(value: postID),
                siteID: NSNumber(value: siteID)
            )
            navigationController?.pushViewController(controller, animated: true)
        case let .feedItem(feedItemID, feedID):
            let controller = ReaderDetailViewController.controllerWithPostID(
                NSNumber(value: feedItemID),
                siteID: NSNumber(value: feedID),
                isFeed: true
            )
            navigationController?.pushViewController(controller, animated: true)
        case let .url(url):
            let configuration = WebViewControllerConfiguration(url: url)
            configuration.authenticateWithDefaultAccount()
            configuration.addsWPComReferrer = true
            let controller = WebViewControllerFactory.controller(
                configuration: configuration,
                source: "reader_saved_posts"
            )
            present(UINavigationController(rootViewController: controller), animated: true)
        case nil:
            break
        }
    }
}

struct ReaderSavedPostsView: View {
    @ObservedObject var viewModel: ReaderSavedPostsViewModel
    let onOpen: (ReaderSavedPostRow) -> Void

    var body: some View {
        List {
            ForEach(viewModel.rows) { row in
                ReaderSavedPostRowView(row: row, onOpen: onOpen, onUnsave: unsave)
                    .task { await viewModel.loadMoreIfNeeded(after: row) }
            }
            if viewModel.hasMore {
                loadingMoreRow
            }
        }
        .listStyle(.plain)
        .overlay { overlay }
        .refreshable { await viewModel.pullToRefresh() }
        .task { await viewModel.onAppear() }
    }

    private var loadingMoreRow: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .task { await viewModel.loadMore() }
    }

    @ViewBuilder
    private var overlay: some View {
        if viewModel.rows.isEmpty {
            if !viewModel.hasLoaded || (viewModel.isRefreshing && viewModel.errorMessage == nil) {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                emptyView
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label(Strings.emptyTitle, systemImage: "bookmark")
        } description: {
            Text(Strings.emptyDescription)
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label(Strings.errorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button(SharedStrings.Button.retry) {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func unsave(_ row: ReaderSavedPostRow) {
        Task { await viewModel.unsave(row) }
    }
}

private struct ReaderSavedPostRowView: View {
    let row: ReaderSavedPostRow
    let onOpen: (ReaderSavedPostRow) -> Void
    let onUnsave: (ReaderSavedPostRow) -> Void

    var body: some View {
        Button {
            onOpen(row)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                details
                Spacer(minLength: 0)
                if let imageURL = row.featuredImageURL {
                    thumbnail(imageURL)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(row.destination == nil)
        .swipeActions(edge: .trailing) {
            unsaveButton
        }
        .contextMenu {
            unsaveButton
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: Strings.unsave) {
            onUnsave(row)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let siteName = row.siteName {
                Text(siteName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(row.title)
                .font(.headline)
                .lineLimit(3)
            if let excerpt = row.excerpt {
                Text(excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// The author and when the post was saved.
    private var footnote: String? {
        let saved = row.dateSaved.map {
            String.localizedStringWithFormat(Strings.savedDate, $0.formatted(date: .abbreviated, time: .omitted))
        }
        let parts = [row.authorName, saved].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func thumbnail(_ url: URL) -> some View {
        CachedAsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var unsaveButton: some View {
        Button(role: .destructive) {
            onUnsave(row)
        } label: {
            Label(Strings.unsave, systemImage: "bookmark.slash")
        }
    }
}

private enum Strings {
    static let emptyTitle = NSLocalizedString(
        "reader.savedPosts.empty.title",
        value: "No saved posts",
        comment: "Title shown in Reader's Saved screen when the user hasn't saved any posts."
    )
    static let emptyDescription = NSLocalizedString(
        "reader.savedPosts.empty.description",
        value: "Tap the bookmark icon on a post to save it to your list.",
        comment: "Hint shown in Reader's Saved screen when the user hasn't saved any posts."
    )
    static let errorTitle = NSLocalizedString(
        "reader.savedPosts.error.title",
        value: "Couldn't load your saved posts",
        comment: "Title shown in Reader's Saved screen when the saved posts couldn't be loaded."
    )
    static let unsave = NSLocalizedString(
        "reader.savedPosts.unsave.button",
        value: "Remove",
        comment: "Button that removes a post from Reader's Saved screen."
    )
    static let savedDate = NSLocalizedString(
        "reader.savedPosts.row.savedDate",
        value: "Saved %1$@",
        comment: "When a post was saved, in Reader's Saved screen. %1$@ is a date, such as 'Nov 9, 2026'."
    )
    static let settingsAccessibilityLabel = NSLocalizedString(
        "reader.savedPosts.settings.button.accessibilityLabel",
        value: "Saved posts settings",
        comment: "Accessibility label for the button that opens saved Reader posts import and export settings"
    )
}
