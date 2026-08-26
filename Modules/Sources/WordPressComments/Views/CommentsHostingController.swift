import SwiftUI
import UIKit
import WordPressCore

/// Module-side factory, the module's only public symbol. The Blog gate and
/// WordPressClient construction live in the app target; see
/// `WordPress/Classes/ViewRelated/Comments/CommentsRouting.swift`.
public enum CommentsHostingController {
    @MainActor
    public static func make(client: WordPressClient) -> UIViewController {
        let view = CommentsTabView(
            service: CommentsService(client: client),
            titleResolver: PostTitleResolver(fetcher: PostTitleResolver.liveFetcher(client: client))
        )
        let host = UIHostingController(rootView: view)
        host.navigationItem.largeTitleDisplayMode = .never
        return host
    }
}
