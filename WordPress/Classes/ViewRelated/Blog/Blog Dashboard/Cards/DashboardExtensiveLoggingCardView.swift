import UIKit
import DesignSystem
import Support

class DashboardExtensiveLoggingCardView: UIView {

    var onTurnOffTapped: (() -> Void)?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.cardTitle)
        return frameView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(horizontal: 12, vertical: 4)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = Strings.message
        return label
    }()

    private lazy var turnOffButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.turnOffButtonTitle, for: .normal)
        button.setTitleColor(UIAppColor.primary, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(turnOffButtonTapped), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)
        cardFrameView.add(subview: containerStackView)

        containerStackView.addArrangedSubviews([messageLabel, turnOffButton])
    }

    @objc private func turnOffButtonTapped() {
        ExtensiveLogging.enabled = false

        Notice(title: Strings.noticeTitle, feedbackType: .success).post()

        onTurnOffTapped?()
    }
}

private enum Strings {
    static let cardTitle = NSLocalizedString(
        "dashboard.extensiveLogging.title",
        value: "Extension Logging",
        comment: "Title for the extension logging card on dashboard"
    )

    static let message = NSLocalizedString(
        "dashboard.extensiveLogging.message",
        value: "Extension logging is currently enabled. This helps with troubleshooting but may impact performance. Turn it off if you don't need it.",
        comment: "Message explaining that extension logging is enabled and should be turned off if not needed"
    )

    static let turnOffButtonTitle = NSLocalizedString(
        "dashboard.extensiveLogging.turnOff",
        value: "Turn Off",
        comment: "Button to turn off extension logging"
    )
    static let noticeTitle = NSLocalizedString(
        "dashboard.extensiveLogging.disabled",
        value: "Extension logging disabled",
        comment: "Notice shown when extension logging is successfully disabled"
    )
}
