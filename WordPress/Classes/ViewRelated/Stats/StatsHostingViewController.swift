import UIKit
import SwiftUI
import JetpackStats
import WordPressKit

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
        guard let siteID = blog.dotComID?.intValue,
              let api = blog.account?.wordPressComRestApi else {
            showErrorView()
            return
        }

        let siteTimezone = blog.timeZone ?? TimeZone.current

        // Create the context
        let context: StatsContext
        if isUsingMockService {
            // For mock service, we need to use the internal initializer
            // Since we can't access it directly, we'll use the demo context
            context = StatsContext.demo
        } else {
            // For real service, use the public initializer
            context = StatsContext(timeZone: siteTimezone, siteID: siteID, api: api)
        }

        // Create the router with reference to navigation controller
        let router = StatsRouter(navigationController: navigationController)

        // Create the SwiftUI view
        let statsView = StatsMainView(context: context)
            .environment(\.statsRouter, router)
        let hostingController = UIHostingController(rootView: AnyView(statsView))

        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

// MARK: - Presentation
extension StatsHostingViewController {
    static func show(for blog: Blog, from viewController: UIViewController) {
        let statsVC = StatsHostingViewController(blog: blog)

        let navController = UINavigationController(rootViewController: statsVC)
        viewController.present(navController, animated: true)
    }
}
