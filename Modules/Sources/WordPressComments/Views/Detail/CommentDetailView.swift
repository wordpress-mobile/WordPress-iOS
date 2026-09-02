import SwiftUI
import UIKit

/// The fixed-region comment detail and moderation screen: a pinned status pill
/// and author header, an optional "In reply to" strip, the internally
/// scrolling content region, and a pinned bottom moderation toolbar hosted via
/// `.safeAreaInset(edge: .bottom)` (never `.toolbar(placement: .bottomBar)`,
/// which does not render in a UIKit-hosted `UIHostingController`).
struct CommentDetailView: View {
    @StateObject private var viewModel: CommentDetailViewModel
    @ObservedObject private var titleResolver: PostTitleResolver

    /// Recursive: tapping the parent strip pushes another detail screen for the
    /// parent comment.
    private let openComment: (Int64, CommentListItem?) -> Void
    /// Built by the router once per screen; the content region keeps it for
    /// the screen's lifetime.
    private let renderer: any CommentContentRendering

    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: CommentDetailViewModel,
        titleResolver: PostTitleResolver,
        renderer: any CommentContentRendering,
        openComment: @escaping (Int64, CommentListItem?) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.titleResolver = titleResolver
        self.renderer = renderer
        self.openComment = openComment
    }

    var body: some View {
        fixedRegions
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomToolbar }
            .toolbar { trailingToolbarItems }
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.onAppear() }
            // The comment no longer exists, so there is nothing left to show.
            // `dismiss` pops this screen off the UIKit navigation stack.
            .onChange(of: viewModel.isDeleted) { _, isDeleted in
                if isDeleted { dismiss() }
            }
    }

    private var fixedRegions: some View {
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
                CommentParentStrip(parent: parent) { openComment(parent.id, parent) }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            Divider()
            contentRegion
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var contentRegion: some View {
        switch viewModel.content {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            failureView
        case .loaded(let detail):
            CommentContentRegion(renderer: renderer, html: detail.contentHTML)
        }
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label(Strings.detailErrorTitle, systemImage: "exclamationmark.triangle")
        } actions: {
            Button(Strings.errorRetry) {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var bottomToolbar: some View {
        let model = viewModel.toolbarModel
        if model != .hidden {
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

    @ToolbarContentBuilder
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            let link = viewModel.loadedDetail?.link
            let menuAction = viewModel.toolbarModel.menuAction
            if link != nil || menuAction != nil {
                Menu {
                    if let link {
                        ShareLink(item: link)
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
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel(Strings.detailMoreActions)
            }
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

#Preview {
    let service = PreviewCommentsService(fetchedStatus: .pending, numberOfReplies: 2)
    let coordinator = CommentsModerationCoordinator(service: service)
    let titleResolver = PostTitleResolver(fetcher: { _ in
        PostTitleResolver.FetchResult(titles: [10: "Reviewing the 2027 Upgrade"])
    })
    let viewModel = CommentDetailViewModel(
        commentID: 1,
        seed: nil,
        service: service,
        capabilities: PreviewCapabilities(),
        coordinator: coordinator,
        titleResolver: titleResolver
    )
    return NavigationStack {
        CommentDetailView(
            viewModel: viewModel,
            titleResolver: titleResolver,
            renderer: StubContentRenderer(),
            openComment: { _, _ in }
        )
    }
}
#endif
