import UIKit

final class PrepublishingHeaderView: UIView {
    private let blogImageView = UIImageView()
    private let publishingToLabel = UILabel()
    private let blogTitleLabel = UILabel()

    let closeButton = UIButton(type: .system)
    let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        blogImageView.layer.masksToBounds = true
        blogImageView.layer.cornerRadius = 6
        blogImageView.layer.cornerCurve = .continuous

        publishingToLabel.text = Strings.publishingTo.uppercased()
        publishingToLabel.font = WPStyleGuide.fontForTextStyle(.caption1)
        publishingToLabel.textColor = .secondaryLabel

        blogTitleLabel.font = WPStyleGuide.fontForTextStyle(.headline)

        closeButton.configuration = {
            var configuration = UIButton.Configuration.plain()
            configuration.image = UIImage(systemName: "xmark.circle.fill")
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14)
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
                .applying(UIImage.SymbolConfiguration(font: WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)))
            return configuration
        }()
        closeButton.accessibilityLabel = Strings.close

        WPStyleGuide.applyBorderStyle(separator)
        separator.alpha = 0

        NSLayoutConstraint.activate([
            blogImageView.widthAnchor.constraint(equalToConstant: 44),
            blogImageView.heightAnchor.constraint(equalToConstant: 44),
        ])

        let labelsStackView = UIStackView(arrangedSubviews: [publishingToLabel, blogTitleLabel])
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        let stackView = UIStackView(arrangedSubviews: [blogImageView, labelsStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 12
        addSubview(stackView)
        pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 16, left: 20, bottom: 12, right: 20))

        addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            blogTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ blog: Blog) {
        blogImageView.downloadSiteIcon(for: blog)
        blogTitleLabel.text = blog.title
    }
}

private enum Strings {
    static let close = NSLocalizedString("prepublishing.close", value: "Close", comment: "Voiceover accessibility label informing the user that this button dismiss the current view")
    static let publishingTo = NSLocalizedString("prepublishing.publishingTo", value: "Publishing to", comment: "Label in the header in the pre-publishing sheet")
}
