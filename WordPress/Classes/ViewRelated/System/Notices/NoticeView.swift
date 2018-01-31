import UIKit

class NoticeView: UIView {
    private let contentStackView = UIStackView()

    private let backgroundView =  UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    private let actionBackgroundView = UIView()

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    private let notice: Notice

    var dismissHandler: (() -> Void)?

    init(notice: Notice) {
        self.notice = notice

        super.init(frame: .zero)

        layer.cornerRadius = Appearance.cornerRadius
        layer.masksToBounds = true

        configureBackgroundViews()
        configureContentStackView()
        configureLabels()
        configureActionButton()
        configureDismissRecognizer()

        configureForNotice()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBackgroundViews() {
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)
    }

    private func configureContentStackView() {
        contentStackView.axis = .horizontal
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(contentStackView)
        backgroundView.contentView.pinSubviewToAllEdges(contentStackView)
    }

    private func configureLabels() {
        let labelStackView = UIStackView()
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Appearance.labelLineSpacing
        labelStackView.isBaselineRelativeArrangement = true
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = Appearance.layoutMargins

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        contentStackView.addArrangedSubview(labelStackView)

        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor)
            ])

        titleLabel.font = Appearance.titleLabelFont
        messageLabel.font = Appearance.messageLabelFont

        titleLabel.textColor = WPStyleGuide.darkGrey()
        messageLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func configureActionButton() {
        contentStackView.addArrangedSubview(actionBackgroundView)
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        actionBackgroundView.layoutMargins = Appearance.layoutMargins
        actionBackgroundView.backgroundColor = Appearance.actionBackgroundColor

        actionBackgroundView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionBackgroundView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            actionBackgroundView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),
            ])

        actionBackgroundView.pinSubviewToAllEdgeMargins(actionButton)

        actionButton.titleLabel?.font = Appearance.actionButtonFont
        actionButton.setTitleColor(WPStyleGuide.mediumBlue(), for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)
    }

    private func configureForNotice() {
        titleLabel.text = notice.title

        if let message = notice.message {
            messageLabel.text = message
        } else {
            titleLabel.numberOfLines = 2
        }

        if let actionTitle = notice.actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
        } else {
            actionBackgroundView.isHidden = true
        }
    }

    // MARK: - Action handlers

    @objc private func viewTapped() {
        dismissHandler?()
    }

    @objc private func actionButtonTapped() {
        notice.actionHandler?()
        dismissHandler?()
    }

    enum Appearance {
        static let cornerRadius: CGFloat = 13.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let actionBackgroundColor = UIColor.white.withAlphaComponent(0.5)
        static let actionButtonFont = UIFont.systemFont(ofSize: 14.0)
        static let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
        static let labelLineSpacing: CGFloat = 18.0
    }
}
