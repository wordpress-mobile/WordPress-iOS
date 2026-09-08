import UIKit
import WordPressData
import WordPressMediaLibrary

@MainActor
final class MediaDetailURLOpenerAdapter: MediaDetailURLOpener {
    private let blog: Blog
    private weak var host: UIViewController?

    init(blog: Blog) {
        self.blog = blog
    }

    /// Attach the hosting controller AFTER it's been constructed. The host
    /// is held weakly so reference cycles are avoided. Production routing
    /// constructs the adapter, builds the hosting controller (which captures
    /// the adapter), then calls this to close the loop.
    func attach(host: UIViewController) {
        self.host = host
    }

    func open(_ url: URL, mediaTitle: String?) {
        let controller = WebViewControllerFactory.controller(url: url, blog: blog, source: "media_item")
        controller.loadViewIfNeeded()
        controller.title = mediaTitle ?? ""
        host?.navigationController?.pushViewController(controller, animated: true)
    }
}
