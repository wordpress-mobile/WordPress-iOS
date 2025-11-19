import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressUI
import WordPressShared

/// View controller that displays post statistics using the new SwiftUI PostStatsView
final class PostStatsViewController: UIViewController {
    private let post: AbstractPost

    init(post: AbstractPost) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
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
        guard let context = StatsContext(blog: post.blog),
              let postID = post.postID?.intValue else {
            return
        }
        let info = PostStatsView.PostInfo(
            title: post.titleForDisplay(),
            postID: String(postID),
            postURL: post.permaLink.flatMap(URL.init),
            date: post.dateCreated
        )
        let statsView = PostStatsView.make(
            post: info,
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
