import UIKit
import SwiftUI

final class ReaderTabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewControllers()
    }

    private func setupViewControllers() {
        let homeVC = UIViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: Strings.home,
            image: UIImage(named: "reader-menu-home"),
            selectedImage: nil
        )

        // TODO: (reader) figure out where we show tags and lists
        let followingVC = UIHostingController(rootView: ReaderSubscriptionsView()
            .environment(\.managedObjectContext, ContextManager.shared.mainContext))
        followingVC.tabBarItem = UITabBarItem(
            title: Strings.following,
            image: UIImage(named: "reader-menu-subscriptions"),
            selectedImage: nil
        )
        followingVC.navigationItem.largeTitleDisplayMode = .always

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

        // TODO: (reader) bind notifications
        let notificationsVC = UIViewController()
        notificationsVC.tabBarItem = UITabBarItem(
            title: Strings.notifications,
            image: UIImage(named: "tab-bar-notifications"),
            selectedImage: UIImage(named: "tab-bar-notifications")
        )

        // TODO: (reader) display your profile icons
        let meVC = UIViewController()
        meVC.tabBarItem = UITabBarItem(
            title: Strings.me,
            image: UIImage(named: "tab-bar-me"),
            selectedImage: UIImage(named: "tab-bar-me")
        )

        self.viewControllers = [
            UINavigationController(rootViewController: homeVC),
            UINavigationController(rootViewController: followingVC),
            UINavigationController(rootViewController: discoverVC),
            UINavigationController(rootViewController: notificationsVC),
            UINavigationController(rootViewController: meVC)
        ]

        followingVC.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

private enum Strings {
    static let home = NSLocalizedString("readerApp.tabBar.home", value: "Home", comment: "Reader app primary navigation tab bar")
    static let following = NSLocalizedString("readerApp.tabBar.following", value: "Following", comment: "Reader app primary navigation tab bar")
    static let discover = NSLocalizedString("readerApp.tabBar.discover", value: "Discover", comment: "Reader app primary navigation tab bar")
    static let notifications = NSLocalizedString("readerApp.tabBar.notifications", value: "Notifications", comment: "Reader app primary navigation tab bar")
    static let me = NSLocalizedString("readerApp.tabBar.me", value: "Me", comment: "Reader app primary navigation tab bar")
}
