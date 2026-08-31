import SwiftUI
import UIKit

/// The fixed-region comment detail screen: a pinned status pill
/// and author header, an optional "In reply to" strip, the internally
/// scrolling content region, and the navigation-bar share action.
struct CommentDetailView: View {
    @StateObject private var viewModel: CommentDetailViewModel
    @ObservedObject private var titleResolver: PostTitleResolver

    /// Recursive: tapping the parent strip pushes another detail screen for the
    /// parent comment.
    private let openComment: (Int64, CommentListItem?) -> Void
    /// Built by the router once per screen; the content region keeps it for
    /// the screen's lifetime.
    private let renderer: any CommentContentRendering

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
            .toolbar { shareToolbarItem }
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.onAppear() }
    }

    private var fixedRegions: some View {
        VStack(spacing: 0) {
            if let header = viewModel.header {
                VStack(alignment: .leading, spacing: 12) {
                    CommentStatusPill(status: header.status)
                    CommentAuthorHeader(
                        header: header,
                        titleState: titleResolver.titleState(for: header.postID),
                        detail: loadedDetail
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

    @ToolbarContentBuilder
    private var shareToolbarItem: some ToolbarContent {
        if let link = loadedDetail?.link {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: link)
            }
        }
    }

    private var loadedDetail: CommentDetail? {
        if case .loaded(let detail) = viewModel.content { return detail }
        return nil
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

@MainActor
private final class PreviewCommentsService: CommentsServiceProtocol {
    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        CommentsPage(items: [], nextPage: nil)
    }

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        .preview(id: id, status: .pending)
    }
}

private struct PreviewCapabilities: CommentsCapabilitiesProtocol {
    func canModerateComments() async -> Bool { true }
}

#Preview {
    let service = PreviewCommentsService()
    let titleResolver = PostTitleResolver(fetcher: { _ in
        PostTitleResolver.FetchResult(titles: [10: "Reviewing the 2027 Upgrade"])
    })
    let viewModel = CommentDetailViewModel(
        commentID: 1,
        seed: nil,
        service: service,
        capabilities: PreviewCapabilities(),
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
