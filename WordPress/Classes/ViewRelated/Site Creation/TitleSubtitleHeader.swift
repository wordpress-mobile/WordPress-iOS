import UIKit

final class TitleSubtitleHeader: UIView {
    struct Margins {
        static let horizontalMargin: CGFloat = 30.0
        private static let compactVerticalMargin: CGFloat = 30.0
        private static let regularVerticalMargin: CGFloat = 40.0
        static let spacing: CGFloat = 10.0

        static func vertical() -> CGFloat {
            return WPDeviceIdentification.isiPad() ? regularVerticalMargin : compactVerticalMargin
        }
    }

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        // Necessary to force the label to render in more than one line when the text doe snot fit in one line
        label.preferredMaxLayoutWidth = self.frame.size.width - 2 * (Margins.horizontalMargin + 10)

        return label
    }()

    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        // Necessary to force the label to render in more than one line when the text doe snot fit in one line
        label.preferredMaxLayoutWidth = self.frame.size.width - 2 * Margins.horizontalMargin

        return label
    }()

    private lazy var stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.axis = .vertical
        returnValue.spacing = Margins.spacing

        return returnValue
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
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Margins.horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * Margins.horizontalMargin),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Margins.vertical()),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Margins.vertical())])

        setStyles()
    }

    private func setStyles() {
        styleBackground()
        styleTitle()
        styleSubtitle()
    }

    private func styleBackground() {
        backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func styleTitle() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        titleLabel.textColor = WPStyleGuide.darkGrey()
    }

    private func styleSubtitle() {
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitleLabel.textColor = WPStyleGuide.greyDarken10()
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
        titleLabel.accessibilityLabel = text
    }

    func setSubtitle(_ text: String) {
        subtitleLabel.text = text
        subtitleLabel.accessibilityLabel = text
    }
}
