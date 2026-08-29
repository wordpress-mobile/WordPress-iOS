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

        let view = CommentsTabView(
            service: service,
            titleResolver: titleResolver,
            router: router
        )
        let host = UIHostingController(rootView: view)
        host.navigationItem.largeTitleDisplayMode = .never
        // Hides the app tab bar for the list and everything pushed above it
        // (detail, parent comments): the list has its own status tabs, and the
        // detail's pinned moderation bar belongs at the screen bottom.
        host.hidesBottomBarWhenPushed = true
        router.host = host
        return host
    }
}
