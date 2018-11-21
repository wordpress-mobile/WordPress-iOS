import UIKit

final class TitleSubtitleHeader: UIView {
    struct Margins {
        static let horizontalMargin: CGFloat = 38.0
        static let verticalMargin: CGFloat = 30.0
        static let spacing: CGFloat = 10.0
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
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2 * Margins.verticalMargin),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Margins.verticalMargin)])

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
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitle.textColor = WPStyleGuide.greyDarken10()
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
