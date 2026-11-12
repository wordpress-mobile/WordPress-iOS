import SwiftUI
import UIKit

/// The fixed-region comment detail and moderation screen: a pinned status pill
/// and author header, an optional "In reply to" strip, the internally
/// scrolling content region, and a pinned bottom moderation toolbar hosted via
/// `.safeAreaInset(edge: .bottom)` (never `.toolbar(placement: .bottomBar)`,
/// which does not render in a UIKit-hosted `UIHostingController`). In compact
/// height, accessibility text sizes use the navigation menu for moderation.
struct CommentDetailView: View {
    @StateObject private var viewModel: CommentDetailViewModel
    @ObservedObject private var titleResolver: PostTitleResolver

    private let router: CommentsDetailRouter
    @StateObject private var contentRenderer: ContentRenderer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(commentID: Int64, seed: CommentListItem?, router: CommentsDetailRouter) {
        self.router = router
        _viewModel = StateObject(wrappedValue: router.makeViewModel(id: commentID, seed: seed))
        titleResolver = router.titleResolver
        _contentRenderer = StateObject(wrappedValue: ContentRenderer(router: router))
    }

    @MainActor
    private final class ContentRenderer: ObservableObject {
        let renderer: any CommentContentRendering

        init(router: CommentsDetailRouter) {
            renderer = router.makeRenderer()
        }
    }

    var body: some View {
        CommentDetailBody(
            viewModel: viewModel,
            titleResolver: titleResolver,
            renderer: contentRenderer.renderer,
            parentDestination: { CommentDetailView(commentID: $0.id, seed: $0, router: router) },
            retry: { Task { await viewModel.retry() } }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomToolbar }
        .toolbar { trailingToolbarItems }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        // The comment no longer exists, so there is nothing left to show.
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            if isDeleted { dismiss() }
        }
        .sheet(item: $viewModel.composer) { composer in
            CommentComposerView(viewModel: composer) { viewModel.composerClosed($0) }
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var bottomToolbar: some View {
        let model = viewModel.toolbarModel
        if model != .hidden && !usesModerationMenu {
            CommentModerationToolbar(
                model: model,
                isEnabled: viewModel.isToolbarEnabled,
                pendingAction: viewModel.pendingAction,
                trashConfirmation: viewModel.trashConfirmation
            ) { action in
                viewModel.perform(action)
            }
        }
    }

    private var usesModerationMenu: Bool {
        verticalSizeClass == .compact && dynamicTypeSize.isAccessibilitySize
    }

    @ToolbarContentBuilder
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.showsReply {
                Button(Strings.detailReply, systemImage: "arrowshape.turn.up.left") {
                    viewModel.replyTapped()
                }
                .disabled(!viewModel.canReply)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            let shareLink = viewModel.shareLink
            let menuAction = viewModel.toolbarModel.menuAction
            let moderationModel = usesModerationMenu ? viewModel.toolbarModel : .hidden
            if viewModel.showsEdit || shareLink != nil || menuAction != nil || moderationModel != .hidden {
                CommentModerationMenu(
                    model: moderationModel,
                    isEnabled: viewModel.isToolbarEnabled,
                    isPerformingAction: usesModerationMenu && viewModel.pendingAction != nil,
                    trashConfirmation: viewModel.trashConfirmation,
                    perform: { viewModel.perform($0) }
                ) {
                    if viewModel.showsEdit {
                        Button(Strings.detailEdit, systemImage: "pencil") { viewModel.editTapped() }
                            .disabled(!viewModel.canEdit)
                    }
                    if let shareLink {
                        ShareLink(item: shareLink)
                    }
                    // The secondary moderation move shares the toolbar's
                    // enablement so it can't fire on seed data or during a
                    // mutation.
                    if let menuAction {
                        Section {
                            Button(menuAction.title, systemImage: menuAction.systemImage, role: menuAction.role) {
                                viewModel.perform(menuAction)
                            }
                            .disabled(!viewModel.isToolbarEnabled)
                        }
                    }
                }
            }
        }
    }
}

/// The fixed regions every detail presentation shares: the status pill and
/// author header, the optional "In reply to" strip, and the content region.
/// The ordinary screen and the review sheet add their own toolbars and
/// lifecycle around it.
struct CommentDetailBody: View {
    @ObservedObject var viewModel: CommentDetailViewModel
    @ObservedObject var titleResolver: PostTitleResolver
    let renderer: any CommentContentRendering
    /// Review sessions leave parent context unlinked.
    var parentDestination: ((CommentListItem) -> CommentDetailView)?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let header = viewModel.header {
                VStack(alignment: .leading, spacing: 12) {
                    CommentStatusPill(status: header.status)
                    CommentAuthorHeader(
                        header: header,
                        titleState: titleResolver.titleState(for: header.postID),
                        detail: viewModel.loadedDetail
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            if let parent = viewModel.parentPreview {
                Divider()
                parentStrip(parent)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            Divider()
            contentRegion
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func parentStrip(_ parent: CommentListItem) -> some View {
        if let parentDestination {
            NavigationLink {
                parentDestination(parent)
            } label: {
                CommentParentStrip(parent: parent, showsDisclosureIndicator: true)
            }
            .buttonStyle(.plain)
        } else {
            CommentParentStrip(parent: parent)
        }
    }

    @ViewBuilder
    private var contentRegion: some View {
        switch viewModel.content {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            ContentUnavailableView {
                Label(Strings.detailErrorTitle, systemImage: "exclamationmark.triangle")
            } actions: {
                Button(Strings.errorRetry, action: retry)
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let detail):
            CommentContentRegion(renderer: renderer, html: detail.contentHTML)
        }
    }
}

#if DEBUG
/// Renders comment HTML as plain text inside a scroll view. Stands in for the
/// production WebKit-backed renderer so the preview stays self-contained.
private final class StubContentRenderer: NSObject, CommentContentRendering {
    let scrollView = UIScrollView()
    private let label = UILabel()

    var view: UIView { scrollView }
    var onLinkTapped: ((URL) -> Void)?

    override init() {
        super.init()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            label.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    func render(html: String) {
        label.text = html.makePlainText()
    }
}

private struct PreviewNoticePresenter: NoticePresenting {
    func present(title: String) {}
}

#Preview {
    let service = PreviewCommentsService(fetchedStatus: .pending, numberOfReplies: 2)
    let coordinator = CommentsModerationCoordinator(service: service)
    let titleResolver = PostTitleResolver(fetcher: { _ in
        PostTitleResolver.FetchResult(titles: [10: "Reviewing the 2027 Upgrade"])
    })
    let router = CommentsDetailRouter(
        service: service,
        capabilities: PreviewCapabilities(),
        coordinator: coordinator,
        draftStore: PreviewCommentDraftStore(),
        titleResolver: titleResolver,
        tracker: nil,
        noticePresenter: PreviewNoticePresenter(),
        makeContentRenderer: { StubContentRenderer() }
    )
    return NavigationStack {
        CommentDetailView(commentID: 1, seed: nil, router: router)
    }
}
#endif
