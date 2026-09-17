import SwiftUI
import UIKit

/// Applies destination tab-bar requests to the My Site navigation stack.
final class MySitesNavigationController: UINavigationController {
    private struct Request {
        weak var owner: UIViewController?
        let originallyHidBottomBar: Bool
    }

    private var requests: [Request] = []
    private var originalTabBarHidden: Bool?
    private var isObservingTransition = false

    func hideAppTabBar(for owner: UIViewController) {
        // SwiftUI also creates snapshot hosts that are not navigation destinations.
        guard viewControllers.contains(where: { $0 === owner }),
            let tabBarController, tabBarController.selectedViewController === self
        else { return }
        let tabBar = tabBarController.tabBar

        if !requests.contains(where: { $0.owner === owner }) {
            if originalTabBarHidden == nil {
                // UIKit's existing requests are accounted for by the current stack on restoration.
                originalTabBarHidden = tabBar.isHidden && !viewControllers.contains(where: \.hidesBottomBarWhenPushed)
            }
            requests.append(Request(owner: owner, originallyHidBottomBar: owner.hidesBottomBarWhenPushed))
            owner.hidesBottomBarWhenPushed = true
        }
        // The hosting controller can become available after its push has started.
        tabBar.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAppTabBarVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAppTabBarVisibility()
    }

    func updateAppTabBarVisibility() {
        guard originalTabBarHidden != nil else { return }
        if let transitionCoordinator {
            guard !isObservingTransition else { return }
            isObservingTransition = true
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.isObservingTransition = false
                self?.reconcileAppTabBarVisibility()
            }
        } else {
            reconcileAppTabBarVisibility()
        }
    }

    private func reconcileAppTabBarVisibility() {
        guard let originalTabBarHidden else { return }
        requests.removeAll { request in
            guard let owner = request.owner else { return true }
            guard !viewControllers.contains(where: { $0 === owner }) else { return false }
            owner.hidesBottomBarWhenPushed = request.originallyHidBottomBar
            return true
        }

        guard let tabBarController, tabBarController.selectedViewController === self else { return }
        // Every remaining request's owner is in the stack with `hidesBottomBarWhenPushed` set.
        let hidden = originalTabBarHidden || viewControllers.contains(where: \.hidesBottomBarWhenPushed)
        if tabBarController.tabBar.isHidden != hidden {
            tabBarController.tabBar.isHidden = hidden
        }
        if requests.isEmpty {
            self.originalTabBarHidden = nil
        }
    }
}

extension View {
    /// Hides the app tab bar while this destination remains in the My Site stack.
    func hidesAppTabBar() -> some View {
        background(AppTabBarVisibilityRequest())
    }
}

private struct AppTabBarVisibilityRequest: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {}

    static func dismantleUIViewController(_ controller: Controller, coordinator: Void) {
        controller.updateVisibilityAfterTransition()
    }

    final class Controller: UIViewController {
        private weak var container: MySitesNavigationController?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            requestVisibility()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            requestVisibility()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            updateVisibilityAfterTransition()
        }

        func updateVisibilityAfterTransition() {
            DispatchQueue.main.async { [weak container] in
                container?.updateAppTabBarVisibility()
            }
        }

        private func requestVisibility() {
            guard let parent, let container = parent.navigationController as? MySitesNavigationController else {
                return
            }
            self.container = container
            container.hideAppTabBar(for: parent)
        }
    }
}
