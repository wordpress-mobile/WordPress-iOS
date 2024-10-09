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
    private let mainNavigationController = UINavigationController()
    private var latestContentVC: UIViewController?

    private var viewContext: NSManagedObjectContext {
        ContextManager.shared.mainContext
    }

    private var cancellables: [AnyCancellable] = []

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
        sidebarViewModel.isCompactStyleEnabled = true
        mainNavigationController.navigationBar.prefersLargeTitles = true
        mainNavigationController.viewControllers = [sidebar]
//        sidebar.navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.left"), primaryAction: UIAction { [weak self] _ in
//            self?.mainNavigationController.popViewController(animated: true)
//        })
        sidebar.navigationItem.backButtonDisplayMode = .minimal
        showInitialSelection()
        return mainNavigationController
    }

    // MARK: - Navigation

    func showInitialSelection() {
        cancellables = []

        // -warning: List occasionally sets the selection to `nil` when switching items.
        sidebarViewModel.$selection.compactMap { $0 }
            .removeDuplicates { [weak self] in
                guard $0 == $1 else { return false }
                self?.popMainNavigationController()
                return true
            }
            .sink { [weak self] in self?.configure(for: $0) }
            .store(in: &cancellables)
    }

    private func configure(for selection: ReaderSidebarItem) {
        switch selection {
        case .main(let screen):
            showSecondary(makeViewController(for: screen))
        case .allSubscriptions:
            showSecondary(makeAllSubscriptionsViewController(), isLargeTitle: true)
        case .subscription(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .list(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .tag(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
        case .organization(let objectID):
            showSecondary(makeViewController(withTopicID: objectID))
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
                    return ReaderCardsStreamViewController.controller(topic: topic)
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
            guard let self else { return }
            let navigationVC = self.splitViewController?.viewController(for: .secondary) as? UINavigationController
            wpAssert(navigationVC != nil)
            let streamVC = ReaderStreamViewController.controllerWithTopic(selection)
            navigationVC?.pushViewController(streamVC, animated: true)
        }.environment(\.managedObjectContext, viewContext)
        return UIHostingController(rootView: view)
    }

    private func navigate(to item: ReaderSidebarNavigation) {
        switch item {
        case .addTag:
            let addTagVC = UIHostingController(rootView: ReaderTagsAddTagView())
            addTagVC.modalPresentationStyle = .formSheet
            addTagVC.preferredContentSize = CGSize(width: 420, height: 124)
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

    private func showSecondary(_ viewController: UIViewController, isLargeTitle: Bool = false) {
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
            showSecondary(ReaderDetailViewController.controllerWithPostID(NSNumber(value: postID), siteID: NSNumber(value: siteID), isFeed: isFeed))
        case let .postURL(url):
            viewModel.selection = nil
            showSecondary(ReaderDetailViewController.controllerWithPostURL(url))
        case let .topic(topic):
            viewModel.selection = nil
            showSecondary(ReaderStreamViewController.controllerWithTopic(topic))
        case let .tag(slug):
            viewModel.selection = nil
            showSecondary(ReaderStreamViewController.controllerWithTagSlug(slug))
        }
    }

    // MARK: - SplitViewDisplayable

    func displayed(in splitVC: UISplitViewController) {
        if secondary.viewControllers.isEmpty {
            showInitialSelection()
        }
    }
}
