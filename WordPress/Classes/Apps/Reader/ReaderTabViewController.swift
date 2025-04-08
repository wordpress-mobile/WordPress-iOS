import UIKit
import SwiftUI

final class ReaderTabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewControllers()
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
        let homeVC: UIViewController = {
            // TODO: (reader) refactor to not require `topic`
            if let topic = ReaderSidebarViewModel().getTopic(for: .following) {
                ReaderStreamViewController.controllerWithTopic(topic)
            } else {
                UIViewController()
            }
        }()
        homeVC.tabBarItem = UITabBarItem(
            title: Strings.home,
            image: UIImage(named: "reader-menu-home"),
            selectedImage: nil
        )
        return UINavigationController(rootViewController: homeVC)
    }

    private func makeFollowingViewController() -> UIViewController {
        // TODO: (reader) figure out where we show tags and lists
        let followingVC = UIHostingController(rootView: ReaderSubscriptionsView()
            .environment(\.managedObjectContext, ContextManager.shared.mainContext))
        followingVC.tabBarItem = UITabBarItem(
            title: Strings.following,
            image: UIImage(named: "reader-menu-subscriptions"),
            selectedImage: nil
        )
        let navigationVC = UINavigationController(rootViewController: followingVC)
        followingVC.enableLargeTitles()
        return navigationVC
    }

    private func makeDiscoverViewController() -> UIViewController {
        let discoverVC: UIViewController = {
            // TODO: (reader) refactor to not require `topic`
            if let topic = ReaderSidebarViewModel().getTopic(for: .discover) {
                ReaderDiscoverViewController(topic: topic)
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
}

private extension UIViewController {
    func enableLargeTitles() {
        assert(navigationController != nil)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

private enum Strings {
    static let home = NSLocalizedString("readerApp.tabBar.home", value: "Home", comment: "Reader app primary navigation tab bar")
    static let following = NSLocalizedString("readerApp.tabBar.following", value: "Following", comment: "Reader app primary navigation tab bar")
    static let discover = NSLocalizedString("readerApp.tabBar.discover", value: "Discover", comment: "Reader app primary navigation tab bar")
    static let notifications = NSLocalizedString("readerApp.tabBar.notifications", value: "Notifications", comment: "Reader app primary navigation tab bar")
    static let me = NSLocalizedString("readerApp.tabBar.me", value: "Me", comment: "Reader app primary navigation tab bar")
}
