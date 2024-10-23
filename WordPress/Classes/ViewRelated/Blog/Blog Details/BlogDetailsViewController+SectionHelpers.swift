import Foundation
import WordPressUI
import UIKit
import SwiftUI

extension Array where Element: BlogDetailsSection {
    fileprivate func findSectionIndex(of category: BlogDetailsSectionCategory) -> Int? {
        return firstIndex(where: { $0.category == category })
    }
}

extension BlogDetailsSubsection {
    func sectionCategory(for blog: Blog) -> BlogDetailsSectionCategory {
        switch self {
        case .domainCredit:
            return .domainCredit
        case .activity, .jetpackSettings, .siteMonitoring:
            return .jetpack
        case .stats where blog.shouldShowJetpackSection:
            return .jetpack
        case .stats where !blog.shouldShowJetpackSection:
            return .general
        case .pages, .posts, .media, .comments:
            return .content
        case .themes, .customize:
            return .personalize
        case .me, .sharing, .people, .plugins:
            return .configure
        case .home:
            return .home
        default:
            fatalError()
        }
    }
}

extension BlogDetailsViewController {
    @objc func findSectionIndex(sections: [BlogDetailsSection], category: BlogDetailsSectionCategory) -> Int {
        return sections.findSectionIndex(of: category) ?? NSNotFound
    }

    @objc func sectionCategory(subsection: BlogDetailsSubsection, blog: Blog) -> BlogDetailsSectionCategory {
        return subsection.sectionCategory(for: blog)
    }

    @objc func defaultSubsection() -> BlogDetailsSubsection {
        if !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
            return .posts
        }
        if shouldShowDashboard() {
            return .home
        }
        return .stats
    }

    @objc func shouldShowStats() -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
    }

    /// Convenience method that returns the view controller for Stats based on the features removal state.
    ///
    /// - Returns: Either the actual Stats view, or the static poster for Stats.
    @objc func viewControllerForStats() -> UIViewController {
        guard shouldShowStats() else {
            return MovedToJetpackViewController(source: .stats)
        }

        let statsView = StatsViewController()
        statsView.blog = blog
        statsView.hidesBottomBarWhenPushed = true
        statsView.navigationItem.largeTitleDisplayMode = .never
        return statsView
    }

    @objc func shouldAddJetpackSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.shouldShowJetpackSection
    }

    @objc func shouldAddGeneralSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.shouldShowJetpackSection == false
    }

    @objc func shouldAddPersonalizeSection() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.themeBrowsing) || blog.supports(.menus)
    }

    @objc func shouldAddMeRow() -> Bool {
        JetpackFeaturesRemovalCoordinator.currentAppUIType == .simplified && !isSidebarModeEnabled
    }

    @objc func shouldAddSharingRow() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.sharing)
    }

    @objc func shouldAddPeopleRow() -> Bool {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            return false
        }
        return blog.supports(.people)
    }

    @objc func shouldAddUsersRow() -> Bool {
        blog.isSelfHosted
    }

    @objc func shouldAddPluginsRow() -> Bool {
        return blog.supports(.pluginManagement)
    }

    @objc func shouldAddDomainRegistrationRow() -> Bool {
        return AppConfiguration.allowsDomainRegistration && blog.supports(.domains)
    }

    @objc func shouldShowApplicationPasswordRow() -> Bool {
        // Only available for application-password authenticated self-hosted sites.
        return self.blog.account == nil && self.blog.userID != nil && (try? WordPressSite.from(blog: self.blog)) != nil
    }

    private func createWordPressClient() -> WordPressClient? {
        do {
            let site = try WordPressSite.from(blog: self.blog)
            return try WordPressClient.for(site: site, in: .shared)
        }
        catch {
           DDLogError("Failed to create WordPressClient: \(error)")
           return nil
       }
    }

    private func createApplicationPasswordService() -> ApplicationPasswordService? {
        guard let client = createWordPressClient(), let userId = self.blog.userID?.intValue else {
            return nil
        }

        return ApplicationPasswordService(api: client, currentUserId: userId)
    }

    private func createUserService() -> UserService? {
        guard let client = createWordPressClient(), let userId = self.blog.userID?.intValue else {
            return nil
        }

        return UserService(api: client, currentUserId: userId)
    }

    @objc func showApplicationPasswordManagement() {
        guard let presentationDelegate, let service = createApplicationPasswordService() else {
            return
        }

        let viewModel = ApplicationTokenListViewModel(dataProvider: service)
        let viewController = UIHostingController(rootView: ApplicationTokenListView(viewModel: viewModel))
        presentationDelegate.presentBlogDetailsViewController(viewController)
    }

    @available(iOS 16.4, *)
    @objc func showUsers() {
        guard self.blog.supportsDotOrgRestApi else {
            let vc = UIHostingController(rootView: RestApiUpgradePrompt(didTapGetStarted: {
                debugPrint("Tapped get started")
            }, didTapLearnMore: {
                debugPrint("Tapped learn more")
            }))

            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium()]
            }

            self.navigationController?.present(vc, animated: true)

            return

        }

        guard let presentationDelegate, let service = createUserService() else {
            return
        }

        UserObjectResolver.userProvider = service
        UserObjectResolver.actionDispatcher = service.actionDispatcher

        let userListView = UIHostingController(rootView: UserListView())
        presentationDelegate.presentBlogDetailsViewController(userListView)
    }

    @objc func showManagePluginsScreen() {
        guard blog.supports(.pluginManagement),
              let site = JetpackSiteRef(blog: blog) else {
            return
        }
        let query = PluginQuery.all(site: site)
        let listViewController = PluginListViewController(site: site, query: query)
        presentationDelegate?.presentBlogDetailsViewController(listViewController)
    }
 }
