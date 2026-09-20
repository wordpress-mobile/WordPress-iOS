import AsyncImageKit
import DesignSystem
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// One post of the redesigned list, drawn as a card.
///
/// Every post with a featured image takes the image-led "hero" shape; the rest
/// let the text span the full card. Which shape a row takes is decided from
/// the shared media cache, so rows do not pop from compact to hero as their
/// images resolve.
struct CustomPostCardRow: View {
    let item: CustomPostCollectionItem
    let configuration: CustomPostCardConfiguration
    let mediaHost: MediaHost?
    @ObservedObject var viewModel: CustomPostListViewModel
    let onSelectPost: (AnyPostWithEditContext) -> Void
    let onDuplicate: (AnyPostWithEditContext) -> Void

    var body: some View {
        switch item.state {
        case .loading:
            CustomPostCardPlaceholder(density: configuration.density)
        case .error(let message):
            if let post = item.post {
                CardContainer { card(for: post, syncError: message, menu: EmptyView()) }
            } else {
                CardContainer { ErrorRow(message: message) }
            }
        case .loaded(let fullPost, _):
            if let post = item.post {
                loadedCard(post: post, fullPost: fullPost)
            }
        }
    }

    @ViewBuilder
    private func loadedCard(post: CustomPostCollectionDisplayPost, fullPost: AnyPostWithEditContext) -> some View {
        let isPending = viewModel.pendingPostIDs.contains(item.id)
        // Not a Button: the overflow menu lives inside the card, and a control
        // nested in a button's label does not reliably get the tap in a List.
        let row = CardContainer {
            card(
                for: post,
                syncError: nil,
                menu: PostActionMenu(
                    post: fullPost,
                    pageRole: item.pageRole,
                    viewModel: viewModel,
                    onDuplicate: onDuplicate
                )
            )
        }
        .onTapGesture {
            onSelectPost(fullPost)
        }
        .onAppear {
            configuration.metricsStore?.rowDidAppear(item.id)
        }
        .onDisappear {
            configuration.metricsStore?.rowDidDisappear(item.id)
        }

        if isPending {
            row
                .overlay(alignment: .topTrailing) {
                    ProgressView()
                        .padding(12)
                }
                .opacity(0.4)
                .disabled(true)
        } else {
            row.postRowActions(
                post: fullPost,
                pageRole: item.pageRole,
                viewModel: viewModel,
                onDuplicate: onDuplicate
            )
        }
    }

    /// Draws the card once its featured image state is known. A post with an
    /// image resolves it from here rather than from the loaded row, so a row
    /// showing cached data behind a sync error resolves its image too.
    @ViewBuilder
    private func card<Menu: View>(
        for post: CustomPostCollectionDisplayPost,
        syncError: String?,
        menu: Menu
    ) -> some View {
        if let mediaId = post.featuredMedia {
            MediaResolvingCard(
                cache: configuration.mediaCache,
                mediaId: mediaId,
                entry: configuration.mediaCache.entry(for: mediaId)
            ) { imageState in
                cardBody(for: post, syncError: syncError, imageState: imageState, menu: menu)
            }
        } else {
            cardBody(for: post, syncError: syncError, imageState: .unresolvable, menu: menu)
        }
    }

    @ViewBuilder
    private func cardBody<Menu: View>(
        for post: CustomPostCollectionDisplayPost,
        syncError: String?,
        imageState: FeaturedMediaURLCache.State,
        menu: Menu
    ) -> some View {
        let isHero = !configuration.density.isCondensed && imageState != .unresolvable
        let padding: CGFloat = configuration.density.isCondensed ? 12 : 14

        if isHero {
            VStack(spacing: 0) {
                CardImage(state: imageState, mediaHost: mediaHost)
                    .frame(height: 130)
                    .transition(.opacity)
                HStack(alignment: .center, spacing: 0) {
                    CardTextColumn(
                        postID: item.id,
                        post: post,
                        configuration: configuration,
                        syncError: syncError,
                        isHero: true
                    )
                    menu
                }
                .padding(padding)
            }
        } else {
            HStack(alignment: .center, spacing: 0) {
                CardTextColumn(
                    postID: item.id,
                    post: post,
                    configuration: configuration,
                    syncError: syncError,
                    isHero: false
                )
                if imageState != .unresolvable {
                    let size: CGFloat = configuration.density.isCondensed ? 56 : 72
                    CardImage(state: imageState, mediaHost: mediaHost)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.leading, padding)
                        .transition(.opacity)
                }
                menu
            }
            .padding(padding)
        }
    }
}

/// Starts this row's featured image lookup and hands its state to the card.
/// Observing the one entry rather than the whole cache keeps an image landing
/// from invalidating every other row in the list.
private struct MediaResolvingCard<Content: View>: View {
    let cache: FeaturedMediaURLCache
    let mediaId: MediaId
    @ObservedObject var entry: FeaturedMediaURLCache.Entry
    @ViewBuilder let content: (FeaturedMediaURLCache.State) -> Content

    var body: some View {
        content(entry.state)
            .onAppear {
                cache.mediaDidAppear(mediaId)
            }
            .onDisappear {
                cache.mediaDidDisappear(mediaId)
            }
    }
}

/// Section header separating the date buckets, e.g. "THIS WEEK".
struct CustomPostDateGroupHeader: View {
    let group: CustomPostDateGroup

    var body: some View {
        Text(group.localizedTitle.uppercased(with: .current))
            .font(.caption.weight(.bold))
            .kerning(1.3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.top, 16)
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Loading placeholder shaped like a compact card so the list does not jump
/// when data lands.
struct CustomPostCardPlaceholder: View {
    let density: CustomPostListDensity

    var body: some View {
        CardContainer {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBar()
                        .frame(width: 200, height: 20)
                    if !density.isCondensed {
                        ShimmerBar()
                            .frame(maxWidth: .infinity)
                            .frame(height: 13)
                        ShimmerBar()
                            .frame(maxWidth: .infinity)
                            .frame(height: 13)
                    }
                    ShimmerBar()
                        .frame(width: 120, height: 13)
                }
                ShimmerBar(cornerRadius: 10)
                    .frame(width: 72, height: 72)
            }
            .padding(14)
        }
    }
}

// MARK: - Building blocks

private struct CardContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            }
            .contentShape(Rectangle())
    }
}

/// The row's featured image at whatever size the caller gives it. Shimmers
/// while the URL is still being resolved.
private struct CardImage: View {
    let state: FeaturedMediaURLCache.State
    let mediaHost: MediaHost?

    var body: some View {
        // Drawn as an overlay on a clear base so a filled image takes the
        // frame the caller gives it rather than proposing its own size.
        Color.clear
            .overlay {
                switch state {
                case .resolved(let url):
                    CachedAsyncImage(url: url, host: mediaHost) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ShimmerBar(cornerRadius: 0)
                    }
                case .pending:
                    ShimmerBar(cornerRadius: 0)
                case .unresolvable:
                    EmptyView()
                }
            }
            .clipped()
    }
}

/// The text stack shared by both row shapes: badges, title, excerpt, then the
/// metadata line. Condensed drops the excerpt, which is what actually
/// shortens the row, and the metrics, which are then not fetched either.
private struct CardTextColumn: View {
    let postID: Int64
    let post: CustomPostCollectionDisplayPost
    let configuration: CustomPostCardConfiguration
    let syncError: String?
    let isHero: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            badges
            Text(post.titleForDisplay)
                .font(
                    Font.make(
                        .recoleta,
                        size: isHero ? 21 : 19,
                        weight: .semibold,
                        relativeTo: isHero ? .title2 : .title3
                    )
                )
                .lineSpacing(2)
                .foregroundStyle(.primary)
                .lineLimit(2)
            if !configuration.density.isCondensed, let excerpt = post.content, !excerpt.isEmpty {
                Text(excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .transition(.opacity)
            }
            metaLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The density toggle is animated by its caller; this keeps the row animating even when
        // the change reaches it outside that transaction, e.g. through the List's diffing.
        .animation(.easeInOut(duration: 0.3), value: configuration.density)
        // One element per card, like the classic row, so VoiceOver reads the
        // whole post at once and the overflow menu stays separately reachable.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var badges: some View {
        let items = post.statusBadgeItems
        if !items.isEmpty {
            HStack(spacing: 4) {
                ForEach(items, id: \.self) { badge in
                    Text(badge)
                        .font(.caption2)
                        .foregroundStyle(post.statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(post.statusColor.opacity(0.5), lineWidth: 1)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        // Dated on the published date, the same field the list is grouped by,
        // so a row never contradicts the header it sits under.
        let dateLabel = post.cardDateBadges
        if let store = configuration.metricsStore, !configuration.density.isCondensed {
            ObservedMetaLine(store: store, postID: postID, dateLabel: dateLabel, syncError: syncError)
        } else {
            MetaLine(dateLabel: dateLabel, metrics: nil, syncError: syncError)
        }
    }
}

/// Wraps `MetaLine` so the row re-renders when its metrics land.
private struct ObservedMetaLine: View {
    @ObservedObject var store: CustomPostMetricsStore
    let postID: Int64
    let dateLabel: String
    let syncError: String?

    var body: some View {
        MetaLine(dateLabel: dateLabel, metrics: store.metrics(for: postID), syncError: syncError)
    }
}

/// "2d ago · 1,204 views · 8 comments", or a single bar standing in for both
/// metrics while they are still being fetched.
private struct MetaLine: View {
    let dateLabel: String
    let metrics: CustomPostRowMetrics?
    let syncError: String?

    var body: some View {
        HStack(spacing: 4) {
            metaText(dateLabel)
            if let metrics {
                if metrics.isPending {
                    separator
                    ShimmerBar()
                        .frame(width: 132, height: 11)
                } else {
                    if case .loaded(let views) = metrics.viewCount {
                        separator
                        metaText(Strings.views(views))
                    }
                    if case .loaded(let comments) = metrics.commentCount {
                        separator
                        metaText(Strings.comments(comments))
                    }
                }
            }
            if syncError != nil {
                separator
                metaText(Strings.syncFailed, color: .red)
            }
        }
        .font(.footnote)
    }

    private func metaText(_ text: String, color: Color = .secondary) -> some View {
        Text(text)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var separator: some View {
        Text(verbatim: "·")
            .foregroundStyle(.tertiary)
    }
}

private enum Strings {
    static func views(_ count: Int) -> String {
        String.localizedStringWithFormat(count == 1 ? viewSingular : viewPlural, count.formatted(.number))
    }

    static func comments(_ count: Int) -> String {
        String.localizedStringWithFormat(count == 1 ? commentSingular : commentPlural, count.formatted(.number))
    }

    static let viewSingular = NSLocalizedString(
        "customPostList.metrics.views.singular",
        value: "%1$@ view",
        comment: "View count shown on a row of the posts list (singular). %1$@ is the formatted number."
    )
    static let viewPlural = NSLocalizedString(
        "customPostList.metrics.views.plural",
        value: "%1$@ views",
        comment: "View count shown on a row of the posts list (plural). %1$@ is the formatted number."
    )
    static let commentSingular = NSLocalizedString(
        "customPostList.metrics.comments.singular",
        value: "%1$@ comment",
        comment: "Comment count shown on a row of the posts list (singular). %1$@ is the formatted number."
    )
    static let commentPlural = NSLocalizedString(
        "customPostList.metrics.comments.plural",
        value: "%1$@ comments",
        comment: "Comment count shown on a row of the posts list (plural). %1$@ is the formatted number."
    )
    static let syncFailed = NSLocalizedString(
        "customPostList.metrics.syncFailed",
        value: "Sync failed",
        comment: "Shown on a row of the posts list when the post could not be refreshed from the site"
    )
}
