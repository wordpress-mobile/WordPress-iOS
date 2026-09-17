import Testing
import UIKit

@testable import WordPress

@MainActor
struct MySitesNavigationControllerTests {
    @Test func unregisteredRouteDoesNotChangeTabBarVisibility() {
        let route = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(viewControllers: [route])

        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == false)
        #expect(route.hidesBottomBarWhenPushed == false)
    }

    @Test func requestedRootRemainsHiddenUnderDetailAndRestoresAfterReset() {
        let requestedRoot = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(viewControllers: [requestedRoot])

        navigationController.hideAppTabBar(for: requestedRoot)
        navigationController.setViewControllers([requestedRoot, UIViewController()], animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == true)
        #expect(requestedRoot.hidesBottomBarWhenPushed == true)

        navigationController.setViewControllers([UIViewController()], animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == false)
        #expect(requestedRoot.hidesBottomBarWhenPushed == false)
    }

    @Test func snapshotOwnerOutsideNavigationStackIsIgnored() {
        let route = UIViewController()
        let snapshot = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(viewControllers: [route])

        navigationController.hideAppTabBar(for: snapshot)

        #expect(tabBarController.tabBar.isHidden == false)
        #expect(snapshot.hidesBottomBarWhenPushed == false)
    }

    @Test func duplicateRequestRestoresOriginalBottomBarPreference() {
        let route = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(viewControllers: [route])

        navigationController.hideAppTabBar(for: route)
        navigationController.hideAppTabBar(for: route)
        navigationController.setViewControllers([UIViewController()], animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == false)
        #expect(route.hidesBottomBarWhenPushed == false)
    }

    @Test func removedRequestRestoresTabBarWhenNavigationControllerBecomesSelectedAgain() {
        let route = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(viewControllers: [route])
        let otherNavigationController = UINavigationController(rootViewController: UIViewController())
        tabBarController.setViewControllers([navigationController, otherNavigationController], animated: false)

        navigationController.hideAppTabBar(for: route)
        tabBarController.selectedViewController = otherNavigationController
        navigationController.setViewControllers([UIViewController()], animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(route.hidesBottomBarWhenPushed == false)

        tabBarController.selectedViewController = navigationController
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == false)
    }

    @Test func existingUIKitBottomBarPreferenceRemainsHiddenAfterRequestIsRemoved() {
        let root = UIViewController()
        let existingUIKitRoute = UIViewController()
        existingUIKitRoute.hidesBottomBarWhenPushed = true
        let requestedRoute = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(
            viewControllers: [root, existingUIKitRoute, requestedRoute]
        )

        navigationController.hideAppTabBar(for: requestedRoute)
        navigationController.setViewControllers([root, existingUIKitRoute], animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == true)
        #expect(existingUIKitRoute.hidesBottomBarWhenPushed == true)
        #expect(requestedRoute.hidesBottomBarWhenPushed == false)
    }

    @Test func resetRestoresVisibleTabBarWhenExistingUIKitHiddenRouteIsRemoved() {
        let root = UIViewController()
        let existingUIKitRoute = UIViewController()
        existingUIKitRoute.hidesBottomBarWhenPushed = true
        let requestedRoute = UIViewController()
        let (tabBarController, navigationController) = makeNavigationController(
            viewControllers: [root, existingUIKitRoute, requestedRoute]
        )
        tabBarController.tabBar.isHidden = true

        navigationController.hideAppTabBar(for: requestedRoute)
        navigationController.popToRootViewController(animated: false)
        navigationController.updateAppTabBarVisibility()

        #expect(tabBarController.tabBar.isHidden == false)
        #expect(requestedRoute.hidesBottomBarWhenPushed == false)
    }

    private func makeNavigationController(
        viewControllers: [UIViewController]
    ) -> (UITabBarController, MySitesNavigationController) {
        let navigationController = MySitesNavigationController()
        navigationController.setViewControllers(viewControllers, animated: false)
        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([navigationController], animated: false)
        return (tabBarController, navigationController)
    }
}
