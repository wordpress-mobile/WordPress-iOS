import UIKit

class DashboardDomainsCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardViewModel: DashboardCardViewModel = {

        let onViewTap: () -> Void = { [weak self] in
            guard let self,
                  let presentingViewController = self.presentingViewController,
                  let blog = self.blog else {
                return
            }

            DomainsDashboardCoordinator.presentDomainsSuggestions(in: presentingViewController,
                                                                  source: Strings.source,
                                                                  blog: blog)
            DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardTapped(in: self.row)
        }

        let onEllipsisTap: () -> Void = { [weak self] in
        }

        let onHideThisTap: UIActionHandler = { [weak self] _ in
            guard let self else { return }

            DomainsDashboardCardHelper.hideCard(for: self.blog)
            DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardHidden(in: self.row)
            self.presentingViewController?.reloadCardsLocally()
        }

        return DashboardCardViewModel(onViewTap: onViewTap,
                                      onEllipsisTap: onEllipsisTap,
                                      onHideThisTap: onHideThisTap)
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.onEllipsisButtonTap = cardViewModel.onEllipsisTap
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.setTitle(Strings.title)
        frameView.clipsToBounds = true
        frameView.translatesAutoresizingMaskIntoConstraints = false
        return frameView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Style.descriptionLabelFont
        label.text = Strings.description
        label.textColor = .textSubtle
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dashboardDomainsCardSearchView: UIView = {
        let searchView = UIView.embedSwiftUIView(DashboardDomainsCardSearchView())
        searchView.translatesAutoresizingMaskIntoConstraints = false
        return searchView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [dashboardDomainsCardSearchView, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = Metrics.stackViewSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = Metrics.contentDirectionalLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var dashboardIcon: UIImageView = {
        let image = UIImage.gridicon(.domains).withTintColor(.white).withRenderingMode(.alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var contextMenu: UIMenu = {
        let hideThisAction = UIAction(title: Strings.hideThis,
                                      image: Style.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: cardViewModel.onHideThisTap)
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }()

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
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Constants.cardFrameConstraintPriority)
        contentView.accessibilityIdentifier = "dashboard-domains-card-contentview"
        cardFrameView.add(subview: containerStackView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tap)
    }

    @objc private func viewTapped() {
        cardViewModel.onViewTap()
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        DomainsDashboardCardTracker.trackDirectDomainsPurchaseDashboardCardShown(in: row)
    }
}

extension DashboardDomainsCardCell {

    private enum Constants {
        static let cardFrameConstraintPriority = UILayoutPriority(999)
    }

    private enum Style {
        static let descriptionLabelFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let hideThisImage = UIImage(systemName: "minus.circle")
    }

    private enum Metrics {
        static let stackViewSpacing: CGFloat = -20 // Negative since the views should overlap
        static let contentDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: 8.0,
                                                                             leading: 16.0,
                                                                             bottom: 8.0,
                                                                             trailing: 16.0)
    }

    private enum Strings {
        static let title = NSLocalizedString("domain.dashboard.card.shortTitle",
                                             value: "Find a custom domain",
                                             comment: "Title for the Domains dashboard card.")
        static let description = NSLocalizedString("domain.dashboard.card.description",
                                                   value: "Stake your claim on your corner of the web with a site address that’s easy to find, share and follow.",
                                                   comment: "Description for the Domains dashboard card.")
        static let hideThis = NSLocalizedString("domain.dashboard.card.menu.hide",
                                                value: "Hide this",
                                                comment: "Title for a menu action in the context menu on the Jetpack install card.")
        static let source = "domains_dashboard_card"
    }
}

// MARK: - DashboardCardViewModel

struct DashboardCardViewModel {
    let onViewTap: () -> Void
    let onEllipsisTap: () -> Void
    let onHideThisTap: UIActionHandler

    init(onViewTap: @escaping () -> Void = {},
         onEllipsisTap: @escaping () -> Void = {},
         onHideThisTap: @escaping UIActionHandler = { _ in }) {
        self.onViewTap = onViewTap
        self.onEllipsisTap = onEllipsisTap
        self.onHideThisTap = onHideThisTap
    }
}
