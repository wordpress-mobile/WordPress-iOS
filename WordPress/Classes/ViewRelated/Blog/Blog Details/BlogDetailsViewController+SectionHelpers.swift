import Foundation
import UIKit
import SwiftUI
import WordPressData
import WordPressUI
import WordPressAPI
import WordPressCore

extension BlogDetailsViewController {
    public func shouldAddJetpackSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.shouldShowJetpackSection
    }

    public func shouldAddGeneralSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.shouldShowJetpackSection == false
    }

    public func shouldAddPersonalizeSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.themeBrowsing) || blog.supports(.menus)
    }

    public func shouldAddMeRow() -> Bool {
        JetpackFeaturesRemovalCoordinator.currentAppUIType == .simplified && !isSidebarModeEnabled
    }

    public func shouldAddSharingRow() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.sharing)
    }

    public func shouldAddPeopleRow() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.people)
    }

    public func shouldAddUsersRow() -> Bool {
        // Only admin users can list users.
        return FeatureFlag.selfHostedSiteUserManagement.enabled && blog.isSelfHosted && blog.isAdmin
    }

    public func shouldAddPluginsRow() -> Bool {
        return blog.supports(.pluginManagement)
    }

    public func shouldAddDomainRegistrationRow() -> Bool {
        return FeatureFlag.domainRegistration.enabled && blog.supports(.domains)
    }

    public func showUsers() {
        guard let presentationDelegate, let userId = blog.userID?.intValue else {
            return
        }

        let feature = NSLocalizedString("applicationPasswordRequired.feature.users", value: "User Management", comment: "Feature name for managing users in the app")
        let rootView = ApplicationPasswordRequiredView(blog: blog, localizedFeatureName: feature, presentingViewController: self) { client in
            let service = UserService(client: client)
            let applicationPasswordService = ApplicationPasswordService(api: client, currentUserId: userId)
            return UserListView(currentUserId: Int32(userId), userService: service, applicationTokenListDataProvider: applicationPasswordService)
        }
        presentationDelegate.presentBlogDetailsViewController(UIHostingController(rootView: rootView))
    }

    public func showManagePluginsScreen() {
        guard blog.supports(.pluginManagement),
              let site = JetpackSiteRef(blog: blog) else {
            return
        }

        let wordpressCoreVersion = blog.version as? String

        let viewController: UIViewController
        if Feature.enabled(.pluginManagementOverhaul) {
            let feature = NSLocalizedString("applicationPasswordRequired.feature.plugins", value: "Plugin Management", comment: "Feature name for managing plugins in the app")
            let rootView = ApplicationPasswordRequiredView(blog: blog, localizedFeatureName: feature, presentingViewController: self) { client in
                let service = PluginService(client: client, wordpressCoreVersion: wordpressCoreVersion)
                InstalledPluginsListView(service: service)
            }
            viewController = UIHostingController(rootView: rootView)
        } else {
            let query = PluginQuery.all(site: site)
            viewController = PluginListViewController(site: site, query: query)
        }

        presentationDelegate?.presentBlogDetailsViewController(viewController)
    }
}

private extension Blog {
    /// If the blog should show the "Jetpack" or the "General" section
    var shouldShowJetpackSection: Bool {
        if supports(.activity) && !isWPForTeams() {
            return true
        }
        if supports(.jetpackSettings) && JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
            return true
        }
        return false
    }
}
