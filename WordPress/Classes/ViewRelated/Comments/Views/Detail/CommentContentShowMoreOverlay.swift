import UIKit

final class CommentContentShowMoreOverlay: UIView {
    var onTap: (() -> Void)?

    private let gradientLayer = CAGradientLayer()
    private let button = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        isUserInteractionEnabled = true

        // Setup gradient
        gradientLayer.colors = [
            UIColor.systemBackground.withAlphaComponent(0).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.9).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        layer.addSublayer(gradientLayer)

        // Setup button
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(Strings.showMore, attributes: AttributeContainer([
            .font: UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.medium)
        ]))
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .caption2).withWeight(.medium))
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 12, bottom: 9, trailing: 12)

        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.maximumContentSizeCategory = .extraExtraExtraLarge

        addSubview(button)
        button.pinEdges([.horizontal, .bottom])
    }

    @objc private func buttonTapped() {
        onTap?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

private enum Strings {
    static let showMore = NSLocalizedString("reader.comments.showMore", value: "Show More", comment: "Button to expand a collapsed comment to show its full content.")
}
