import UIKit

final class BlazeCardView: UIView {

    // MARK: - Properties

    private let viewModel: BlazeCardViewModel

    // MARK: - Views

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Style.titleLabelFont
        label.text = Strings.title
        label.textColor = .text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = Metrics.stackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Metrics.contentDirectionalLayoutMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var flameIcon: UIImageView = {
        let image = UIImage(named: "blaze-flame")?.imageFlippedForRightToLeftLayoutDirection()
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var contextMenu: UIMenu = {
        let hideThisAction = UIAction(title: Strings.hideThis,
                                      image: Style.hideThisImage,
                                      attributes: [UIMenuElement.Attributes.destructive],
                                      handler: viewModel.onHideThisTap)
        return UIMenu(title: String(), options: .displayInline, children: [hideThisAction])
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.configureButtonContainerStackView()
        frameView.onEllipsisButtonTap = viewModel.onEllipsisTap
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.hideHeader()
        frameView.add(subview: contentStackView)
        frameView.clipsToBounds = true
        frameView.translatesAutoresizingMaskIntoConstraints = false
        return frameView
    }()

    // MARK: - Initializers

    init(_ viewModel: BlazeCardViewModel = BlazeCardViewModel()) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func setupView() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)

        cardFrameView.addSubview(flameIcon)
        cardFrameView.bringSubviewToFront(flameIcon)
        NSLayoutConstraint.activate([
            flameIcon.trailingAnchor.constraint(equalTo: cardFrameView.trailingAnchor),
            flameIcon.bottomAnchor.constraint(equalTo: cardFrameView.bottomAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tap)
    }

    // MARK: - Private

    @objc private func viewTapped() {
        viewModel.onViewTap()
    }
}

extension BlazeCardView {

    private enum Style {
        static let titleLabelFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        static let descriptionLabelFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let hideThisImage = UIImage(systemName: "minus.circle")
    }

    private enum Metrics {
        static let stackViewSpacing = 8.0
        static let contentDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: 16.0, leading: 16.0, bottom: 8.0, trailing: 16.0)
    }

    private enum Strings {
        static let title = NSLocalizedString("blaze.dashboard.card.title",
                                             value: "Promote your content with Blaze",
                                             comment: "Title for the Blaze dashboard card.")
        static let description = NSLocalizedString("blaze.dashboard.card.description",
                                                   value: "Display your work across millions of sites.",
                                                   comment: "Description for the Blaze dashboard card.")
        static let hideThis = NSLocalizedString("blaze.dashboard.card.menu.hide",
                                                 value: "Hide this",
                                                 comment: "Title for a menu action in the context menu on the Jetpack install card.")
    }
}

// MARK: - BlazeCardViewModel

struct BlazeCardViewModel {

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
