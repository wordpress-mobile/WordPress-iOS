import Foundation
import UIKit

/// Presents the BloggingPromptsFeatureIntroduction with actionable buttons
/// and directs the flow according to which action button is tapped.
/// - Try it: the answer prompt flow.
/// - Remind me: the blogging reminders flow.
/// - If the account has multiple sites, a site selector is displayed before either of the above.

class BloggingPromptsIntroductionPresenter: NSObject {

    // MARK: - Properties

    private var presentingViewController: UIViewController?
    private var interactionType: BloggingPromptsFeatureIntroduction.InteractionType = .actionable

    private lazy var navigationController: UINavigationController = {
        let vc = BloggingPromptsFeatureIntroduction(interactionType: interactionType)
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    private var siteSelectorNavigationController: UINavigationController?
    private var selectedBlog: Blog?

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
        showSiteSelectorIfNeeded(completion: { [weak self] in
            self?.showPostCreation()
        })
    }

    func secondaryButtonSelected() {
        showSiteSelectorIfNeeded(completion: { [weak self] in
            self?.showRemindersScheduling()
        })
    }

}

private extension BloggingPromptsIntroductionPresenter {

    func showSiteSelectorIfNeeded(completion: @escaping () -> Void) {
        guard accountHasMultipleSites else {
            completion()
            return
        }

        let successHandler: BlogSelectorSuccessDotComHandler = { [weak self] (dotComID: NSNumber?) in
            self?.selectedBlog = self?.accountSites?.first(where: { $0.dotComID == dotComID })
            self?.siteSelectorNavigationController?.dismiss(animated: true)
            completion()
        }

        let dismissHandler: BlogSelectorDismissHandler = {
            completion()
        }

        let selectorViewController = BlogSelectorViewController(selectedBlogDotComID: nil,
                                                                successHandler: successHandler,
                                                                dismissHandler: dismissHandler)

        selectorViewController.displaysOnlyDefaultAccountSites = true
        selectorViewController.dismissOnCompletion = false
        selectorViewController.dismissOnCancellation = true

        let selectorNavigationController = UINavigationController(rootViewController: selectorViewController)
        self.navigationController.present(selectorNavigationController, animated: true)
        siteSelectorNavigationController = selectorNavigationController
    }

    func showPostCreation() {
        guard let blog = blogToUse(),
              let presentingViewController = presentingViewController else {
            navigationController.dismiss(animated: true)
            return
        }

        // TODO: pre-populate post content with prompt from backend instead
        // of example prompt
        let editor = EditPostViewController(blog: blog, prompt: .examplePrompt)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = .bloggingPromptsFeatureIntroduction

        navigationController.dismiss(animated: true, completion: { [weak self] in
            presentingViewController.present(editor, animated: false)
            self?.trackPostEditorShown(blog)
        })
    }

    func showRemindersScheduling() {
        guard let blog = blogToUse(),
        let presentingViewController = presentingViewController else {
            navigationController.dismiss(animated: true)
            return
        }

        navigationController.dismiss(animated: true, completion: {
            BloggingRemindersFlow.present(from: presentingViewController,
                                          for: blog,
                                          source: .bloggingPromptsFeatureIntroduction)
        })
    }

    func blogToUse() -> Blog? {
        return accountHasMultipleSites ? selectedBlog : accountSites?.first
    }

    func trackPostEditorShown(_ blog: Blog) {
        WPAppAnalytics.track(.editorCreatedPost,
                             withProperties: [WPAppAnalyticsKeyTapSource: "blogging_prompts_feature_introduction", WPAppAnalyticsKeyPostType: "post"],
                             with: blog)
    }

}
