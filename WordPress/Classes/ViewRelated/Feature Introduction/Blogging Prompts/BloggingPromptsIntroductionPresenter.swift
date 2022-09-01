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
    private var interactionType: BloggingPromptsFeatureIntroduction.InteractionType

    private lazy var navigationController: UINavigationController = {
        let vc = BloggingPromptsFeatureIntroduction(interactionType: interactionType)
        vc.presenter = self
        return UINavigationController(rootViewController: vc)
    }()

    private var siteSelectorNavigationController: UINavigationController?
    private var selectedBlog: Blog?

    private lazy var accountSites: [Blog]? = {
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        return account?.visibleBlogs.filter { $0.isAccessibleThroughWPCom() }
    }()

    private lazy var accountHasMultipleSites: Bool = {
        (accountSites?.count ?? 0) > 1
    }()

    private lazy var accountHasNoSites: Bool = {
        (accountSites?.count ?? 0) == 0
    }()

    private lazy var bloggingPromptsService: BloggingPromptsService? = {
        return BloggingPromptsService(blog: blogToUse())
    }()

    // MARK: - Init

    init(interactionType: BloggingPromptsFeatureIntroduction.InteractionType = .actionable(blog: nil)) {
        self.interactionType = interactionType
        if case .actionable(let blog) = interactionType {
            selectedBlog = blog
        }
        super.init()
    }

    // MARK: - Present Feature Introduction

    func present(from presentingViewController: UIViewController) {
        WPAnalytics.track(.promptsIntroductionModalViewed)

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
        guard accountHasMultipleSites, selectedBlog == nil else {
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
        selectorViewController.shouldHideSelfHostedSites = true

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

        fetchPrompt(completion: { [weak self] (prompt) in
            guard let prompt = prompt else {
                self?.dispatchErrorNotice()
                self?.navigationController.dismiss(animated: true)
                return
            }

            let editor = EditPostViewController(blog: blog, prompt: prompt)
            editor.modalPresentationStyle = .fullScreen
            editor.entryPoint = .bloggingPromptsFeatureIntroduction

            self?.navigationController.dismiss(animated: true, completion: { [weak self] in
                presentingViewController.present(editor, animated: false)
                self?.trackPostEditorShown(blog)
            })
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

    // MARK: Prompt Fetching

    func fetchPrompt(completion: @escaping ((_ prompt: BloggingPrompt?) -> Void)) {
        // TODO: check for cached prompt first.

        guard let bloggingPromptsService = bloggingPromptsService else {
            DDLogError("Feature Introduction: failed creating BloggingPromptsService instance.")
            return
        }

        bloggingPromptsService.fetchTodaysPrompt(success: { (prompt) in
            completion(prompt)
        }, failure: { (error) in
            completion(nil)
            DDLogError("Feature Introduction: failed fetching blogging prompt: \(String(describing: error))")
        })
    }

    func dispatchErrorNotice() {
        let message = NSLocalizedString("Error loading prompt", comment: "Text displayed when there is a failure loading a blogging prompt.")
        presentingViewController?.displayNotice(title: message)
    }

}
