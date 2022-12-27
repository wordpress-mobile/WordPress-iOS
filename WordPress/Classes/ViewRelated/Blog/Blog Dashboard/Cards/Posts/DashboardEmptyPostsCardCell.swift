import UIKit
import WordPressShared

/// Card cell prompting the user to create their first post
final class DashboardFirstPostCardCell: DashboardEmptyPostsCardCell, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        super.configure(blog: blog, viewController: viewController, apiResponse: apiResponse, cardType: .createPost)
    }
}

/// Card cell prompting the user to create their next post
final class DashboardNextPostCardCell: DashboardEmptyPostsCardCell, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        super.configure(blog: blog, viewController: viewController, apiResponse: apiResponse, cardType: .nextPost)
    }
}

/// Card cell used when no posts are available to display
class DashboardEmptyPostsCardCell: UICollectionViewCell, Reusable {

    // MARK: Views

    private lazy var frameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.hideHeader()
        return frameView
    }()

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
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
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

    // MARK: Private Variables

    /// The VC presenting this cell
    private weak var viewController: BlogDashboardViewController?
    private var blog: Blog?
    private var cardType: DashboardCard?

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: Constants.constraintPriority)

        frameView.add(subview: mainStackView)

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc private func promptTapped() {
        presentEditor()
    }
}

// MARK: BlogDashboardCardConfigurable

extension DashboardEmptyPostsCardCell {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?, cardType: DashboardCard) {
        self.blog = blog
        self.viewController = viewController
        self.cardType = cardType

        switch cardType {
        case .createPost:
            titleLabel.text = Strings.firstPostTitle
            descriptionLabel.text = Strings.firstPostDescription
        case .nextPost:
            titleLabel.text = Strings.nextPostTitle
            descriptionLabel.text = Strings.nextPostDescription
        default:
            assertionFailure("Cell used with wrong card type")
            return
        }

        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": cardType.rawValue])
    }
}

// MARK: Private Helpers

private extension DashboardEmptyPostsCardCell {
    func presentEditor() {
        BlogDashboardAnalytics.shared.track(.dashboardCardItemTapped, properties: ["type": "post", "sub_type": cardType?.rawValue ?? ""])
        let presenter = RootViewControllerCoordinator.sharedPresenter
        presenter.showPostTab()
    }
}

// MARK: Constants

extension DashboardEmptyPostsCardCell {
    private enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 10
        static let padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let imageSize = CGSize(width: 70, height: 70)
        static let constraintPriority = UILayoutPriority(999)
    }

    private enum Strings {
        static let nextPostTitle = NSLocalizedString("Create your next post", comment: "Title for the card prompting the user to create a new post.")
        static let nextPostDescription = NSLocalizedString("Posting regularly helps build your audience!", comment: "Description for the card prompting the user to create a new post.")
        static let firstPostTitle = NSLocalizedString("Create your first post", comment: "Title for the card prompting the user to create their first post.")
        static let firstPostDescription = NSLocalizedString("Posts appear on your blog page in reverse chronological order. It's time to share your ideas with the world!", comment: "Description for the card prompting the user to create their first post.")
    }
}
