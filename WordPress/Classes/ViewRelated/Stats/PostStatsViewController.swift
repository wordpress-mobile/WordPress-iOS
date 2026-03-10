import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressUI
import WordPressShared

/// View controller that displays post statistics using the new SwiftUI PostStatsView
final class PostStatsViewController: UIViewController {
    private let postInfo: PostStatsView.PostInfo
    private let blog: Blog

    init(postInfo: PostStatsView.PostInfo, blog: Blog) {
        self.postInfo = postInfo
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(postID: Int, postTitle: String, postURL: URL?, postDate: Date?, blog: Blog) {
        let info = PostStatsView.PostInfo(
            title: postTitle,
            postID: String(postID),
            postURL: postURL,
            date: postDate
        )
        self.init(postInfo: info, blog: blog)
    }

    convenience init(post: AbstractPost) {
        let info = PostStatsView.PostInfo(
            title: post.titleForDisplay(),
            postID: String(post.postID?.intValue ?? 0),
            postURL: post.permaLink.flatMap(URL.init),
            date: post.dateCreated
        )
        self.init(postInfo: info, blog: post.blog)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = Strings.title

        setupStatsView()
        setupNavigationBar()
    }

    private func setupStatsView() {
        guard let context = StatsContext(blog: blog),
              postInfo.postID != "0" else {
            return
        }
        let statsView = PostStatsView.make(
            post: postInfo,
            context: context,
            router: StatsRouter(viewController: self)
        )
        let hostingController = UIHostingController(rootView: statsView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.pinEdges()
        hostingController.didMove(toParent: self)
    }

    private func setupNavigationBar() {
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(dismissViewController)
            )
        }
    }

    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true)
    }
}

private enum Strings {
    static let title = NSLocalizedString("postStats.title", value: "Post Stats", comment: "Navigation bar title of the Post Stats screen")
}
