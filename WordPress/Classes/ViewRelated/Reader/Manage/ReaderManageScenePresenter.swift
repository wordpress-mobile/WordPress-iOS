class ReaderManageScenePresenter: ScenePresenter {

    var presentedViewController: UIViewController?

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard presentedViewController == nil else {
            completion?()
            return
        }
        let navigationController = makeNavigationController()
        presentedViewController = navigationController
        viewController.present(navigationController, animated: true, completion: nil)
    }
}

private extension ReaderManageScenePresenter {
    func makeViewController() -> TabbedViewController {
        let tagsViewController = ReaderTagsTableViewController(style: .grouped)
        let sitesViewController = ReaderFollowedSitesViewController.controller(showsAccessoryFollowButtons: true, showsSectionTitle: false)

        let tagsItem = TabbedViewController.TabbedItem(title: NSLocalizedString("Followed Tags", comment: "Followed Tags Title"),
                                                       viewController: tagsViewController,
                                                       accessibilityIdentifier: "FollowedTags")

        let sitesItem = TabbedViewController.TabbedItem(title: NSLocalizedString("Followed Sites", comment: "Followed Sites Title"),
                                                        viewController: sitesViewController,
                                                        accessibilityIdentifier: "FollowedSites")

        let tabbedViewController = TabbedViewController(items: [tagsItem, sitesItem])
        tabbedViewController.title =  NSLocalizedString("Manage", comment: "Title for the Reader Manage screen.")

        return tabbedViewController
    }

    func makeNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: makeViewController())
        return navigationController
    }
}
