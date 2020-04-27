class ReaderManageScenePresenter: ScenePresenter {

    enum TabbedSection {
        case tags
        case sites

        private func makeViewController() -> UIViewController {
            switch self {
            case .tags:
                return ReaderTagsTableViewController(style: .grouped)
            case .sites:
                return ReaderFollowedSitesViewController.controller(showsAccessoryFollowButtons: true, showsSectionTitle: false)
            }
        }

        var tabbedItem: TabbedViewController.TabbedItem {
            switch self {
            case .tags:
                return TabbedViewController.TabbedItem(title: NSLocalizedString("Followed Tags", comment: "Followed Tags Title"),
                                                               viewController: makeViewController(),
                                                               accessibilityIdentifier: "FollowedTags")
            case .sites:
                return TabbedViewController.TabbedItem(title: NSLocalizedString("Followed Sites", comment: "Followed Sites Title"),
                                                                viewController: makeViewController(),
                                                                accessibilityIdentifier: "FollowedSites")
            }
        }
    }

    weak var presentedViewController: UIViewController?

    private let sections: [TabbedSection]
    private let selectedSection: TabbedSection?
    private weak var delegate: ScenePresenterDelegate?

    init(sections tabbedSections: [TabbedSection] = [TabbedSection.tags, TabbedSection.sites],
         selected: TabbedSection? = nil, sceneDelegate: ScenePresenterDelegate? = nil) {
        sections = tabbedSections
        selectedSection = selected
        delegate = sceneDelegate
    }

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
        let tabbedItems = sections.map({ item in
            return item.tabbedItem
        })

        let tabbedViewController = TabbedViewController(items: tabbedItems, onDismiss: {
            self.delegate?.didDismiss(presenter: self)
        })
        tabbedViewController.title =  NSLocalizedString("Manage", comment: "Title for the Reader Manage screen.")
        if let section = selectedSection, let firstSelection = sections.firstIndex(of: section) {
            tabbedViewController.selection = firstSelection
        }

        return tabbedViewController
    }

    func makeNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: makeViewController())
        return navigationController
    }
}
