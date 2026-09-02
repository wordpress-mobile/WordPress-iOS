import SwiftUI
import UIKit

/// Owns the shared detail dependencies and pushes comment detail screens onto
/// the navigation stack of `host`, the comments list controller.
@MainActor
final class CommentsDetailRouter {
    /// The list's hosting controller; detail screens push onto its navigation
    /// controller. Weak: the controller retains this router through the tab view.
    weak var host: UIViewController?

    private let service: any CommentsServiceProtocol
    private let capabilities: any CommentsCapabilitiesProtocol
    private let coordinator: CommentsModerationCoordinator
    private let titleResolver: PostTitleResolver
    private let tracker: (any CommentsTracker)?
    private let noticePresenter: any NoticePresenting
    private let makeContentRenderer: @MainActor () -> any CommentContentRendering

    init(
        service: any CommentsServiceProtocol,
        capabilities: any CommentsCapabilitiesProtocol,
        coordinator: CommentsModerationCoordinator,
        titleResolver: PostTitleResolver,
        tracker: (any CommentsTracker)?,
        noticePresenter: any NoticePresenting,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering
    ) {
        self.service = service
        self.capabilities = capabilities
        self.coordinator = coordinator
        self.titleResolver = titleResolver
        self.tracker = tracker
        self.noticePresenter = noticePresenter
        self.makeContentRenderer = makeContentRenderer
    }

    /// Builds the detail view model and screen for `id` (seeded from the list
    /// row when available) and pushes it onto the shared navigation stack.
    func open(id: Int64, seed: CommentListItem?) {
        let viewModel = CommentDetailViewModel(
            commentID: id,
            seed: seed,
            service: service,
            capabilities: capabilities,
            coordinator: coordinator,
            titleResolver: titleResolver,
            tracker: tracker,
            noticePresenter: noticePresenter
        )
        let renderer = makeContentRenderer()
        renderer.onLinkTapped = { url in
            UIApplication.shared.open(url)
        }
        let detail = CommentDetailView(
            viewModel: viewModel,
            titleResolver: titleResolver,
            renderer: renderer,
            openComment: { [weak self] id, seed in self?.open(id: id, seed: seed) }
        )
        let controller = UIHostingController(rootView: detail)
        controller.navigationItem.largeTitleDisplayMode = .never
        host?.navigationController?.pushViewController(controller, animated: true)
    }
}
