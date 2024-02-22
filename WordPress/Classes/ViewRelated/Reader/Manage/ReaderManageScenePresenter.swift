extension NSNotification.Name {
    static let readerManageControllerWasDismissed = NSNotification.Name("ReaderManageControllerWasDismissed")
}

class ReaderManageScenePresenter {

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
                return TabbedViewController.TabbedItem(title: NSLocalizedString("reader.manage.tab.tags",
                                                                                value: "Tags",
                                                                                comment: "Manage tags tab title"),
                                                               viewController: makeViewController(),
                                                               accessibilityIdentifier: "FollowedTags")
            case .sites:
                return TabbedViewController.TabbedItem(title: NSLocalizedString("reader.manage.tab.blogs",
                                                                                value: "Blogs",
                                                                                comment: "Manage blogs tab title"),
                                                                viewController: makeViewController(),
                                                                accessibilityIdentifier: "FollowedSites")
            }
        }
    }

    weak var presentedViewController: UIViewController?

    private let sections: [TabbedSection]
    private var selectedSection: TabbedSection?
    private weak var delegate: ScenePresenterDelegate?

    init(sections tabbedSections: [TabbedSection] = [TabbedSection.tags, TabbedSection.sites],
         selected: TabbedSection? = nil,
         sceneDelegate: ScenePresenterDelegate? = nil) {
        sections = tabbedSections
        selectedSection = selected
        delegate = sceneDelegate
    }

    /// Presents the Reader Manage flow.
    ///
    /// - Parameters:
    ///   - viewController: The presenting view controller.
    ///   - selectedSection: The section that will be selected by default.
    ///   - animated: Whether the presentation should be animated.
    ///   - completion: Closure that's called after the user dismisses the Manage flow.
    func present(on viewController: UIViewController,
                 selectedSection: TabbedSection?,
                 animated: Bool,
                 completion: (() -> Void)?) {
        guard presentedViewController == nil else {
            completion?()
            return
        }

        self.selectedSection = selectedSection
        let navigationController = UINavigationController(rootViewController: makeViewController(onDismiss: completion))
        presentedViewController = navigationController
        viewController.present(navigationController, animated: true, completion: nil)

        WPAnalytics.track(.readerManageViewDisplayed)
    }
}

// MARK: - ScenePresenter

extension ReaderManageScenePresenter: ScenePresenter {
    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        present(on: viewController, selectedSection: nil, animated: animated, completion: completion)
    }
}

// MARK: - Private helpers

private extension ReaderManageScenePresenter {
    func makeViewController(onDismiss: (() -> Void)? = nil) -> TabbedViewController {
        let tabbedItems = sections.map({ item in
            return item.tabbedItem
        })

        let tabbedViewController = TabbedViewController(items: tabbedItems, onDismiss: { [weak self] in
            guard let self else {
                return
            }

            onDismiss?()
            self.delegate?.didDismiss(presenter: self)
            NotificationCenter.default.post(name: .readerManageControllerWasDismissed, object: self)
            WPAnalytics.track(.readerManageViewDismissed)
        })
        tabbedViewController.title =  NSLocalizedString("Manage", comment: "Title for the Reader Manage screen.")
        if let section = selectedSection, let firstSelection = sections.firstIndex(of: section) {
            tabbedViewController.selection = firstSelection
        }

        return tabbedViewController
    }

}
