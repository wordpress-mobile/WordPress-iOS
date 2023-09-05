import UIKit

final class DashboardMenuCell: DashboardCollectionViewCell {
    private var blog: Blog?
    private weak var viewController: BlogDashboardViewController?
    private var viewModel: DashboardBlazeCardCellViewModel?
    private var stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView() {
        stackView.axis = .vertical

        let frameView = BlogDashboardCardFrameView()
        frameView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        frameView.pinSubviewToAllEdges(stackView)

        contentView.addSubview(frameView)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(frameView, priority: .init(999))
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.viewController = viewController

#warning("cache view instead of re-creating?")
#warning("instead of individual viewmodels create cells right here?")
        stackView.removeAllSubviews()

        let postsViewModel = DashboardMenuItemViewModel(iconName: "icon-blaze", title: "Posts", details: "23") {

        }

        let pagesViewModel = DashboardMenuItemViewModel(iconName: "icon-blaze", title: "Pages", details: "23") {

        }

        let viewModels = [postsViewModel, pagesViewModel]
        let views = viewModels.map(makeMenuView)

        stackView.addArrangedSubviews(views)
    }

    private func makeMenuView(viewModel: DashboardMenuItemViewModel) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = viewModel.title
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true

        let imageView = UIImageView(image: UIImage(named: viewModel.iconName)?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .label

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true

        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, spacer])
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false

        if let details = viewModel.details {
            let detailsLabel = UILabel()
            detailsLabel.text = viewModel.details
            detailsLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
            detailsLabel.textColor = .secondaryLabel
            detailsLabel.adjustsFontForContentSizeCategory = true
            stackView.addArrangedSubviews([detailsLabel])
        }

        return stackView
    }

    private func setCardView(_ cardView: UIView, subtype: DashboardBlazeCardSubtype) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: UILayoutPriority(999))

        BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: [
            "type": DashboardCard.blaze.rawValue,
            "sub_type": subtype.rawValue
        ])
    }
}

struct DashboardMenuItemViewModel {
    let iconName: String
    let title: String
    let details: String?
    let action: () -> Void
}
