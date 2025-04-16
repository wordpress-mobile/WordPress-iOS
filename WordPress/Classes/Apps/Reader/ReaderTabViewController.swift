import Combine
import UIKit
import SwiftUI
import WordPressUI

final class ReaderTabViewController: UITabBarController, UITabBarControllerDelegate {
    private var menuStore = ReaderMenuStore()
    private let library = ReaderPresenter(
        viewModel: ReaderSidebarViewModel(isReaderAppModeEnabled: true)
    )
    private let notificationsButtonViewModel = NotificationsButtonViewModel()
    private var cancellables: [AnyCancellable] = []

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
            makeLibraryViewController(),
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
        // TODO: (reader) remove it; had to use due to how ghosts are implemented (separate table)
        homeVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        return UINavigationController(rootViewController: homeVC)
    }

    private func makeLibraryViewController() -> UIViewController {
        let libraryVC = library.sidebar
        libraryVC.tabBarItem = UITabBarItem(
            title: SharedStrings.Reader.library,
            image: UIImage(named: "reader-menu-subscriptions"),
            selectedImage: nil
        )
        libraryVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        return library.prepareForLibraryPresentation()
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
        discoverVC.tabBarItem.scrollEdgeAppearance = {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            return appearance
        }()
        let navigationVC = UINavigationController(rootViewController: discoverVC)
        navigationVC.navigationBar.prefersLargeTitles = true
        return navigationVC
    }

    private func makeNotificationsViewController() -> UIViewController {
        let notificationsVC = Notifications.instantiateInitialViewController()
        notificationsVC.tabBarItem = UITabBarItem(
            title: Strings.notifications,
            image: UIImage(named: "tab-bar-notifications"),
            selectedImage: UIImage(named: "tab-bar-notifications")
        )
        notificationsVC.isReaderAppModeEnabled = true
        let navigationVC = UINavigationController(rootViewController: notificationsVC)
        notificationsVC.enableLargeTitles()

        notificationsButtonViewModel.$counter.sink { [weak notificationsVC] count in
            let image = UIImage(named: count == 0 ? "tab-bar-notifications" : "tab-bar-notifications-unread")
            notificationsVC?.tabBarItem.image = image
            notificationsVC?.tabBarItem.selectedImage = image
        }.store(in: &cancellables)

        return navigationVC
    }

    private func makeMeViewController() -> UIViewController {
        let meVC = ReaderProfileViewController()
        // TODO: (reader) display your profile icons
        meVC.tabBarItem = UITabBarItem(
            title: Strings.me,
            image: UIImage(named: "tab-bar-me"),
            selectedImage: UIImage(named: "tab-bar-me")
        )
        // TODO: (reader) observe gravatar updates
        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
           let avatarURL = account.avatarURL.flatMap(URL.init) {
            Task { @MainActor [weak meVC] in
                do {
                    let image = try await ImageDownloader.shared.image(from: avatarURL)
                    meVC?.tabBarItem.configureGravatarImage(image)
                } catch {
                    // Do nothing
                }
            }
        }
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
