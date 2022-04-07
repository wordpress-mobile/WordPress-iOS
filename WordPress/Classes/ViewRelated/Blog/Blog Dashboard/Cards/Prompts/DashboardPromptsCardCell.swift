import UIKit
import WordPressShared

class DashboardPromptsCardCell: UICollectionViewCell, Reusable {


    /// Controls available actions on the bottom row.
    /// TODO: Might need to review this once we have a better picture of what the Prompt model looks like.
    var isAnswered: Bool = true {
        didSet {
            refreshStackView()
        }
    }

    // MARK: Private Properties

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

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
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

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.promptContentFont
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

    private lazy var answerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.answerButtonTitle, for: .normal)
        button.setTitleColor(Style.buttonTitleColor, for: .normal)
        button.titleLabel?.font = Style.buttonTitleFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true

        return button
    }()

    private lazy var answeredLabel: UILabel = {
        let label = UILabel()
        label.font = Style.buttonTitleFont
        label.textColor = Style.answeredLabelColor
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
        button.setTitleColor(Style.buttonTitleColor, for: .normal)
        button.titleLabel?.font = Style.buttonTitleFont
        button.contentHorizontalAlignment = .leading

        // TODO: Implement button tap action

        return button
    }()

    private lazy var answeredStateView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = Constants.answeredButtonsSpacing

        // added some spacer views to make the label and button look more centered together.
        stackView.addArrangedSubviews([UIView(), answeredLabel, shareButton, UIView()])

        return stackView
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

        // TODO: For testing purposes. Remove once we can pull content from remote.
        promptLabel.text = "Cast the movie of your life."

        // TODO: Add train of avatars view.
        containerStackView.addArrangedSubviews([promptTitleView, (isAnswered ? answeredStateView : answerButton)])
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
        static let cardFrameTitle = NSLocalizedString("Prompts", comment: "Title label for the Prompts card in My Sites tab.")
        static let answerButtonTitle = NSLocalizedString("Answer Prompt", comment: "Title for a call-to-action button on the prompts card.")
        static let answeredLabelTitle = NSLocalizedString("✓ Answered", comment: "Title label that indicates the prompt has been answered.")
        static let shareButtonTitle = NSLocalizedString("Share", comment: "Title for a button that allows the user to share their answer to the prompt.")
    }

    struct Style {
        static let frameIconImage = UIImage(systemName: "lightbulb")
        static let promptContentFont = WPStyleGuide.serifFontForTextStyle(.headline, fontWeight: .semibold)
        static let buttonTitleFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let buttonTitleColor = UIColor.primary
        static let answeredLabelColor = UIColor.muriel(name: .green, .shade50)
    }

    struct Constants {
        static let spacing: CGFloat = 12
        static let answeredButtonsSpacing: CGFloat = 16
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
