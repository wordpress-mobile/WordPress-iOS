import UIKit

final class MigrationWelcomeBlogTableViewCell: UITableViewCell, Reusable {

    // MARK: - Views

    let siteImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.imageCornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    let siteNameLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.siteNameFont
        label.textColor = Constants.siteNameTextColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let siteAddressLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.siteAddressFont
        label.textColor = Constants.siteAddressTextColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        // Set cell properties
        self.selectionStyle = .none
        self.accessibilityElements = [siteNameLabel, siteAddressLabel]

        // Set subviews
        let labelsStackView = UIStackView(arrangedSubviews: [siteNameLabel, siteAddressLabel])
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = Constants.verticalSpacing
        let mainStackView = UIStackView(arrangedSubviews: [siteImageView, labelsStackView])
        mainStackView.axis = .horizontal
        mainStackView.spacing = Constants.horizontalSpacing
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(mainStackView)

        // Set constraints
        let imageSize = Constants.imageSize
        NSLayoutConstraint.activate([
            self.siteImageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            self.siteImageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        ])
        self.contentView.pinSubviewToAllEdgeMargins(mainStackView)
    }

    // MARK: - Updating UI

    func update(with blog: Blog) {
        let displayURL = blog.displayURL as String? ?? ""
        if let name = blog.settings?.name?.nonEmptyString() {
            self.siteNameLabel.text = name
            self.siteAddressLabel.text = displayURL
        } else {
            self.siteNameLabel.text = displayURL
            self.siteAddressLabel.text = nil
        }
        self.siteImageView.downloadSiteIcon(for: blog, imageSize: Constants.imageSize)
    }

    // MARK: - Types

    private struct Constants {
        /// Spacing between the image view and the labels stack view.
        static let horizontalSpacing = CGFloat(20)

        /// Spacing between the labels.
        static let verticalSpacing = CGFloat(3)

        static let siteNameFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let siteNameTextColor = UIColor.text
        static let siteAddressFont =  WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        static let siteAddressTextColor = UIColor.textSubtle

        static let imageCornerRadius = CGFloat(3)
        static let imageSize = CGSize(width: 60, height: 60)
    }
}
