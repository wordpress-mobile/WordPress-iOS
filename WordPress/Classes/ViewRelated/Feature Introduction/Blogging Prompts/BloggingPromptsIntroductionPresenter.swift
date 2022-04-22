import Foundation
import UIKit

/// Presents the BloggingPromptsFeatureIntroduction with actionable buttons
/// and directs the flow according to which action button is tapped.
/// - Try it: the answer prompt flow.
/// - Remind me: the blogging reminders flow.
/// - If the account has multiple sites, a site picker is displayed before either of the above.

class BloggingPromptsIntroductionPresenter: NSObject {

    // MARK: - Properties

    private var presentingViewController: UIViewController?
    private var interactionType: BloggingPromptsFeatureIntroduction.InteractionType = .actionable

    private lazy var navigationController: UINavigationController = {
        let vc = BloggingPromptsFeatureIntroduction(interactionType: interactionType)
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    private lazy var accountSites: [Blog]? = {
        return AccountService(managedObjectContext: ContextManager.shared.mainContext).defaultWordPressComAccount()?.visibleBlogs
    }()

    private lazy var accountHasMultipleSites: Bool = {
        (accountSites?.count ?? 0) > 1
    }()

    private lazy var accountHasNoSites: Bool = {
        (accountSites?.count ?? 0) == 0
    }()

    // MARK: - Present Feature Introduction

    func present(from presentingViewController: UIViewController) {

        // We shouldn't get here, but just in case - verify the account actually has a site.
        // If not, fallback to the non-actionable/informational view.
        if accountHasNoSites {
            interactionType = .informational
        }

        self.presentingViewController = presentingViewController
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Action Handling

    func primaryButtonSelected() {
        accountHasMultipleSites ? showSiteSelector() : showPostCreation()
    }

    func secondaryButtonSelected() {
        accountHasMultipleSites ? showSiteSelector() : showRemindersScheduling()
    }

}

private extension BloggingPromptsIntroductionPresenter {

    func showSiteSelector() {
        // TODO: show site selector
        navigationController.dismiss(animated: true, completion: nil)
    }

    func showPostCreation() {
        // TODO: show post creation
        navigationController.dismiss(animated: true, completion: nil)
    }

    func showRemindersScheduling() {
        guard let blog = accountSites?.first,
        let presentingViewController = presentingViewController else {
            navigationController.dismiss(animated: true, completion: nil)
            return
        }

        navigationController.dismiss(animated: true, completion: {
            BloggingRemindersFlow.present(from: presentingViewController,
                                          for: blog,
                                          source: .bloggingPromptsFeatureIntroduction)
        })
    }

}
