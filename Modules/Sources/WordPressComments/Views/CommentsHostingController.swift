import SwiftUI
import UIKit
import WordPressCore

/// UIKit entry point for the dashboard and iPad detail column.
public enum CommentsHostingController {
    @MainActor
    public static func make(
        client: WordPressClient,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering,
        tracker: any CommentsTracker,
        noticePresenter: any NoticePresenting
    ) -> UIViewController {
        let host = UIHostingController(
            rootView: CommentsView(
                client: client,
                makeContentRenderer: makeContentRenderer,
                tracker: tracker,
                noticePresenter: noticePresenter
            )
        )
        host.navigationItem.largeTitleDisplayMode = .never
        host.hidesBottomBarWhenPushed = true
        return host
    }
}

/// Comments destination for a surrounding navigation container.
/// Use a site-specific view identity when changing the client.
public struct CommentsView: View {
    @StateObject private var context: CommentsContext

    public init(
        client: WordPressClient,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering,
        tracker: any CommentsTracker,
        noticePresenter: any NoticePresenting
    ) {
        _context = StateObject(
            wrappedValue: CommentsContext(
                client: client,
                makeContentRenderer: makeContentRenderer,
                tracker: tracker,
                noticePresenter: noticePresenter
            )
        )
    }

    public var body: some View {
        CommentsTabView(viewModels: context.listViewModels, router: context.detailRouter)
    }
}

/// Keeps the lists and their shared dependencies alive across view updates.
@MainActor
private final class CommentsContext: ObservableObject {
    let listViewModels: [CommentsListFilter: CommentsListViewModel]
    let detailRouter: CommentsDetailRouter

    init(
        client: WordPressClient,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering,
        tracker: any CommentsTracker,
        noticePresenter: any NoticePresenting
    ) {
        let service = CommentsService(client: client)
        let titleResolver = PostTitleResolver(fetcher: PostTitleResolver.liveFetcher(client: client))
        let coordinator = CommentsModerationCoordinator(service: service, tracker: tracker)

        detailRouter = CommentsDetailRouter(
            service: service,
            capabilities: CommentsCapabilities(client: client),
            coordinator: coordinator,
            titleResolver: titleResolver,
            tracker: tracker,
            noticePresenter: noticePresenter,
            makeContentRenderer: makeContentRenderer
        )

        listViewModels = CommentsTabView.makeViewModels(
            service: service,
            titleResolver: titleResolver,
            coordinator: coordinator
        )
    }
}
