import UIKit
import WordPressShared

class DashboardPromptsCardCell: UICollectionViewCell, Reusable {

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
        frameView.onEllipsisButtonTap = {
            // TODO: Show contextual menu.
        }

        return frameView
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.promptContentFont
        label.textAlignment = .center
        label.numberOfLines = 0

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
        return button
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
        // clear existing views.
        containerStackView.removeAllSubviews()

        // TODO: For testing purposes. Remove once we can pull content from remote.
        promptLabel.text = "Cast the movie of your life."

        // TODO: Add train of avatars view.
        // TODO: Add 'answered' state, which shows the "Answered" text and Share button.
        containerStackView.addArrangedSubviews([promptTitleView, answerButton])
    }
}

// MARK: - Constants

private extension DashboardPromptsCardCell {

    func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Constants.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    struct Strings {
        static let cardFrameTitle = NSLocalizedString("Prompts", comment: "Title label for the Prompts card in My Sites tab.")
        static let answerButtonTitle = NSLocalizedString("Answer Prompt", comment: "Title for a call-to-action button on the prompts card.")
    }

    struct Style {
        static let frameIconImage = UIImage(systemName: "lightbulb")
        static let promptContentFont = WPStyleGuide.serifFontForTextStyle(.headline, fontWeight: .semibold)
        static let buttonTitleFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let buttonTitleColor = UIColor.primary
    }

    struct Constants {
        static let spacing: CGFloat = 12
        static let cardFrameConstraintPriority = UILayoutPriority(999)
    }
}
