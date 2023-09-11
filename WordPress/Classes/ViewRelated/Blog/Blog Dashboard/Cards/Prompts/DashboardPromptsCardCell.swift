import UIKit
import WordPressShared
import WordPressUI
import WordPressFlux

class DashboardPromptsCardCell: UICollectionViewCell, Reusable {
    // MARK: - Public Properties

    // This is public so it can be accessed from the BloggingPromptsFeatureDescriptionView.
    private(set) lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.cardFrameTitle)

        frameView.onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: .prompts)
        }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu

        return frameView
    }()

    // MARK: - Private Properties

    private var blog: Blog?

    private var prompt: BloggingPrompt? {
        didSet {
            refreshStackView()
        }
    }

    private var isAnswered: Bool {
        if forExampleDisplay {
            return false
        }

        return prompt?.answered ?? false
    }

    private lazy var bloggingPromptsService: BloggingPromptsService? = {
        return BloggingPromptsService(blog: blog)
    }()

    /// When set to true, a "default" version of the card is displayed. That is:
    /// - `maxAvatarCount` number of avatars.
    /// - `exampleAnswerCount` answer count.
    /// - `examplePrompt` prompt label.
    /// - disabled user interaction.
    private var forExampleDisplay: Bool = false {
        didSet {
            isUserInteractionEnabled = false
            cardFrameView.isUserInteractionEnabled = false
            refreshStackView()
        }
    }

    private var didFailLoadingPrompt: Bool = false {
        didSet {
            if didFailLoadingPrompt != oldValue {
                refreshStackView()
            }
        }
    }

    // This provides a quick way to toggle in flux features.
    // Since they probably will not be included in Blogging Prompts V1,
    // they are disabled by default.
    private let sharePromptEnabled = false

    // Used to present:
    // - The menu sheet for contextual menu in iOS13.
    // - The Blogging Prompts list when selected from the contextual menu.
    private weak var presenterViewController: BlogDashboardViewController? = nil

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
        stackView.layoutMargins = Constants.containerMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // MARK: Top row views

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.BloggingPrompts.promptContentFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private lazy var promptTitleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(promptLabel)
        view.pinSubviewToAllEdges(promptLabel, insets: UIEdgeInsets(top: Constants.spacing, left: 0, bottom: 0, right: 0))

        return view
    }()

    // MARK: Middle row views

    private var answerCount: Int {
        if forExampleDisplay {
            return Constants.exampleAnswerCount
        }

        return Int(prompt?.answerCount ?? 0)
    }

    private var answerInfoText: String {
        if RemoteFeatureFlag.bloggingPromptsSocial.enabled() {
            return Strings.viewAllResponses
        }

        let stringFormat = (answerCount == 1 ? Strings.answerInfoSingularFormat : Strings.answerInfoPluralFormat)
        return String(format: stringFormat, answerCount)
    }

    private var avatarTrainContainerView: UIView {
        let avatarURLs: [URL?] = {
            if forExampleDisplay {
                return (0..<Constants.maxAvatarCount).map { _ in nil }
            }

            guard let displayAvatarURLs = prompt?.displayAvatarURLs else {
                return []
            }

            return Array(displayAvatarURLs.prefix(min(answerCount, Constants.maxAvatarCount)))
        }()

        let avatarTrainView = AvatarTrainView(avatarURLs: avatarURLs, placeholderImage: Style.avatarPlaceholderImage)
        avatarTrainView.translatesAutoresizingMaskIntoConstraints = false

        let trainContainerView = UIView()
        trainContainerView.translatesAutoresizingMaskIntoConstraints = false
        trainContainerView.addSubview(avatarTrainView)
        NSLayoutConstraint.activate([
            trainContainerView.centerYAnchor.constraint(equalTo: avatarTrainView.centerYAnchor),
            trainContainerView.topAnchor.constraint(lessThanOrEqualTo: avatarTrainView.topAnchor),
            trainContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: avatarTrainView.bottomAnchor),
            trainContainerView.leadingAnchor.constraint(equalTo: avatarTrainView.leadingAnchor),
            trainContainerView.trailingAnchor.constraint(equalTo: avatarTrainView.trailingAnchor)
        ])

        return trainContainerView
    }

    private var answerInfoButton: UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(answerInfoText, for: .normal)
        button.titleLabel?.font = WPStyleGuide.BloggingPrompts.answerInfoButtonFont
        button.setTitleColor(
            RemoteFeatureFlag.bloggingPromptsSocial.enabled()
            ? WPStyleGuide.BloggingPrompts.buttonTitleColor
            : WPStyleGuide.BloggingPrompts.answerInfoButtonColor,
            for: .normal
        )
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(didTapAnswerInfoButton), for: .touchUpInside)
        return button
    }

    @objc
    private func didTapAnswerInfoButton() {
        guard RemoteFeatureFlag.bloggingPromptsSocial.enabled(),
              let promptID = prompt?.promptID else {
            return
        }
        RootViewCoordinator.sharedPresenter.readerCoordinator?.showTag(named: "\(Constants.dailyPromptTag)-\(promptID)")
        WPAnalytics.track(.promptsOtherAnswersTapped)
    }

    private var answerInfoView: UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.answerInfoViewSpacing
        stackView.addArrangedSubviews([avatarTrainContainerView, answerInfoButton])

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: stackView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            containerView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            containerView.leadingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor)
        ])

        return containerView
    }

    private lazy var attributionIcon = UIImageView()

    private lazy var attributionSourceLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var attributionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [attributionIcon, attributionSourceLabel])
        stackView.alignment = .center
        return stackView
    }()

    // MARK: Bottom row views

    private lazy var answerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.answerButtonTitle, for: .normal)
        button.setTitleColor(WPStyleGuide.BloggingPrompts.buttonTitleColor, for: .normal)
        button.titleLabel?.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(answerButtonTapped), for: .touchUpInside)

        return button
    }()

    private lazy var answeredLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        label.textColor = WPStyleGuide.BloggingPrompts.answeredLabelColor
        label.text = Strings.answeredLabelTitle

        // The 'answered' label needs to be close to the Share button.
        // swiftlint:disable:next inverse_text_alignment
        label.textAlignment = (effectiveUserInterfaceLayoutDirection == .leftToRight ? .right : .left)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true

        return label
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.shareButtonTitle, for: .normal)
        button.setTitleColor(WPStyleGuide.BloggingPrompts.buttonTitleColor, for: .normal)
        button.titleLabel?.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.contentHorizontalAlignment = .leading

        // TODO: Implement button tap action

        return button
    }()

    private lazy var answeredStateView: UIView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.answeredButtonsSpacing
        stackView.addArrangedSubviews(sharePromptEnabled ? [answeredLabel, shareButton] : [answeredLabel])

        // center the stack view's contents based on its total intrinsic width (instead of having it stretched edge to edge).
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: stackView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            containerView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            containerView.leadingAnchor.constraint(lessThanOrEqualTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor)
        ])

        return containerView
    }()

    // Defines the structure of the contextual menu items.
    private var contextMenuItems: [[MenuItem]] {
        let viewMoreMenuTapped = { [weak self] in
            guard let self else { return }
            self.viewMoreMenuTapped()
        }

        let skipMenuTapped = { [weak self] in
            guard let self else { return }
            self.skipMenuTapped()
        }

        let learnMoreTapped = { [weak self] in
            guard let self else { return }
            self.learnMoreTapped()
        }

        let removeMenuTapped = { [weak self] in
            guard let self else { return }
            self.removeMenuTapped()
        }

        let defaultItems: [MenuItem] = [
            .viewMore(viewMoreMenuTapped),
            .skip(skipMenuTapped)
        ]

        return [defaultItems, [.learnMore(learnMoreTapped)], [.remove(removeMenuTapped)]]
    }

    private var contextMenu: UIMenu {
        return .init(title: String(), options: .displayInline, children: contextMenuItems.map { menuSection in
            UIMenu(title: String(), options: .displayInline, children: [
                // Use an uncached deferred element so we can track each time the menu is shown
                UIDeferredMenuElement.uncached { completion in
                    WPAnalytics.track(.promptsDashboardCardMenu)
                    completion(menuSection.map { $0.toAction })
                }
            ])
        })
    }

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        observeManagedObjectsChange()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        //  refresh when the appearance style changed so the placeholder images are correctly recolored.
        if let previousTraitCollection = previousTraitCollection,
            previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle {
            refreshStackView()
        }
    }

    // MARK: - Public Methods

    func configureForExampleDisplay() {
        forExampleDisplay = true
    }

    // Class method to determine if the Dashboard should show this card.
    // Specifically, it checks if today's prompt has been skipped,
    // and therefore should not be shown.
    static func shouldShowCard(for blog: Blog) -> Bool {
        guard AppConfiguration.bloggingPromptsEnabled,
              blog.isAccessibleThroughWPCom(),
              let promptsService = BloggingPromptsService(blog: blog) else {
            return false
        }

        guard let todaysPrompt = promptsService.localTodaysPrompt else {
            // If there is no cached prompt, it can't have been skipped. So show the card.
            return true
        }

        return !userSkippedPrompt(todaysPrompt, for: blog)
    }

}

// MARK: - BlogDashboardCardConfigurable

extension DashboardPromptsCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presenterViewController = viewController
        fetchPrompt()
    }
}

// MARK: - Private Helpers

private extension DashboardPromptsCardCell {

    // MARK: Configure View

    func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Constants.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    func refreshStackView() {
        // clear existing views.
        containerStackView.removeAllSubviews()

        guard !didFailLoadingPrompt else {
            promptLabel.text = Strings.errorTitle
            containerStackView.addArrangedSubview(promptTitleView)
            return
        }

        promptLabel.text = forExampleDisplay ? Strings.examplePrompt : prompt?.textForDisplay()
        containerStackView.addArrangedSubview(promptTitleView)

        if let attribution = prompt?.promptAttribution {
            attributionIcon.image = attribution.iconImage
            attributionSourceLabel.attributedText = attribution.attributedText
            containerStackView.addArrangedSubview(attributionStackView)
        }

        if answerCount > 0 {
            containerStackView.addArrangedSubview(answerInfoView)
        }

        containerStackView.addArrangedSubview((isAnswered ? answeredStateView : answerButton))
        presenterViewController?.collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Managed object observer

    func observeManagedObjectsChange() {
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleObjectsChange),
                name: .NSManagedObjectContextObjectsDidChange,
                object: ContextManager.shared.mainContext
        )
    }

    @objc func handleObjectsChange(_ notification: Foundation.Notification) {
        guard let prompt = prompt else {
            return
        }
        let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let refreshed = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set()

        if updated.contains(prompt) || refreshed.contains(prompt) {
            refreshStackView()
        }
    }

    // MARK: Prompt Fetching

    func fetchPrompt() {
        guard let bloggingPromptsService = bloggingPromptsService else {
            didFailLoadingPrompt = true
            DDLogError("Failed creating BloggingPromptsService instance.")
            return
        }

        bloggingPromptsService.todaysPrompt(success: { [weak self] (prompt) in
            self?.prompt = prompt
            self?.didFailLoadingPrompt = false
        }, failure: { [weak self] (error) in
            self?.prompt = nil
            self?.didFailLoadingPrompt = true
            DDLogError("Failed fetching blogging prompt: \(String(describing: error))")
        })
    }

    // MARK: Button actions

    @objc func answerButtonTapped() {
        guard let blog = blog,
              let prompt = prompt else {
            return
        }
        WPAnalytics.track(.promptsDashboardCardAnswerPrompt)

        let editor = EditPostViewController(blog: blog, prompt: prompt)
        editor.modalPresentationStyle = .fullScreen
        editor.entryPoint = .bloggingPromptsDashboardCard
        presenterViewController?.present(editor, animated: true)
    }

    // MARK: Context menu actions

    func viewMoreMenuTapped() {
        guard let blog = blog,
              let presenterViewController = presenterViewController else {
            DDLogError("Failed showing Blogging Prompts from Dashboard card. Missing blog or controller.")
            return
        }

        WPAnalytics.track(.promptsDashboardCardMenuViewMore)
        BloggingPromptsViewController.show(for: blog, from: presenterViewController)
    }

    func skipMenuTapped() {
        WPAnalytics.track(.promptsDashboardCardMenuSkip)
        saveSkippedPromptForSite()
        presenterViewController?.reloadCardsLocally()
        let notice = Notice(title: Strings.promptSkippedTitle, feedbackType: .success, actionTitle: Strings.undoSkipTitle) { [weak self] _ in
            self?.clearSkippedPromptForSite()
            self?.presenterViewController?.reloadCardsLocally()
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func removeMenuTapped() {
        guard let siteID = blog?.dotComID?.intValue else {
            return
        }
        WPAnalytics.track(.promptsDashboardCardMenuRemove)
        BlogDashboardAnalytics.trackHideTapped(for: .prompts)
        let service = BlogDashboardPersonalizationService(siteID: siteID)
        service.setEnabled(false, for: .prompts)
        if !AppConfiguration.personalizeHomeTabEnabled {
            let notice = Notice(title: Strings.promptRemovedTitle, message: Strings.promptRemovedSubtitle, feedbackType: .success, actionTitle: Strings.undoSkipTitle) { _ in
                service.setEnabled(true, for: .prompts)
            }
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }

    func learnMoreTapped() {
        WPAnalytics.track(.promptsDashboardCardMenuLearnMore)
        guard let presenterViewController = presenterViewController else {
            return
        }
        BloggingPromptsIntroductionPresenter(interactionType: .actionable(blog: blog)).present(from: presenterViewController)
    }

    // MARK: Constants

    struct Strings {
        static let examplePrompt = NSLocalizedString("Cast the movie of your life.", comment: "Example prompt for the Prompts card in Feature Introduction.")
        static let cardFrameTitle = NSLocalizedString("Prompts", comment: "Title label for the Prompts card in My Sites tab.")
        static let answerButtonTitle = NSLocalizedString("Answer Prompt", comment: "Title for a call-to-action button on the prompts card.")
        static let answeredLabelTitle = NSLocalizedString("✓ Answered", comment: "Title label that indicates the prompt has been answered.")
        static let shareButtonTitle = NSLocalizedString("Share", comment: "Title for a button that allows the user to share their answer to the prompt.")
        static let answerInfoSingularFormat = NSLocalizedString("%1$d answer", comment: "Singular format string for displaying the number of users "
                                                                + "that answered the blogging prompt.")
        static let answerInfoPluralFormat = NSLocalizedString("%1$d answers", comment: "Plural format string for displaying the number of users "
                                                              + "that answered the blogging prompt.")
        static let viewAllResponses = NSLocalizedString("prompts.card.viewprompts.title",
                                                        value: "View all responses",
                                                        comment: "Title for a tappable string that opens the reader with a prompts tag")
        static let errorTitle = NSLocalizedString("Error loading prompt", comment: "Text displayed when there is a failure loading a blogging prompt.")
        static let promptSkippedTitle = NSLocalizedString("Prompt skipped", comment: "Title of the notification presented when a prompt is skipped")
        static let undoSkipTitle = NSLocalizedString("Undo", comment: "Button in the notification presented when a prompt is skipped")
        static let promptRemovedTitle = NSLocalizedString("prompts.notification.removed.title",
                                                          value: "Blogging Prompts hidden",
                                                          comment: "Title of the notification when prompts are hidden from the dashboard card")
        static let promptRemovedSubtitle = NSLocalizedString("prompts.notification.removed.subtitle",
                                                             value: "Visit Site Settings to turn back on",
                                                             comment: "Subtitle of the notification when prompts are hidden from the dashboard card")
    }

    struct Style {
        static let frameIconImage = UIImage(named: "icon-lightbulb-outline")?.resizedImage(Constants.cardIconSize, interpolationQuality: .default)
        static var avatarPlaceholderImage: UIImage {
            // this needs to be computed so the color is correct depending on the user interface style.
            return UIImage(color: .init(light: .quaternarySystemFill, dark: .systemGray4))
        }
    }

    struct Constants {
        static let spacing: CGFloat = 12
        static let answeredButtonsSpacing: CGFloat = 16
        static let answerInfoViewSpacing: CGFloat = 6
        static let containerMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let maxAvatarCount = 3
        static let exampleAnswerCount = 19
        static let cardIconSize = CGSize(width: 18, height: 18)
        static let cardFrameConstraintPriority = UILayoutPriority(999)
        static let skippedPromptsUDKey = "wp_skipped_blogging_prompts"
        static let dailyPromptTag = "dailyprompt"
    }

    // MARK: Contextual Menu

    enum MenuItem {
        case viewMore(_ handler: () -> Void)
        case skip(_ handler: () -> Void)
        case remove(_ handler: () -> Void)
        case learnMore(_ handler: () -> Void)

        var title: String {
            switch self {
            case .viewMore:
                return NSLocalizedString("View more prompts", comment: "Menu title to show more prompts.")
            case .skip:
                return NSLocalizedString("Skip for today", comment: "Menu title to skip today's prompt.")
            case .remove:
                return NSLocalizedString("Turn off prompts", comment: "Destructive menu title to remove the prompt card from the dashboard.")
            case .learnMore:
                return NSLocalizedString("Learn more", comment: "Menu title to show the prompts feature introduction modal.")
            }
        }

        var image: UIImage? {
            switch self {
            case .viewMore:
                return .init(systemName: "ellipsis.circle")
            case .skip:
                return .init(systemName: "xmark.circle")
            case .remove:
                return .init(systemName: "minus.circle")
            case .learnMore:
                return .init(systemName: "info.circle")
            }
        }

        var menuAttributes: UIMenuElement.Attributes {
            switch self {
            case .remove:
                return .destructive
            default:
                return []
            }
        }

        var toAction: UIAction {
            switch self {
            case .viewMore(let handler),
                 .skip(let handler),
                 .remove(let handler),
                 .learnMore(let handler):
                return UIAction(title: title, image: image, attributes: menuAttributes) { _ in
                    handler()
                }
            }
        }
    }
}

// MARK: - User Defaults

private extension DashboardPromptsCardCell {

    static var allSkippedPrompts: [[String: Int32]] {
        return UserPersistentStoreFactory.instance().array(forKey: Constants.skippedPromptsUDKey) as? [[String: Int32]] ?? []
    }

    func saveSkippedPromptForSite() {
        guard let prompt = prompt,
        let siteID = blog?.dotComID?.stringValue else {
            return
        }

        clearSkippedPromptForSite()

        let skippedPrompt = [siteID: prompt.promptID]
        var updatedSkippedPrompts = DashboardPromptsCardCell.allSkippedPrompts
        updatedSkippedPrompts.append(skippedPrompt)

        UserPersistentStoreFactory.instance().set(updatedSkippedPrompts, forKey: Constants.skippedPromptsUDKey)
    }

    func clearSkippedPromptForSite() {
        guard let siteID = blog?.dotComID?.stringValue else {
            return
        }

        let updatedSkippedPrompts = DashboardPromptsCardCell.allSkippedPrompts.filter { $0.keys.first != siteID }
        UserPersistentStoreFactory.instance().set(updatedSkippedPrompts, forKey: Constants.skippedPromptsUDKey)
    }

    static func userSkippedPrompt(_ prompt: BloggingPrompt, for blog: Blog) -> Bool {
        guard AppConfiguration.bloggingPromptsEnabled,
            let siteID = blog.dotComID?.stringValue else {
            return false
        }

        let siteSkippedPrompts = allSkippedPrompts.filter { $0.keys.first == siteID }
        let matchingPrompts = siteSkippedPrompts.filter { $0.values.first == prompt.promptID }

        return !matchingPrompts.isEmpty
    }

}
