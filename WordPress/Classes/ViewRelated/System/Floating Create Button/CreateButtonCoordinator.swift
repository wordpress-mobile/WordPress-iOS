import Gridicons
import WordPressFlux
import WordPressUI

@objc class CreateButtonCoordinator: NSObject {

    private enum Constants {
        static let padding: CGFloat = -16 // Bottom and trailing padding to position the button along the bottom right corner
        static let heightWidth: CGFloat = 56 // Height and width of the button
        static let popoverOffset: CGFloat = -10 // The vertical offset of the iPad popover
        static let maximumTooltipViews = 5 // Caps the number of times the user can see the announcement tooltip
        static let skippedPromptsUDKey = "wp_skipped_blogging_prompts"
    }

    var button: FloatingActionButton = {
        let button = FloatingActionButton(image: .gridicon(.plus))
        button.accessibilityLabel = NSLocalizedString("Create", comment: "Accessibility label for create floating action button")
        button.accessibilityIdentifier = "floatingCreateButton"
        return button
    }()

    private weak var viewController: UIViewController?

    private let noticeAnimator = NoticeAnimator(duration: 0.5, springDampening: 0.7, springVelocity: 0.0)

    private func notice(for blog: Blog) -> Notice {
        let showsStories = blog.supports(.stories)
        let title = showsStories ? NSLocalizedString("Create a post, page, or story", comment: "The tooltip title for the Floating Create Button") : NSLocalizedString("Creates new post, or page", comment: " Accessibility hint for create floating action button")
        let notice = Notice(title: title,
                            message: "",
                            style: ToolTipNoticeStyle()) { [weak self] _ in
                self?.didDismissTooltip = true
                self?.hideNotice()
        }
        return notice
    }

    // Once this reaches `maximumTooltipViews` we won't show the tooltip again
    private var shownTooltipCount: Int {
        set {
            if newValue >= Constants.maximumTooltipViews {
                didDismissTooltip = true
            } else {
                UserPersistentStoreFactory.instance().createButtonTooltipDisplayCount = newValue
            }
        }
        get {
            return UserPersistentStoreFactory.instance().createButtonTooltipDisplayCount
        }
    }

    private var didDismissTooltip: Bool {
        set {
            UserPersistentStoreFactory.instance().createButtonTooltipWasDisplayed = newValue
        }
        get {
            return UserPersistentStoreFactory.instance().createButtonTooltipWasDisplayed
        }
    }

    // TODO: when prompt is used, get prompt from cache so it's using the latest.
    private var prompt: BloggingPrompt?

    private lazy var bloggingPromptsService: BloggingPromptsService? = {
        return BloggingPromptsService(blog: blog)
    }()

    private weak var noticeContainerView: NoticeContainerView?
    private let actions: [ActionSheetItem]
    private let source: String
    private let blog: Blog?

    /// Returns a newly initialized CreateButtonCoordinator
    /// - Parameters:
    ///   - viewController: The UIViewController from which the menu should be shown.
    ///   - actions: A list of actions to display in the menu
    ///   - source: The source where the create button is being presented from
    ///   - blog: The current blog in context
    init(_ viewController: UIViewController, actions: [ActionSheetItem], source: String, blog: Blog? = nil) {
        self.viewController = viewController
        self.actions = actions
        self.source = source
        self.blog = blog

        super.init()

        listenForQuickStart()

        // Only fetch the prompt if it is actually needed, i.e. on the FAB that has multiple actions.
        if actions.count > 1 {
            fetchBloggingPrompt()
        }
    }

    deinit {
        quickStartObserver = nil
    }

    /// Should be called any time the `viewController`'s trait collections will change. Dismisses when horizontal class changes to transition from .popover -> .custom
    /// - Parameter previousTraitCollection: The previous trait collection
    /// - Parameter newTraitCollection: The new trait collection
    @objc func presentingTraitCollectionWillChange(_ previousTraitCollection: UITraitCollection, newTraitCollection: UITraitCollection) {
        if let actionSheetController = viewController?.presentedViewController as? ActionSheetViewController {
            if previousTraitCollection.horizontalSizeClass != newTraitCollection.horizontalSizeClass {
                viewController?.dismiss(animated: false, completion: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.setupPresentation(on: actionSheetController, for: newTraitCollection)
                    self.viewController?.present(actionSheetController, animated: false, completion: nil)
                })
            }
        }
    }

    /// Button must be manually shown _after_ adding using `showCreateButton`
    @objc func add(to view: UIView, trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding)
        ])

        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)
    }

    private var currentTourElement: QuickStartTourElement?

    @objc func showCreateSheet() {
        didDismissTooltip = true
        hideNotice()

        guard let viewController = viewController else {
            return
        }

        if actions.count == 1 {
            actions.first?.handler()
        } else {
            let actionSheetVC = actionSheetController(with: viewController.traitCollection)
            viewController.present(actionSheetVC, animated: true, completion: { [weak self] in
                WPAnalytics.track(.createSheetShown, properties: ["source": self?.source ?? ""])

                if let element = self?.currentTourElement {
                    QuickStartTourGuide.shared.visited(element)
                }
            })
        }
    }

    private func actionSheetController(with traitCollection: UITraitCollection) -> UIViewController {
        let actionSheetVC = CreateButtonActionSheet(headerView: createPromptHeaderView(), actions: actions)
        setupPresentation(on: actionSheetVC, for: traitCollection)
        return actionSheetVC
    }

    private func setupPresentation(on viewController: UIViewController, for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            viewController.modalPresentationStyle = .popover
        } else {
            viewController.modalPresentationStyle = .custom
        }

        viewController.popoverPresentationController?.sourceView = self.button
        viewController.popoverPresentationController?.sourceRect = self.button.bounds.offsetBy(dx: 0, dy: Constants.popoverOffset)
        viewController.transitioningDelegate = self
    }

    private func hideNotice() {
        if let container = noticeContainerView {
            NoticePresenter.dismiss(container: container)
        }
    }

    func hideCreateButtonTooltip() {
        didDismissTooltip = true
        hideNotice()
    }

    @objc func hideCreateButton() {
        hideNotice()

        if UIAccessibility.isReduceMotionEnabled {
            button.isHidden = true
        } else {
            button.springAnimation(toShow: false)
        }
    }

    func removeCreateButton() {
        button.removeFromSuperview()
        noticeContainerView?.removeFromSuperview()
    }

    @objc func showCreateButton(for blog: Blog) {
        let showsStories = blog.supports(.stories)
        button.accessibilityHint = showsStories ? NSLocalizedString("Creates new post, page, or story", comment: " Accessibility hint for create floating action button") : NSLocalizedString("Create a post or page", comment: " Accessibility hint for create floating action button")
        showCreateButton(notice: notice(for: blog))
    }

    private func showCreateButton(notice: Notice) {
        if !didDismissTooltip {
            noticeContainerView = noticeAnimator.present(notice: notice, in: viewController!.view, sourceView: button)
            shownTooltipCount += 1
        }

        if UIAccessibility.isReduceMotionEnabled {
            button.isHidden = false
        } else {
            button.springAnimation(toShow: true)
        }
    }

    // MARK: - Quick Start

    private var quickStartObserver: Any?

    private func quickStartNotice(_ description: NSAttributedString) -> Notice {
        let notice = Notice(title: "",
                            message: "",
                            style: ToolTipNoticeStyle(attributedMessage: description)) { [weak self] _ in
                self?.didDismissTooltip = true
                self?.hideNotice()
        }

        return notice
    }

    private func listenForQuickStart() {
        quickStartObserver = NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self,
                let userInfo = notification.userInfo,
                let element = userInfo[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
                let description = userInfo[QuickStartTourGuide.notificationDescriptionKey] as? NSAttributedString,
                element == .newpost || element == .newPage else {
                    return
            }

            self.currentTourElement = element
            self.hideNotice()
            self.didDismissTooltip = false
            self.showCreateButton(notice: self.quickStartNotice(description))
        }
    }
}

// MARK: Tranisitioning Delegate

extension CreateButtonCoordinator: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimationController(transitionType: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = BottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
        return presentationController
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return (viewController?.presentedViewController?.presentationController as? BottomSheetPresentationController)?.interactionController
    }
}

// MARK: - Blogging Prompts Methods

private extension CreateButtonCoordinator {

    private func fetchBloggingPrompt() {

        // TODO: check for cached prompt first.

        guard let bloggingPromptsService = bloggingPromptsService else {
            DDLogError("FAB: failed creating BloggingPromptsService instance.")
            prompt = nil
            return
        }

        bloggingPromptsService.todaysPrompt(success: { [weak self] (prompt) in
            self?.prompt = prompt
        }, failure: { [weak self] (error) in
            self?.prompt = nil
            DDLogError("FAB: failed fetching blogging prompt: \(String(describing: error))")
        })
    }

    private func createPromptHeaderView() -> BloggingPromptsHeaderView? {
        guard FeatureFlag.bloggingPrompts.enabled,
              let blog = blog,
              blog.isAccessibleThroughWPCom(),
              let prompt = prompt,
              let siteID = blog.dotComID,
              BlogDashboardPersonalizationService(siteID: siteID.intValue).isEnabled(.prompts),
              !userSkippedPrompt(prompt, for: blog) else {
            return nil
        }

        let promptsHeaderView = BloggingPromptsHeaderView.view(for: prompt)

        promptsHeaderView.answerPromptHandler = { [weak self] in
            WPAnalytics.track(.promptsBottomSheetAnswerPrompt)
            self?.viewController?.dismiss(animated: true) {
                let editor = EditPostViewController(blog: blog, prompt: prompt)
                editor.modalPresentationStyle = .fullScreen
                editor.entryPoint = .bloggingPromptsActionSheetHeader
                self?.viewController?.present(editor, animated: true)
            }
        }

        promptsHeaderView.infoButtonHandler = { [weak self] in
            WPAnalytics.track(.promptsBottomSheetHelp)
            guard let presentedViewController = self?.viewController?.presentedViewController else {
                return
            }
            BloggingPromptsIntroductionPresenter(interactionType: .actionable(blog: blog)).present(from: presentedViewController)
        }

        return promptsHeaderView
    }

    func userSkippedPrompt(_ prompt: BloggingPrompt, for blog: Blog) -> Bool {
        guard AppConfiguration.isJetpack,
              let siteID = blog.dotComID?.stringValue,
              let allSkippedPrompts = UserPersistentStoreFactory.instance().array(forKey: Constants.skippedPromptsUDKey) as? [[String: Int32]] else {
            return false
        }
        let siteSkippedPrompts = allSkippedPrompts.filter { $0.keys.first == siteID }
        let matchingPrompts = siteSkippedPrompts.filter { $0.values.first == prompt.promptID }

        return !matchingPrompts.isEmpty
    }

}
