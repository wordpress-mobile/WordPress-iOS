import UIKit
import WordPressShared
import WordPressUI

class DashboardPromptsCardCell: UICollectionViewCell, Reusable {


    /// Controls available actions on the bottom row.
    /// TODO: Might need to review this once we have a better picture of what the Prompt model looks like.
    var isAnswered: Bool = true {
        didSet {
            refreshStackView()
        }
    }

    // This is public so it can be accessed from the BloggingPromptsFeatureDescriptionView.
    private(set) lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.title = Strings.cardFrameTitle
        frameView.icon = Style.frameIconImage

        // NOTE: Remove the logic for iOS 13 once we drop that version.
        if #available (iOS 14.0, *) {
            // assign an empty closure so the button appears.
            frameView.onEllipsisButtonTap = {}
            frameView.ellipsisButton.showsMenuAsPrimaryAction = true
            frameView.ellipsisButton.menu = contextMenu
        } else {
            // Show a fallback implementation using `MenuSheetViewController`.
            // iOS 13 doesn't support showing UIMenu programmatically.
            frameView.onEllipsisButtonTap = { [weak self] in
                self?.showMenuSheet()
            }
        }

        return frameView
    }()

    // MARK: - Private Properties

    /// When set to true, a "default" version of the card is displayed. That is:
    /// - `maxAvatarCount` number of avatars.
    /// - `maxAvatarCount` answer count.
    /// - `examplePrompt` prompt label.
    /// - disabled user interaction.
    private var forExampleDisplay: Bool = false {
        didSet {
            isUserInteractionEnabled = false
            isAnswered = false
        }
    }

    // Used to present the menu sheet for contextual menu.
    // NOTE: Remove this once we drop support for iOS 13.
    private weak var presenterViewController: BlogDashboardViewController? = nil

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
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
        view.pinSubviewToAllEdges(promptLabel, insets: .init(top: Constants.spacing, left: 0, bottom: 0, right: 0))

        return view
    }()

    // MARK: Middle row views

    private lazy var answerCount: Int = {
        if forExampleDisplay {
            return Constants.exampleAnswerCount
        }
        // TODO: For testing purposes. Remove once we actually have real avatar URLs.
        return 3
    }()

    private var answerInfoText: String {
        let stringFormat = (answerCount == 1 ? Strings.answerInfoSingularFormat : Strings.answerInfoPluralFormat)
        return String(format: stringFormat, answerCount)
    }

    private var avatarTrainContainerView: UIView {
        let avatarURLs: [URL?] = {
            if forExampleDisplay {
                return (0..<Constants.maxAvatarCount).map { _ in nil }
            }
            // TODO: Refactor this once we have real avatar URLs.
            return (0..<min(answerCount, Constants.maxAvatarCount)).map { _ in nil }
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

    private var answerInfoLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = answerInfoText
        label.font = WPStyleGuide.BloggingPrompts.answerInfoLabelFont
        label.textColor = WPStyleGuide.BloggingPrompts.answerInfoLabelColor
        label.textAlignment = (effectiveUserInterfaceLayoutDirection == .leftToRight ? .left : .right)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }

    private var answerInfoView: UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.answerInfoViewSpacing
        stackView.addArrangedSubviews([avatarTrainContainerView, answerInfoLabel])

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

    // MARK: Bottom row views

    private lazy var answerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.answerButtonTitle, for: .normal)
        button.setTitleColor(WPStyleGuide.BloggingPrompts.buttonTitleColor, for: .normal)
        button.titleLabel?.font = WPStyleGuide.BloggingPrompts.buttonTitleFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true

        // TODO: Implement button tap action

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
        stackView.addArrangedSubviews([answeredLabel, shareButton])

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
        return [
            [
                .viewMore(viewMoreMenuTapped),
                .skip(skipMenuTapped)
            ],
            [
                .remove(removeMenuTapped)
            ]
        ]
    }

    private var contextMenu: UIMenu {
        return .init(title: String(), options: .displayInline, children: contextMenuItems.map { menuSection in
            UIMenu(title: String(), options: .displayInline, children: menuSection.map { $0.toAction })
        })
    }

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
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

}

// MARK: - BlogDashboardCardConfigurable

extension DashboardPromptsCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.presenterViewController = viewController
        refreshStackView()
    }
}

// MARK: - Private Helpers

private extension DashboardPromptsCardCell {

    func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Constants.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    func refreshStackView() {
        // clear existing views.
        containerStackView.removeAllSubviews()

        // TODO: Remove the hard coded string once we can pull content from remote.
        promptLabel.text = forExampleDisplay ? Strings.examplePrompt : "Cast the movie of your life."

        containerStackView.addArrangedSubview(promptTitleView)

        if answerCount > 0 {
            containerStackView.addArrangedSubview(answerInfoView)
        }

        containerStackView.addArrangedSubview((isAnswered ? answeredStateView : answerButton))
    }

    // MARK: Context menu actions

    func viewMoreMenuTapped() {
        // TODO.
    }

    func skipMenuTapped() {
        // TODO.
    }

    func removeMenuTapped() {
        // TODO.
    }

    // Fallback context menu implementation for iOS 13.
    func showMenuSheet() {
        guard let presenterViewController = presenterViewController else {
            return
        }

        let menuViewController = MenuSheetViewController(items: contextMenuItems.map { menuSection in
            menuSection.map { $0.toMenuSheetItem }
        })

        menuViewController.modalPresentationStyle = .popover
        if let popoverPresentationController = menuViewController.popoverPresentationController {
            popoverPresentationController.delegate = presenterViewController
            popoverPresentationController.sourceView = cardFrameView.ellipsisButton
            popoverPresentationController.sourceRect = cardFrameView.ellipsisButton.bounds
        }

        presenterViewController.present(menuViewController, animated: true)
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
        static let maxAvatarCount = 3
        static let exampleAnswerCount = 19
        static let cardIconSize = CGSize(width: 18, height: 18)
        static let cardFrameConstraintPriority = UILayoutPriority(999)
    }

    // MARK: Contextual Menu

    enum MenuItem {
        case viewMore(_ handler: () -> Void)
        case skip(_ handler: () -> Void)
        case remove(_ handler: () -> Void)

        var title: String {
            switch self {
            case .viewMore:
                return NSLocalizedString("View more prompts", comment: "Menu title to show more prompts.")
            case .skip:
                return NSLocalizedString("Skip this prompt", comment: "Menu title to skip today's prompt.")
            case .remove:
                return NSLocalizedString("Remove from dashboard", comment: "Destructive menu title to remove the prompt card from the dashboard.")
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
                    .remove(let handler):
                return .init(title: title, image: image, attributes: menuAttributes, handler: { _ in
                    handler()
                })
            }
        }

        var toMenuSheetItem: MenuSheetViewController.MenuItem {
            switch self {
            case .viewMore(let handler),
                    .skip(let handler),
                    .remove(let handler):
                return .init(title: title, image: image, destructive: menuAttributes.contains(.destructive), handler: handler)
            }
        }
    }
}
