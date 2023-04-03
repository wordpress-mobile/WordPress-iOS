import UIKit

final class BlogDashboardEmptyStateCell: DashboardCollectionViewCell {
    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        let titleLabel = UILabel()
        titleLabel.font = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .regular)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.text = Strings.title

        let subtitleLabel = UILabel()
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = Strings.subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 320).isActive = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        contentView.pinSubviewToAllEdges(stack, insets: .init(top: 52, left: 16, bottom: 4, right: 16))
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        // Do nothing
    }
}

private extension BlogDashboardEmptyStateCell {
    enum Strings {
        static let title = NSLocalizedString("dasboard.emptyView.title", value: "No cards to display", comment: "Title for an empty state view when no cards are displayed")
        static let subtitle = NSLocalizedString("dasboard.emptyView.subtitle", value: "Add cards that fit your needs to see information about your site.", comment: "Title for an empty state view when no cards are displayed")
    }
}
