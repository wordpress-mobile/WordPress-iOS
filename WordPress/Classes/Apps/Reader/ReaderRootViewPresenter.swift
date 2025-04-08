import UIKit

final class ReaderRootViewPresenter: RootViewPresenter {
    let rootViewController: UIViewController = ReaderTabViewController()

    func currentlySelectedScreen() -> String {
        // TODO: (reader) implement
        ""
    }

    func currentlyVisibleBlog() -> Blog? {
        // TODO: (reader) this should be optional? what is it for?
        nil
    }

    func showMySitesTab() {
        // TODO: (reader) optional?
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any]) {
        // TODO: (reader) optional?
    }

    func showReader(path: ReaderNavigationPath?) {
        // TODO: (reader) implement
    }

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        // TODO: (reader) implement
    }

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        // TODO: (reader) optional?
    }
}
