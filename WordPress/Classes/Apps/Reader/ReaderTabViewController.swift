import UIKit
import SwiftUI
import WordPressUI

final class ReaderTabViewController: UITabBarController, UITabBarControllerDelegate {
    private var menuStore = ReaderMenuStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        if ReaderSidebarViewModel().getTopic(for: .following) != nil {
            setupViewControllers()
        } else {
            loadMenuItems()
        }
    }

    // TODO: (reader) remove the need to fetch the menu on first launch before showing anything
    private func loadMenuItems() {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        activityIndicator.pinCenter()

        menuStore.onCompletion = { [weak self] in
            activityIndicator.removeFromSuperview()
            self?.setupViewControllers()
            self?.menuStore.onCompletion = nil
        }
        menuStore.refreshMenu()
    }

    private func setupViewControllers() {
        self.viewControllers = [
            makeHomeViewController(),
            makeFollowingViewController(),
            makeDiscoverViewController(),
            makeNotificationsViewController(),
            makeMeViewController()
        ]
    }

    // MARK: - Tabs

    private func makeHomeViewController() -> UIViewController {
        let homeVC = ReaderHomeViewController()
        // TODO: (reader) refactor to not require `topic`
        homeVC.readerTopic = ReaderSidebarViewModel().getTopic(for: .following)
        homeVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.home,
            image: UIImage(named: "reader-menu-home"),
            selectedImage: nil
        )
        return UINavigationController(rootViewController: homeVC)
    }

    private func makeFollowingViewController() -> UIViewController {
        let followingVC = ReaderFollowingViewController()
        followingVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.following,
            image: UIImage(named: "reader-menu-subscriptions"),
            selectedImage: nil
        )
        return UINavigationController(rootViewController: followingVC)
    }

    private func makeDiscoverViewController() -> UIViewController {
        let discoverVC: UIViewController = {
            // TODO: (reader) refactor to not require `topic`
            if let topic = ReaderSidebarViewModel().getTopic(for: .discover) {
                ReaderDiscoverTabViewController(topic: topic)
            } else {
                UIViewController()
            }
        }()
        discoverVC.tabBarItem = UITabBarItem(
            title: Strings.discover,
            image: UIImage(named: "reader-menu-explorer"),
            selectedImage: nil
        )
        return UINavigationController(rootViewController: discoverVC)
    }

    private func makeNotificationsViewController() -> UIViewController {
        let notificationsVC = UIStoryboard(name: "Notifications", bundle: nil)
            .instantiateInitialViewController() as! NotificationsViewController
        // TODO: (reader) bind notifications
        notificationsVC.tabBarItem = UITabBarItem(
            title: Strings.notifications,
            image: UIImage(named: "tab-bar-notifications"),
            selectedImage: UIImage(named: "tab-bar-notifications")
        )
        notificationsVC.isReaderModeEnabled = true
        let navigationVC = UINavigationController(rootViewController: notificationsVC)
        notificationsVC.enableLargeTitles()
        return navigationVC
    }

    private func makeMeViewController() -> UIViewController {
        // TODO: (reader) this requires a reader-speicifc profile, so it's just a placeholder
        let meVC = MeViewController()
        // TODO: (reader) display your profile icons
        meVC.tabBarItem = UITabBarItem(
            title: Strings.me,
            image: UIImage(named: "tab-bar-me"),
            selectedImage: UIImage(named: "tab-bar-me")
        )
        return UINavigationController(rootViewController: meVC)
    }

    // MAKR: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if selectedIndex == viewControllers?.firstIndex(of: viewController) {
            (viewController as? UINavigationController)?.scrollContentToTopAnimated(true)
        }
        return true
    }
}

private extension UIViewController {
    func enableLargeTitles() {
        assert(navigationController != nil)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

private enum Strings {
    static let discover = NSLocalizedString("readerApp.tabBar.discover", value: "Discover", comment: "Reader app primary navigation tab bar")
    static let notifications = NSLocalizedString("readerApp.tabBar.notifications", value: "Notifications", comment: "Reader app primary navigation tab bar")
    static let me = NSLocalizedString("readerApp.tabBar.me", value: "Me", comment: "Reader app primary navigation tab bar")
}
