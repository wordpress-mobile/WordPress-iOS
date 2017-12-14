import UIKit

class NoticeView: UIView {
    private let backgroundView =  UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    private let actionBackgroundView = UIView()

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionLabel = UILabel()

    var dismissHandler: (() -> Void)?

    init(notice: Notice) {
        super.init(frame: .zero)

        layer.cornerRadius = Appearance.cornerRadius
        layer.masksToBounds = true

        configureBackgroundViews()
        configureLabels()
        configureForNotice(notice)
        configureDismissRecognizer()
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

    private func configureLabels() {
        let labelStackView = UIStackView()
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Appearance.labelLineSpacing
        labelStackView.isBaselineRelativeArrangement = true
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        actionBackgroundView.addSubview(actionLabel)
        backgroundView.contentView.addSubview(labelStackView)

        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionLabel.leadingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.leadingAnchor),
            actionLabel.trailingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.trailingAnchor),
            actionLabel.topAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.topAnchor),
            actionLabel.bottomAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            labelStackView.leadingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leadingAnchor),
            labelStackView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: actionBackgroundView.leadingAnchor),
            labelStackView.topAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        actionLabel.font = Appearance.actionLabelFont
        titleLabel.font = Appearance.titleLabelFont
        messageLabel.font = Appearance.messageLabelFont

        actionLabel.textColor = WPStyleGuide.mediumBlue()
        titleLabel.textColor = WPStyleGuide.darkGrey()
        messageLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func configureForNotice(_ notice: Notice) {
        titleLabel.text = notice.title
        messageLabel.text = notice.message

        if let actionTitle = notice.actionTitle {
            actionLabel.text = actionTitle
        } else {
            actionBackgroundView.isHidden = true
        }
    }

    private func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)
    }

    // MARK: - Action handlers

    @objc private func viewTapped() {
        dismissHandler?()
    }

    enum Appearance {
        static let cornerRadius: CGFloat = 13.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let actionBackgroundColor = UIColor.white.withAlphaComponent(0.5)
        static let actionLabelFont = UIFont.systemFont(ofSize: 14.0)
        static let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
        static let labelLineSpacing: CGFloat = 18.0
    }
}
