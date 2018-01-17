import UIKit

class NoticeView: UIView {
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
        configureActionButton()
        configureLabels()
        configureDismissRecognizer()

        configureForNotice()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBackgroundViews() {
        addSubview(backgroundView)
        addSubview(actionBackgroundView)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        actionBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            actionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            actionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        backgroundView.layoutMargins = Appearance.layoutMargins
        actionBackgroundView.layoutMargins = Appearance.layoutMargins

        actionBackgroundView.backgroundColor = Appearance.actionBackgroundColor
    }

    private func configureActionButton() {
        actionBackgroundView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.trailingAnchor),
            actionButton.topAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        actionButton.titleLabel?.font = Appearance.actionButtonFont
        actionButton.setTitleColor(WPStyleGuide.mediumBlue(), for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    private func configureLabels() {
        let labelStackView = UIStackView()
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Appearance.labelLineSpacing
        labelStackView.isBaselineRelativeArrangement = true
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        backgroundView.contentView.addSubview(labelStackView)

        labelStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            labelStackView.leadingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leadingAnchor),
            labelStackView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: actionBackgroundView.leadingAnchor, constant: -Appearance.layoutMargins.right),
            labelStackView.topAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        titleLabel.font = Appearance.titleLabelFont
        messageLabel.font = Appearance.messageLabelFont

        titleLabel.textColor = WPStyleGuide.darkGrey()
        messageLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)
    }

    private func configureForNotice() {
        titleLabel.text = notice.title
        messageLabel.text = notice.message

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
