import UIKit

final class TitleSubtitleHeader: UIView {
    struct Margins {
        static let horizontalMargin: CGFloat = 30.0

        private static let compactVerticalMargin: CGFloat = 30.0
        private static let regularVerticalMargin: CGFloat = 40.0

        static var verticalMargin: CGFloat {
            return WPDeviceIdentification.isiPad() ? regularVerticalMargin : compactVerticalMargin
        }

        static let interLabelVerticalSpacing = CGFloat(10)
    }

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Margins.verticalMargin),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Margins.horizontalMargin),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Margins.horizontalMargin),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Margins.interLabelVerticalSpacing),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Margins.horizontalMargin),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Margins.horizontalMargin),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Margins.verticalMargin)
        ])

        setStyles()
        prepareForVoiceOver()
    }

    private func setStyles() {
        styleBackground()
        styleTitle()
        styleSubtitle()
    }

    private func styleBackground() {
        backgroundColor = .listBackground
    }

    private func styleTitle() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        titleLabel.textColor = .text
    }

    private func styleSubtitle() {
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitleLabel.textColor = .textSubtle
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
        refreshAccessibilityLabel()
    }

    func setSubtitle(_ text: String) {
        subtitleLabel.text = text
        refreshAccessibilityLabel()
    }
}

extension TitleSubtitleHeader {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        // Title needs to be forced to reset its style, otherwise the types do not change
        styleTitle()
    }
}

// MARK: - VoiceOver

private extension TitleSubtitleHeader {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        accessibilityTraits = .header
        refreshAccessibilityLabel()
    }

    func refreshAccessibilityLabel() {
        let strings = [titleLabel.text ?? "", subtitleLabel.text ?? ""]
        accessibilityLabel = strings.joined(separator: ". ")
    }
}
