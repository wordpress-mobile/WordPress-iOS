import UIKit

class DashboardFailureCardCell: UICollectionViewCell, Reusable {
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.textColor = .secondaryLabel
        title.text = Strings.title
        title.font = WPStyleGuide.serifFontForTextStyle(.headline, fontWeight: .semibold)
        title.textAlignment = .center
        return title
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitle = UILabel()
        subtitle.textColor = .secondaryLabel
        subtitle.text = Strings.subtitle
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        subtitle.font = WPStyleGuide.fontForTextStyle(.subheadline)
        return subtitle
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentStackView.addArrangedSubviews([
            titleLabel,
            subtitleLabel
        ])

        contentView.addSubview(contentStackView)
        contentView.pinSubviewToAllEdges(contentStackView, insets: Constants.contentInsets)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Constants {
        static let spacing: CGFloat = 4
        static let contentInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    private enum Strings {
        static let title = NSLocalizedString("Some data wasn't loaded", comment: "Title shown on the dashboard when it fails to load")
        static let subtitle = NSLocalizedString("Check your internet connection and pull to refresh.", comment: "Subtitle shown on the dashboard when it fails to load")
    }
}

extension DashboardFailureCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) { }
}
