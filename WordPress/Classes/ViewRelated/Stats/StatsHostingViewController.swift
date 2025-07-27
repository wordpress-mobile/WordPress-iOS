import UIKit
import SwiftUI
import JetpackStats
import WordPressKit
import WordPressShared
import Gravatar

/// A UIViewController wrapper for the new SwiftUI StatsMainView
class StatsHostingViewController: UIViewController {

    let blog: Blog
    var dismissBlock: (() -> Void)?

    private var isUsingMockService = false
    private var hostingController: UIHostingController<AnyView>?

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    static func makeStatsViewController(for blog: Blog) -> UIViewController {
        guard FeatureFlag.newStats.enabled else {
            let statsVC = StatsViewController()
            statsVC.blog = blog
            statsVC.hidesBottomBarWhenPushed = true
            statsVC.navigationItem.largeTitleDisplayMode = .never
            return statsVC
        }

        let statsVC = StatsHostingViewController(blog: blog)
        statsVC.hidesBottomBarWhenPushed = true
        statsVC.navigationItem.largeTitleDisplayMode = .never
        return statsVC
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Stats", comment: "Stats screen title")
        setupStatsView()
        setupNavigationBar()
    }

    private func setupStatsView() {
        guard var context = StatsContext(blog: blog) else {
            showErrorView()
            return
        }

        if isUsingMockService {
            // For mock service, we need to use the internal initializer
            // Since we can't access it directly, we'll use the demo context
            context = StatsContext.demo
        }

        let statsView = StatsMainView(context: context, router: StatsRouter(viewController: self))
        let hostingController = UIHostingController(rootView: AnyView(statsView))

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.pinEdges()
        hostingController.didMove(toParent: self)

        self.hostingController = hostingController
    }

    private func setupNavigationBar() {
        // Add menu button with ellipsis
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: createMenu()
        )
        navigationItem.rightBarButtonItem = menuButton
    }

    private func createMenu() -> UIMenu {
        let toggleDataSource = UIAction(
            title: isUsingMockService ? "Use Real Data" : "Use Mock Data",
            image: UIImage(systemName: "arrow.triangle.2.circlepath")
        ) { [weak self] _ in
            self?.toggleServiceType()
        }

        // We can add more menu items here later

        return UIMenu(children: [toggleDataSource])
    }

    private func updateNavigationMenu() {
        navigationItem.rightBarButtonItem?.menu = createMenu()
    }

    private func toggleServiceType() {
        isUsingMockService.toggle()

        // Remove existing hosting controller
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil

        // Recreate with new service
        setupStatsView()

        // Update menu
        updateNavigationMenu()

        // Show toast indicating the change
        let message = isUsingMockService ? "Using mock data" : "Using real data"
        showToast(message: message)
    }

    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toast.heightAnchor.constraint(equalToConstant: 40),
            toast.widthAnchor.constraint(equalToConstant: 200)
        ])

        UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    private func showErrorView() {
        let errorLabel = UILabel()
        errorLabel.text = "Unable to load stats"
        errorLabel.textAlignment = .center
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension StatsHostingViewController {
    static func show(for blog: Blog, from viewController: UIViewController) {
        let statsVC = StatsHostingViewController(blog: blog)

        let navController = UINavigationController(rootViewController: statsVC)
        viewController.present(navController, animated: true)
    }
}

extension StatsContext {
    init?(blog: Blog) {
        guard let siteID = blog.dotComID?.intValue,
              let api = blog.account?.wordPressComRestApi else {
            wpAssertionFailure("required context missing")
            return nil
        }
        self.init(
            timeZone: blog.timeZone ?? .current,
            siteID: siteID,
            api: api
        )

        // Configure avatar preprocessing using Gravatar
        self.preprocessAvatar = { url, size in
            // Use AvatarURL from Gravatar to update the URL to the requested pixel size
            guard let avatarURL = AvatarURL(url: url) else {
                return url
            }
            let options = AvatarQueryOptions(preferredSize: .points(size))
            return avatarURL.replacing(options: options)?.url ?? url
        }
    }
}

extension StatsRouter {
    @MainActor
    convenience init(viewController: UIViewController) {
        self.init(
            viewController: viewController,
            factory: JetpackAppStatsRouterScreenFactory()
        )
    }
}

/// Shared router implementation for Jetpack app stats navigation
private final class JetpackAppStatsRouterScreenFactory: StatsRouterScreenFactory {
    func makeLikesListViewController(siteID: Int, postID: Int, totalLikes: Int) -> UIViewController {
        StatsLikesListViewController(
            siteID: siteID as NSNumber,
            postID: NSNumber(value: postID),
            totalLikes: totalLikes
        )
    }

    func makeCommentsListViewController(siteID: Int, postID: Int) -> UIViewController {
        ReaderCommentsViewController(
            postID: NSNumber(value: postID),
            siteID: siteID as NSNumber
        )
    }
}
