import UIKit

class BaseDashboardDomainsCardCell: DashboardCollectionViewCell {
    var blog: Blog?
    weak var presentingViewController: BlogDashboardViewController?
    private(set) var viewModel: DashboardDomainsCardViewModel = .empty

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.onEllipsisButtonTap = viewModel.onEllipsisTap
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.setTitle(viewModel.strings.title)
        frameView.clipsToBounds = true
        frameView.translatesAutoresizingMaskIntoConstraints = false
        return frameView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Style.descriptionLabelFont
        label.text = viewModel.strings.description
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

    private lazy var contextMenu: UIMenu = {
        let hideThisAction = UIAction(title: viewModel.strings.hideThis,
                                      image: Style.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: viewModel.onHideThisTap)
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
        contentView.accessibilityIdentifier = viewModel.strings.accessibilityIdentifier
        cardFrameView.add(subview: containerStackView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tap)
    }

    @objc private func viewTapped() {
        viewModel.onViewTap()
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        viewModel.onViewShow()
    }
}

extension BaseDashboardDomainsCardCell {

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
}

// MARK: - DashboardCardViewModel

struct DashboardDomainsCardViewModel {
    struct Strings {
        let title: String
        let description: String
        let hideThis: String
        let source: String
        let accessibilityIdentifier: String

        init(title: String = "",
             description: String = "",
             hideThis: String = "",
             source: String = "",
             accessibilityIdentifier: String = "") {
            self.title = title
            self.description = description
            self.hideThis = hideThis
            self.source = source
            self.accessibilityIdentifier = accessibilityIdentifier
        }

    }

    let strings: DashboardDomainsCardViewModel.Strings
    let onViewShow: () -> Void
    let onViewTap: () -> Void
    let onEllipsisTap: () -> Void
    let onHideThisTap: UIActionHandler

    init(strings: DashboardDomainsCardViewModel.Strings,
         onViewShow: @escaping () -> Void = {},
         onViewTap: @escaping () -> Void = {},
         onEllipsisTap: @escaping () -> Void = {},
         onHideThisTap: @escaping UIActionHandler = { _ in }) {
        self.strings = strings
        self.onViewShow = onViewShow
        self.onViewTap = onViewTap
        self.onEllipsisTap = onEllipsisTap
        self.onHideThisTap = onHideThisTap
    }

    static var empty: DashboardDomainsCardViewModel {
        DashboardDomainsCardViewModel(strings: .init())
    }
}
