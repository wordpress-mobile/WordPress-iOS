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

    private lazy var title: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private lazy var subtitle: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private lazy var stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [self.title, self.subtitle])
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
        title.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        title.textColor = WPStyleGuide.darkGrey()
        title.layer.borderColor = UIColor.red.cgColor
        title.layer.borderWidth = 1
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitle.textColor = WPStyleGuide.greyDarken10()
        subtitle.layer.borderColor = UIColor.red.cgColor
        subtitle.layer.borderWidth = 1
    }

    func setTitle(_ text: String) {
        title.text = text
        title.accessibilityLabel = text
    }

    func setSubtitle(_ text: String) {
        subtitle.text = text
        subtitle.accessibilityLabel = text
    }
}

// MARK: - Exposing for tests
extension TitleSubtitleHeader {
    func titleLabel() -> UILabel {
        return title
    }

    func subtitleLabel() -> UILabel {
        return subtitle
    }
}
