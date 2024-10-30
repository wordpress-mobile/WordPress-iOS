import Foundation
import UIKit
import SwiftUI
import Combine
import WordPressUI

/// Manages top-level Reader navigation.
final class ReaderPresenter: NSObject, SplitViewDisplayable {
    private let sidebarViewModel = ReaderSidebarViewModel()

    // The view controllers used during split view presentation.
    let sidebar: ReaderSidebarViewController
    let supplementary: UINavigationController
    var secondary: UINavigationController

    /// The navigation controller for the main content when shown using tabs.
    private var mainNavigationController = UINavigationController()
    private var latestContentVC: UIViewController?

    private var viewContext: NSManagedObjectContext {
        ContextManager.shared.mainContext
    }

    private var selectionObserver: AnyCancellable?

    override init() {
        secondary = UINavigationController()
        sidebar = ReaderSidebarViewController(viewModel: sidebarViewModel)
        sidebar.navigationItem.largeTitleDisplayMode = .automatic
        supplementary = UINavigationController(rootViewController: sidebar)
        supplementary.navigationBar.prefersLargeTitles = true

        super.init()

        sidebarViewModel.navigate = { [weak self] in self?.navigate(to: $0) }
    }

    // TODO: (reader) update to allow seamless transitions between split view and tabs
    @objc func prepareForTabBarPresentation() -> UINavigationController {
        sidebar.onViewDidLoad = { [weak self] in
            self?.showInitialSelection()
        }
        sidebarViewModel.isCompact = true
        sidebarViewModel.restoreSelection(defaultValue: nil)
        mainNavigationController.navigationBar.prefersLargeTitles = true
        mainNavigationController = UINavigationController(rootViewController: sidebar) // Loads sidebar lazily
        sidebar.navigationItem.backButtonDisplayMode = .minimal
        return mainNavigationController
    }

    // MARK: - Navigation

    func showInitialSelection() {
        // -warning: List occasionally sets the selection to `nil` when switching items.
        selectionObserver = sidebarViewModel.$selection.compactMap { $0 }
            .removeDuplicates { [weak self] in
                guard $0 == $1 else { return false }
                self?.popMainNavigationController()
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
    }

    private func popMainNavigationController() {
        if let splitViewController {
            let secondaryVC = splitViewController.viewController(for: .secondary)
            (secondaryVC as? UINavigationController)?.popToRootViewController(animated: true)
            hideSupplementaryColumnIfNeeded()
        } else {
            if let latestContentVC {
                // Return to the previous view controller preserving its state
                mainNavigationController.pushViewController(latestContentVC, animated: true)
            }
        }
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
            return ReaderSearchViewController.controller(withSearchText: "")
        }
    }

    private func makeAllSubscriptionsViewController() -> UIViewController {
        let view = ReaderSubscriptionsView() { [weak self] selection in
            let streamVC = ReaderStreamViewController.controllerWithTopic(selection)
            self?.push(streamVC)
        }.environment(\.managedObjectContext, viewContext)
        let hostVC = UIHostingController(rootView: view)
        hostVC.title = ReaderSubscriptionsView.navigationTitle
        if sidebarViewModel.isCompact {
            hostVC.navigationItem.largeTitleDisplayMode = .never
        }
        return hostVC
    }

    private func navigate(to item: ReaderSidebarNavigation) {
        switch item {
        case .addTag:
            let addTagVC = UIHostingController(rootView: ReaderTagsAddTagView())
            addTagVC.modalPresentationStyle = .formSheet
            let preferredHeight: CGFloat = 124
            addTagVC.sheetPresentationController?.detents = [.custom(resolver: { _ in
                preferredHeight
            })]
            addTagVC.preferredContentSize = CGSize(width: 420, height: preferredHeight)
            sidebar.present(addTagVC, animated: true, completion: nil)
        case .discoverTags:
            let tags = viewContext.allObjects(
                ofType: ReaderTagTopic.self,
                matching: ReaderSidebarTagsSection.predicate,
                sortedBy: [NSSortDescriptor(SortDescriptor<ReaderTagTopic>(\.title, order: .forward))]
            )
            let interestsVC = ReaderSelectInterestsViewController(topics: tags)
            interestsVC.didSaveInterests = { [weak self] _ in
                self?.sidebar.dismiss(animated: true)
            }
            let navigationVC = UINavigationController(rootViewController: interestsVC)
            navigationVC.modalPresentationStyle = .formSheet
            sidebar.present(navigationVC, animated: true, completion: nil)
        }
    }

    private func makeErrorViewController() -> UIViewController {
        UIHostingController(rootView: EmptyStateView(SharedStrings.Error.generic, systemImage: "exclamationmark.circle"))
    }

    /// Shows the given view controller by either displaying it in the `.secondary`
    /// column (split view) or pushing to the navigation stack.
    private func show(_ viewController: UIViewController, isLargeTitle: Bool = false) {
        if let splitViewController {
            let navigationVC = UINavigationController(rootViewController: viewController)
            if isLargeTitle {
                navigationVC.navigationBar.prefersLargeTitles = true
            }
            splitViewController.setViewController(navigationVC, for: .secondary)
        } else {
            latestContentVC = viewController
            mainNavigationController.pushViewController(viewController, animated: true)
        }
    }

    /// Pushes the view controller to either the existing navigation stack in
    /// the `.secondary` column (split view) or to the main navigation stack.
    private func push(_ viewController: UIViewController) {
        if let splitViewController {
            let navigationVC = splitViewController.viewController(for: .secondary) as? UINavigationController
            wpAssert(navigationVC != nil)
            navigationVC?.pushViewController(viewController, animated: true)
        } else {
            mainNavigationController.pushViewController(viewController, animated: true)
        }
    }

    private var splitViewController: UISplitViewController? {
        sidebar.splitViewController
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
            viewModel.selection = nil
            show(ReaderDetailViewController.controllerWithPostID(NSNumber(value: postID), siteID: NSNumber(value: siteID), isFeed: isFeed))
        case let .postURL(url):
            viewModel.selection = nil
            show(ReaderDetailViewController.controllerWithPostURL(url))
        case let .topic(topic):
            viewModel.selection = nil
            show(ReaderStreamViewController.controllerWithTopic(topic))
        case let .tag(slug):
            viewModel.selection = nil
            show(ReaderStreamViewController.controllerWithTagSlug(slug))
        }
    }

    // MARK: - SplitViewDisplayable

    func displayed(in splitVC: UISplitViewController) {
        if secondary.viewControllers.isEmpty {
            showInitialSelection()
        }
    }
}
