import Combine
import Foundation
import SwiftUI
import UIKit
import WordPressData
import WordPressUI

/// Manages top-level Reader navigation.
public final class ReaderPresenter: NSObject, SplitViewDisplayable {
    private let sidebarViewModel: ReaderSidebarViewModel

    // The view controllers used during split view presentation.
    let sidebar: ReaderSidebarViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    /// The navigation controller for the main content when shown using tabs.
    private var mainNavigationController = UINavigationController()

    private var viewContext: NSManagedObjectContext {
        ContextManager.shared.mainContext
    }

    private var selectionObserver: AnyCancellable?

    public convenience override init() {
        self.init(viewModel: ReaderSidebarViewModel())
    }

    weak var splitViewController: UISplitViewController?

    init(viewModel: ReaderSidebarViewModel) {
        sidebarViewModel = viewModel
        secondary = UINavigationController()
        sidebar = ReaderSidebarViewController(viewModel: sidebarViewModel)
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        supplementary = UINavigationController(rootViewController: sidebar)
        supplementary.navigationBar.prefersLargeTitles = true

        super.init()
    }

    // TODO: (reader) update to allow seamless transitions between split view and tabs
    @objc public func prepareForTabBarPresentation() -> UINavigationController {
        guard AccountHelper.isDotcomAvailable() else {
            return UINavigationController(rootViewController: ReaderLoggedOutViewController())
        }

        sidebar.onViewDidLoad = { [weak self] in
            self?.showInitialSelection()
        }
        sidebarViewModel.isCompact = true
        sidebarViewModel.restoreSelection(defaultValue: nil)
        mainNavigationController = UINavigationController(rootViewController: sidebar) // Loads sidebar lazily
        mainNavigationController.navigationBar.prefersLargeTitles = true
        sidebar.navigationItem.backButtonDisplayMode = .minimal
        return mainNavigationController
    }

    // TODO: (reader) rework
    /// Returns the sidebar screen updated to act a a "Library" tab in the
    /// standalone Reader app.
    func prepareForLibraryPresentation() -> UIViewController {
        sidebarViewModel.isCompact = true
        sidebar.onViewDidLoad = { [weak self] in
            self?.showInitialSelection()
        }
        mainNavigationController = UINavigationController(rootViewController: sidebar) // Loads sidebar lazily
        mainNavigationController.navigationBar.prefersLargeTitles = true

        sidebar.title = SharedStrings.Reader.library
        sidebar.navigationItem.largeTitleDisplayMode = .always
        mainNavigationController.navigationBar.prefersLargeTitles = true

        return mainNavigationController
    }

    // MARK: - Navigation

    func showInitialSelection() {
        // -warning: List occasionally sets the selection to `nil` when switching items.
        selectionObserver = sidebarViewModel.$selection.compactMap { $0 }
            .removeDuplicates { [weak self] in
                guard $0 == $1, let self, let splitViewController else { return false }
                self.popMainNavigationController(in: splitViewController)
                return true
            }
            .sink { [weak self] in self?.configure(for: $0) }
    }

    private func configure(for selection: ReaderSidebarItem) {
        switch selection {
        case .main(let screen):
            show(makeViewController(for: screen))
        case .allSubscriptions:
            show(makeAllSubscriptionsViewController(), isLargeTitle: true)
        case .subscription(let objectID):
            show(makeViewController(withTopicID: objectID))
        case .list(let objectID):
            show(makeViewController(withTopicID: objectID))
        case .tag(let objectID):
            show(makeViewController(withTopicID: objectID))
        case .organization(let objectID):
            show(makeViewController(withTopicID: objectID))
        }

        hideSupplementaryColumnIfNeeded()
    }

    private func popMainNavigationController(in splitViewController: UISplitViewController) {
        let secondaryVC = splitViewController.viewController(for: .secondary)
        (secondaryVC as? UINavigationController)?.popToRootViewController(animated: true)
        hideSupplementaryColumnIfNeeded()
    }

    private func hideSupplementaryColumnIfNeeded() {
        if sidebar.didAppear, let splitVC = sidebar.splitViewController, splitVC.splitBehavior == .overlay {
            DispatchQueue.main.async {
                splitVC.hide(.supplementary)
            }
        }
    }

    private func makeViewController<T: ReaderAbstractTopic>(withTopicID objectID: TaggedManagedObjectID<T>) -> UIViewController {
        do {
            let topic = try viewContext.existingObject(with: objectID)
            return ReaderStreamViewController.controllerWithTopic(topic)
        } catch {
            wpAssertionFailure("tag missing", userInfo: ["error": "\(error)"])
            return makeErrorViewController()
        }
    }

    private func makeViewController(for screen: ReaderStaticScreen) -> UIViewController {
        switch screen {
        case .recent, .discover, .likes:
            if let topic = screen.topicType.flatMap(sidebarViewModel.getTopic) {
                if screen == .discover {
                    return ReaderDiscoverViewController(topic: topic)
                } else {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                }
            } else {
                return makeErrorViewController() // This should never happen
            }
        case .saved:
            return ReaderStreamViewController.controllerForContentType(.saved)
        case .search:
            return ReaderSearchViewController()
        case .subscrtipions:
            return makeAllSubscriptionsViewController()
        case .tags:
            return makeTagsViewController()
        case .lists:
            return makeListsViewController()
        }
    }

    private func makeAllSubscriptionsViewController() -> UIViewController {
        let view = ReaderSubscriptionsView() { [weak self] selection in
            let streamVC = ReaderStreamViewController.controllerWithTopic(selection)
            self?.push(streamVC)
        }.environment(\.managedObjectContext, viewContext)
        let hostVC = UIHostingController(rootView: view)
        hostVC.title = SharedStrings.Reader.subscriptions
        if sidebarViewModel.isCompact {
            hostVC.navigationItem.largeTitleDisplayMode = .never
        }
        return hostVC
    }

    private func makeTagsViewController() -> UIViewController {
        let tagsVC = ReaderTagsTableViewController(style: .plain)
        tagsVC.title = SharedStrings.Reader.tags
        if sidebarViewModel.isCompact {
            tagsVC.navigationItem.largeTitleDisplayMode = .never
        }
        return tagsVC
    }

    private func makeListsViewController() -> UIViewController {
        let view = ReaderListsView() { [weak self] selection in
            let streamVC = ReaderStreamViewController.controllerWithTopic(selection)
            self?.push(streamVC)
        }.environment(\.managedObjectContext, viewContext)
        let hostVC = UIHostingController(rootView: view)
        hostVC.title = SharedStrings.Reader.lists
        if sidebarViewModel.isCompact {
            hostVC.navigationItem.largeTitleDisplayMode = .never
        }
        return hostVC
    }

    private func makeErrorViewController() -> UIViewController {
        UIHostingController(rootView: EmptyStateView(SharedStrings.Error.generic, systemImage: "exclamationmark.circle"))
    }

    /// Shows the given view controller by either displaying it in the `.secondary`
    /// column (split view) or pushing to the navigation stack.
    private func show(_ viewController: UIViewController, isLargeTitle: Bool = false) {
        if let splitViewController {
            guard !self.contentIsAlreadyDisplayed(viewController, in: splitViewController, for: .secondary) else {
                DDLogInfo("View controller for \(viewController.contentIdentifier) already presented – skipping show")
                return
            }
            (viewController as? ReaderStreamViewController)?.isNotificationsBarButtonEnabled = true

            let navigationVC = UINavigationController(rootViewController: viewController)
            if isLargeTitle {
                navigationVC.navigationBar.prefersLargeTitles = true
            }
            splitViewController.setViewController(navigationVC, for: .secondary)
        } else {
            // Don't push a view controller on top of another with the same content
            guard !self.contentIsAlreadyDisplayed(viewController, in: mainNavigationController) else {
                DDLogInfo("View controller for \(viewController.contentIdentifier) already presented – skipping show")
                return
            }

            mainNavigationController.safePushViewController(viewController, animated: true)
        }
    }

    /// Pushes the view controller to either the existing navigation stack in
    /// the `.secondary` column (split view) or to the main navigation stack.
    private func push(_ viewController: UIViewController) {
        if let splitViewController {
            // Don't push a view controller on top of another with the same content
            guard !contentIsAlreadyDisplayed(viewController, in: splitViewController, for: .secondary) else {
                DDLogInfo("View controller for \(viewController.contentIdentifier) already presented – skipping push")
                return
            }
            let navigationVC = splitViewController.viewController(for: .secondary) as? UINavigationController
            wpAssert(navigationVC != nil)
            navigationVC?.safePushViewController(viewController, animated: true)
        } else {
            // Don't push a view controller on top of another with the same content
            guard !self.contentIsAlreadyDisplayed(viewController, in: mainNavigationController) else {
                DDLogInfo("View controller for \(viewController.contentIdentifier) already presented – skipping push")
                return
            }

            mainNavigationController.safePushViewController(viewController, animated: true)
        }
    }

    private func contentIsAlreadyDisplayed(_ viewController: UIViewController, in nav: UINavigationController) -> Bool {
        guard
            let current = nav.topViewController as? ContentIdentifiable,
            let new = viewController as? ContentIdentifiable
        else {
            return false
        }

        return current.contentIdentifier == new.contentIdentifier
    }

    private func contentIsAlreadyDisplayed(
        _ viewController: UIViewController,
        in split: UISplitViewController,
        for column: UISplitViewController.Column
    ) -> Bool {
        guard let top = split.viewController(for: column) else {
            return false
        }

        if let nav = top as? UINavigationController {
            return self.contentIsAlreadyDisplayed(viewController, in: nav)
        }

        guard let current = top as? ContentIdentifiable, let new = viewController as? ContentIdentifiable else {
            return false
        }

        return current.contentIdentifier == new.contentIdentifier
    }

    // MARK: - Deep Links (ReaderNavigationPath)

    func navigate(to path: ReaderNavigationPath) {
        let viewModel = sidebarViewModel

        switch path {
        case .recent:
            viewModel.selection = .main(.recent)
        case .discover:
            viewModel.selection = .main(.discover)
        case .likes:
            viewModel.selection = .main(.likes)
        case .search:
            viewModel.selection = .main(.search)
        case .subscriptions:
            viewModel.selection = .allSubscriptions
        case let .post(postID, siteID, isFeed):
            push(ReaderDetailViewController.controllerWithPostID(NSNumber(value: postID), siteID: NSNumber(value: siteID), isFeed: isFeed))
        case let .postURL(url):
            push(ReaderDetailViewController.controllerWithPostURL(url))
        case let .topic(topic):
            viewModel.selection = nil
            show(ReaderStreamViewController.controllerWithTopic(topic))
        case let .tag(slug):
            viewModel.selection = nil
            show(ReaderStreamViewController.controllerWithTagSlug(slug))
        case let .site(siteID, isFeed):
            viewModel.selection = nil
            show(ReaderStreamViewController.controllerWithSiteID(NSNumber(value: siteID), isFeed: isFeed))
        }
    }

    // MARK: - SplitViewDisplayable

    func displayed(in splitVC: UISplitViewController) {
        if secondary.viewControllers.isEmpty {
            showInitialSelection()
        }
    }
}

private extension UINavigationController {
    // TODO: fix when stack trace becomes available
    // A workaround for https://a8c.sentry.io/issues/3140539221.
    func safePushViewController(_ viewController: UIViewController, animated: Bool) {
        guard !children.contains(viewController) else {
            return wpAssertionFailure("pushing the same view controller more than once", userInfo: ["viewController": "\(viewController)"])
        }
        pushViewController(viewController, animated: animated)
    }
}

fileprivate extension UIViewController {
    /// Helper for logging – if a user hits a bug where we're not showing the content they expect, this should help debug it.
    /// Using a non-nil value makes the log lines easier to write.
    var contentIdentifier: String {
        (self as? ContentIdentifiable)?.contentIdentifier ?? "(unknown)"
    }
}
