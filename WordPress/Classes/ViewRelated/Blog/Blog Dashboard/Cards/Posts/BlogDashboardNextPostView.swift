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
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Posts appear on your blog page in reverse chronological order. It's time to share your ideas with the world!"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .textSubtle
        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        return descriptionLabel
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "wp-illustration-first-post")
        return imageView
    }()

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
}
