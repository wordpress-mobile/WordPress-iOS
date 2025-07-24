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

        setupStatsView()
        setupNavigationBar()
    }

    private func setupStatsView() {
        guard let context = StatsContext(blog: post.blog),
              let postID = post.postID?.intValue else {
            return
        }
        let info = PostStatsView.PostInfo(
            title: post.titleForDisplay() ?? "",
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
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissViewController)
            )
        }
    }

    @objc private func dismissViewController() {
        presentingViewController?.dismiss(animated: true)
    }
}
