import SwiftUI
import UIKit
import WordPressCore

/// Module-side factory, the module's only public symbol. The Blog gate and
/// WordPressClient construction live in the app target; see
/// `WordPress/Classes/ViewRelated/Comments/CommentsRouting.swift`.
public enum CommentsHostingController {
    @MainActor
    public static func make(
        client: WordPressClient,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering,
        tracker: any CommentsTracker,
        noticePresenter: any NoticePresenting
    ) -> UIViewController {
        let service = CommentsService(client: client)
        let titleResolver = PostTitleResolver(fetcher: PostTitleResolver.liveFetcher(client: client))
        let coordinator = CommentsModerationCoordinator(service: service, tracker: tracker)

        // The router builds each detail screen (recursively, so a parent comment
        // pushes onto the same stack). The tab view retains it for the
        // controller's lifetime.
        let router = CommentsDetailRouter(
            service: service,
            capabilities: CommentsCapabilities(client: client),
            coordinator: coordinator,
            titleResolver: titleResolver,
            tracker: tracker,
            noticePresenter: noticePresenter,
            makeContentRenderer: makeContentRenderer
        )

        let listViewModels = CommentsTabView.makeViewModels(
            service: service,
            titleResolver: titleResolver,
            coordinator: coordinator
        )
        let view = CommentsTabView(
            viewModels: listViewModels,
            titleResolver: titleResolver,
            router: router
        )
        let host = CommentsRootHostingController(
            rootView: view,
            listViewModels: Array(listViewModels.values)
        )
        host.navigationItem.largeTitleDisplayMode = .never
        // Hides the app tab bar for the list and everything pushed above it
        // (detail, parent comments): the list has its own status tabs, and the
        // detail's pinned moderation bar belongs at the screen bottom.
        host.hidesBottomBarWhenPushed = true
        router.host = host
        return host
    }
}

/// Hosts the tab view and, on each appearance, retries the list tabs whose
/// stale reload failed while the list was off screen (typically behind a
/// pushed detail screen). `markStale()` already reloads eagerly at event
/// time; this is only the retry for when that reload failed. It lives in the
/// controller because SwiftUI's `onAppear` and `.task` do not re-run when a
/// UIKit-pushed controller is popped back to this one (verified on a
/// simulator).
final class CommentsRootHostingController<Content: View>: UIHostingController<Content> {
    private let listViewModels: [CommentsListViewModel]

    init(rootView: Content, listViewModels: [CommentsListViewModel]) {
        self.listViewModels = listViewModels
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for viewModel in listViewModels {
            Task { await viewModel.reloadIfStale() }
        }
    }
}
