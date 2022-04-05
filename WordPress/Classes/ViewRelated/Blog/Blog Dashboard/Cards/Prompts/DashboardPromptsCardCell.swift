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
        frameView.onEllipsisButtonTap = { [weak self] in
            // TODO: Show contextual menu.
            // TODO: For testing purposes; added to make it easier to toggle answered state.
            self?.isAnswered.toggle()
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
        refreshStackView()
    }
}

// MARK: - Constants

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
}
