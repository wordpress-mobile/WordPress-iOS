import UIKit

extension WPTab {
    var identifier: String {
        switch self {
        case .mySites: "mysites"
        case .reader: "reader"
        case .notifications: "notifications"
        case .me: "me"
        }
    }

    init?(tab: UITab?) {
        guard let match = Self.allCases.first(where: { $0.identifier == tab?.identifier }) else {
            return nil
        }
        self = match
    }
}

extension WPTabBarController {
    @objc var selectedAppTab: WPTab {
        WPTab(tab: selectedTab) ?? .mySites
    }

    @objc func tab(forAppTab appTab: WPTab) -> UITab? {
        tab(forIdentifier: appTab.identifier)
    }

    @objc func selectTab(_ appTab: WPTab) {
        selectedTab = tab(forAppTab: appTab)
    }

    @objc(updateTabsSelecting:) func updateTabs(selecting selection: WPTab) {
        let controllers = [
            mySitesCoordinator.rootViewController,
            readerNavigationController,
            notificationsNavigationController,
            meNavigationController
        ]
        tabs = zip(WPTab.allCases, controllers)
            .map { appTab, controller in
                // Account changes can replace one tab while the others keep their navigation state.
                if let existing = tab(forAppTab: appTab), existing.viewController === controller {
                    return existing
                }
                let item: UITabBarItem = controller.tabBarItem
                let tab = UITab(title: item.title ?? "", image: item.image, identifier: appTab.identifier) { _ in
                    controller
                }
                tab.preferredPlacement = .fixed
                tab.accessibilityIdentifier = item.accessibilityIdentifier
                tab.accessibilityLabel = item.accessibilityLabel
                if appTab == .me {
                    tab.configureAccountAvatar(AccountAvatar.shared.image, isSelected: selection == .me)
                }
                return tab
            }
        selectTab(selection)
    }
}
