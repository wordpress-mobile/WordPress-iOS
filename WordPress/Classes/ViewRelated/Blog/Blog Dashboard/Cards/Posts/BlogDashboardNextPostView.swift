import UIKit

/// View prompting the user to create their next post
class BlogDashboardNextPostView: UIView {
    private lazy var mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.distribution = .fillProportionally
        mainStackView.spacing = Constants.horizontalSpacing
        mainStackView.layoutMargins = Constants.padding
        mainStackView.isLayoutMarginsRelativeArrangement = true
        return mainStackView
    }()

    private lazy var contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = Constants.verticalSpacing
        return contentStackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Create your first post"
        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.title3)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .button
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.text = Strings.nextPostDescription
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        descriptionLabel.accessibilityTraits = .button
        return descriptionLabel
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        let heightAnchor = imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height)
        heightAnchor.priority = UILayoutPriority(rawValue: 999)
        heightAnchor.isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "wp-illustration-first-post")
        imageView.isAccessibilityElement = false
        return imageView
    }()

    var onTap: (() -> Void)?

    var hasPublishedPosts: Bool = true {
        didSet {
            titleLabel.text = hasPublishedPosts ? Strings.nextPostTitle : Strings.firstPostTitle
            descriptionLabel.text = hasPublishedPosts ? Strings.nextPostDescription : Strings.firstPostDescription
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)

        mainStackView.addArrangedSubviews([
            contentStackView,
            imageView
        ])

        contentStackView.addArrangedSubviews([
            titleLabel,
            descriptionLabel
        ])
        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(promptTapped))
        addGestureRecognizer(tap)
    }

    @objc private func promptTapped() {
        onTap?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 10
        static let padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let imageSize = CGSize(width: 70, height: 70)
    }

    private enum Strings {
        static let nextPostTitle = NSLocalizedString("Create your next post", comment: "Title for the card prompting the user to create a new post.")
        static let nextPostDescription = NSLocalizedString("Posting regularly helps build your audience!", comment: "Description for the card prompting the user to create a new post.")
        static let firstPostTitle = NSLocalizedString("Create your first post", comment: "Title for the card prompting the user to create their first post.")
        static let firstPostDescription = NSLocalizedString("Posts appear on your blog page in reverse chronological order. It's time to share your ideas with the world!", comment: "Description for the card prompting the user to create their first post.")
    }
}
