import UIKit
import WordPressShared

class CustomizeInsightsCell: UITableViewCell, Accessible {

    // MARK: - Properties

    private let titleLabel = UILabel.makeStatsLabel(text: "Customize your insights", textStyle: .title3)
    private let contentLabel = UILabel.makeStatsLabel(
        text:
            "Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.",
        textStyle: .body,
        numberOfLines: 0
    )
    private let dismissButton = makeButton(title: "Dismiss")
    private let tryButton = makeButton(title: "Try it now")
    private let bottomSeparatorLine: UIView = {
        let view = UIView.makeStatsSeparator()
        view.backgroundColor = UIColor(white: 0.667, alpha: 1)
        return view
    }()

    private weak var insightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.clipsToBounds = true
        contentView.contentMode = .center

        let imageView = UIImageView(image: UIImage(named: "insights-management-feature-image"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)

        dismissButton.addTarget(self, action: #selector(didTapDismissButton), for: .touchUpInside)
        tryButton.addTarget(self, action: #selector(didTapTryButton), for: .touchUpInside)

        [imageView, titleLabel, contentLabel, tryButton, bottomSeparatorLine, dismissButton]
            .forEach(contentView.addSubview)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 44),
            contentView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 189),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 25),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentLabel.trailingAnchor, constant: 16),

            dismissButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 35),
            dismissButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bottomSeparatorLine.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 11),

            tryButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 35),
            contentView.trailingAnchor.constraint(equalTo: tryButton.trailingAnchor, constant: 16),
            bottomSeparatorLine.topAnchor.constraint(equalTo: tryButton.bottomAnchor, constant: 11),

            bottomSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: bottomSeparatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        return button
    }

    // MARK: - Configure

    func configure(insightsDelegate: SiteStatsInsightsDelegate?) {
        self.insightsDelegate = insightsDelegate
        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .staticText
        titleLabel.accessibilityLabel = Labels.title

        contentLabel.isAccessibilityElement = true
        contentLabel.accessibilityTraits = .staticText
        contentLabel.accessibilityLabel = Labels.content

        dismissButton.accessibilityLabel = Labels.dismiss
        dismissButton.accessibilityHint = Labels.dismissHint
        dismissButton.accessibilityIdentifier = "dismiss-customize-insights-cell"

        tryButton.accessibilityLabel = Labels.tryIt
        tryButton.accessibilityHint = Labels.tryItHint
    }
}

// MARK: - Private Extension

private extension CustomizeInsightsCell {

    // MARK: - Styles

    func applyStyles() {
        titleLabel.text = Labels.title
        contentLabel.text = Labels.content
        tryButton.setTitle(Labels.tryIt, for: .normal)
        dismissButton.setTitle(Labels.dismiss, for: .normal)

        Style.configureCell(self)
        Style.configureLabelAsCustomizeTitle(titleLabel)
        Style.configureLabelAsSummary(contentLabel)
        Style.configureAsCustomizeDismissButton(dismissButton)
        Style.configureAsCustomizeTryButton(tryButton)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    // MARK: - Button Handling

    @objc func didTapDismissButton(_ sender: UIButton) {
        WPAppAnalytics.track(.statsItemTappedInsightsCustomizeDismiss)
        insightsDelegate?.customizeDismissButtonTapped?()
    }

    @objc func didTapTryButton(_ sender: UIButton) {
        WPAppAnalytics.track(.statsItemTappedInsightsCustomizeTry)
        insightsDelegate?.customizeTryButtonTapped?()
    }

    // MARK: - Constants

    struct Labels {
        static let title = NSLocalizedString(
            "customizeInsightsCell.title",
            value: "Customize your insights",
            comment: "Customize Insights title"
        )
        static let content = NSLocalizedString(
            "customizeInsightsCell.content",
            value:
                "Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.",
            comment: "Customize Insights description"
        )
        static let tryIt = NSLocalizedString(
            "customizeInsightsCell.tryItButton.title",
            value: "Try it now",
            comment: "Customize Insights button title"
        )
        static let dismiss = NSLocalizedString(
            "customizeInsightsCell.dismissButton.title",
            value: "Dismiss",
            comment: "Customize Insights button title"
        )
        static let dismissHint = NSLocalizedString(
            "customizeInsightsCell.dismissButton.accessibilityHint",
            value: "Tap to dismiss this card",
            comment: "Accessibility hint"
        )
        static let tryItHint = NSLocalizedString(
            "customizeInsightsCell.tryItButton.accessibilityHint",
            value: "Tap to customize insights",
            comment: "Accessibility hint"
        )
    }
}
