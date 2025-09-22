import UIKit
import Gridicons
import WordPressData
import WordPressFlux
import WordPressShared
import WordPressUI

final class CreateButtonCoordinator: NSObject {

    private enum Constants {
        static let padding: CGFloat = -16 // Bottom and trailing padding to position the button along the bottom right corner
        static let heightWidth: CGFloat = 56 // Height and width of the button
        static let popoverOffset: CGFloat = -4 // The vertical offset of the iPad popover
        static let skippedPromptsUDKey = "wp_skipped_blogging_prompts"
    }

    var button: UIButton = {
        let button: UIButton
        if #available(iOS 26, *) {
            var configuration = UIButton.Configuration.prominentClearGlass()
            configuration.image = UIImage(systemName: "plus")
            configuration.contentInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                font: .systemFont(ofSize: 20, weight: .semibold)
            )
            configuration.baseForegroundColor = .systemBackground
            configuration.baseBackgroundColor = .label.withAlphaComponent(0.8)

            button = UIButton(configuration: configuration, primaryAction: nil)
        } else {
            button = FloatingActionButton(image: .gridicon(.plus))
        }
        button.accessibilityLabel = NSLocalizedString("Create", comment: "Accessibility label for create floating action button")
        button.accessibilityIdentifier = "floatingCreateButton"
        return button
    }()

    private weak var viewController: UIViewController?

    // TODO: when prompt is used, get prompt from cache so it's using the latest.
    private var prompt: BloggingPrompt?

    private lazy var bloggingPromptsService: BloggingPromptsService? = {
        return BloggingPromptsService(blog: blog)
    }()

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

        // Only fetch the prompt if it is actually needed, i.e. on the FAB that has multiple actions.
        if actions.count > 1 {
            fetchBloggingPrompt()
        }
    }

    /// Should be called any time the `viewController`'s trait collections will change. Dismisses when horizontal class changes to transition from .popover -> .custom
    /// - Parameter previousTraitCollection: The previous trait collection
    /// - Parameter newTraitCollection: The new trait collection
    func presentingTraitCollectionWillChange(_ previousTraitCollection: UITraitCollection, newTraitCollection: UITraitCollection) {
        if let actionSheetController = viewController?.presentedViewController as? ActionSheetViewController {
            if previousTraitCollection.horizontalSizeClass != newTraitCollection.horizontalSizeClass {
                viewController?.dismiss(animated: false, completion: { [weak self] in
                    guard let self else {
                        return
                    }
                    self.setupPresentation(on: actionSheetController, for: newTraitCollection)
                    self.viewController?.present(actionSheetController, animated: false, completion: nil)
                })
            }
        }
    }

    /// Button must be manually shown _after_ adding using `showCreateButton`
    func add(to view: UIView, trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding)
        ])

        if #unavailable(iOS 26) {
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
                button.widthAnchor.constraint(equalToConstant: Constants.heightWidth),
            ])
        }

        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)
    }

    @objc func showCreateSheet() {
        guard let viewController else {
            return
        }

        // Temporarily show the sheet when the FAB is tapped on the Reader tab.
        if actions.count == 1 {
            actions.first?.handler()
        } else {
            let actionSheetVC = actionSheetController(with: viewController.traitCollection)
            viewController.present(actionSheetVC, animated: true, completion: { [weak self] in
                WPAnalytics.track(.createSheetShown, properties: ["source": self?.source ?? ""])
            })
        }
    }

    private func actionSheetController(with traitCollection: UITraitCollection) -> UIViewController {
        let actionSheetVC = CreateButtonActionSheet(headerView: createPromptHeaderView(), actions: actions)
        setupPresentation(on: actionSheetVC, for: traitCollection)
        return actionSheetVC
    }

    private func setupPresentation(on viewController: UIViewController, for traitCollection: UITraitCollection) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = button
        viewController.popoverPresentationController?.sourceRect = button.bounds.offsetBy(dx: 0, dy: Constants.popoverOffset)

        // Pre-compute `preferredContentSize`
        viewController.view.layoutIfNeeded()

        viewController.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.custom { [weak viewController] context in
            viewController?.preferredContentSize.height ?? 320
        }]

        if #available(iOS 18.0, *) {
            viewController.preferredTransition = .zoom { [weak self] _ in
                self?.button
            }
        }
    }

    func hideCreateButton() {
        if UIAccessibility.isReduceMotionEnabled {
            button.isHidden = true
        } else {
            button.springAnimation(toShow: false)
        }
    }

    func removeCreateButton() {
        button.removeFromSuperview()
    }

    func showCreateButton(for blog: Blog) {
        button.accessibilityHint = Strings.createPostHint
        showCreateButton()
    }

    private func showCreateButton() {
        if UIAccessibility.isReduceMotionEnabled {
            button.isHidden = false
        } else {
            button.springAnimation(toShow: true)
        }
    }
}

// MARK: - Blogging Prompts Methods

private extension CreateButtonCoordinator {

    private func fetchBloggingPrompt() {

        // TODO: check for cached prompt first.

        guard let bloggingPromptsService else {
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
              let blog,
              blog.isAccessibleThroughWPCom(),
              let prompt,
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

private extension UIButton {

    private enum Constants {
        enum Maximize {
            static let damping: CGFloat = 0.7
            static let duration: TimeInterval = 0.5
            static let initialScale: CGFloat = 0.0
            static let finalScale: CGFloat = 1.0
        }
        enum Minimize {
            static let damping: CGFloat = 0.9
            static let duration: TimeInterval = 0.25
            static let initialScale: CGFloat = 1.0
            static let finalScale: CGFloat = 0.001
        }
    }

    /// Animates the showing and hiding of a view using a spring animation
    /// - Parameter toShow: Whether to show the view
    func springAnimation(toShow: Bool) {
        if toShow {
            guard isHidden == true else { return }
            maximizeSpringAnimation()
        } else {
            guard isHidden == false else { return }
            minimizeSpringAnimation()
        }
    }

    /// Applies a spring animation, from size 1 to 0
    private func minimizeSpringAnimation() {
        let damping = Constants.Minimize.damping
        let scaleInitial = Constants.Minimize.initialScale
        let scaleFinal = Constants.Minimize.finalScale
        let duration = Constants.Minimize.duration

        scaleAnimation(duration: duration, damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal) { [weak self] success in
            self?.transform = .identity
            self?.isHidden = true
        }
    }

    /// Applies a spring animation, from size 0 to 1
    private func maximizeSpringAnimation() {
        let damping = Constants.Maximize.damping
        let scaleInitial = Constants.Maximize.initialScale
        let scaleFinal = Constants.Maximize.finalScale
        let duration = Constants.Maximize.duration

        scaleAnimation(duration: duration, damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal)
    }

    private func scaleAnimation(duration: TimeInterval, damping: CGFloat, scaleInitial: CGFloat, scaleFinal: CGFloat, completion: ((Bool) -> Void)? = nil) {
        setNeedsDisplay() // Make sure we redraw so that corners are rounded
        transform = CGAffineTransform(scaleX: scaleInitial, y: scaleInitial)
        isHidden = false

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping) {
            self.transform = CGAffineTransform(scaleX: scaleFinal, y: scaleFinal)
        }
        animator.addCompletion { (position) in
            completion?(true)
        }
        animator.startAnimation()
    }
}

private enum Strings {
    static let readerSource = "reader"
    static let createPostHint = NSLocalizedString("createPostSheet.createPostHint", value: "Create a post or page", comment: "Accessibility hint for create floating action button")
}
