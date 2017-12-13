import UIKit

class NoticeView: UIView {
    private let backgroundView =  UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    private let actionBackgroundView = UIView()

    private let descriptionLabel = UILabel()
    private let actionLabel = UILabel()

    init(notice: Notice) {
        super.init(frame: .zero)

        layer.cornerRadius = Appearance.cornerRadius
        layer.masksToBounds = true

        configureBackgroundViews()
        configureLabels()
        configureForNotice(notice)
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
        actionBackgroundView.addSubview(actionLabel)
        backgroundView.contentView.addSubview(descriptionLabel)

        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            actionLabel.leadingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.leadingAnchor),
            actionLabel.trailingAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.trailingAnchor),
            actionLabel.topAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.topAnchor),
            actionLabel.bottomAnchor.constraint(equalTo: actionBackgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.topAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.bottomAnchor)
            ])

        actionLabel.font = Appearance.actionLabelFont
        descriptionLabel.font = Appearance.actionButtonFont

        actionLabel.textColor = WPStyleGuide.mediumBlue()
        descriptionLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func configureForNotice(_ notice: Notice) {
        descriptionLabel.text = notice.title

        if let actionTitle = notice.actionTitle {
            actionLabel.text = actionTitle
        } else {
            actionBackgroundView.isHidden = true
        }
    }

    enum Appearance {
        static let cornerRadius: CGFloat = 13.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let actionBackgroundColor = UIColor.white.withAlphaComponent(0.5)
        static let actionLabelFont = UIFont.systemFont(ofSize: 14.0)
        static let actionButtonFont = UIFont.systemFont(ofSize: 14.0)
    }
}
