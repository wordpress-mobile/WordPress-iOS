import UIKit

final class BlazeCardView: UIView {

    // MARK: - Properties

    private let viewModel: BlazeCardViewModel

    // MARK: - Views

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Style.descriptionLabelFont
        label.text = Strings.description
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel])
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Metrics.contentDirectionalLayoutMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
        frameView.icon = .none
        frameView.title = Strings.title
        frameView.onEllipsisButtonTap = {}
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = contextMenu
        frameView.add(subview: contentStackView)
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
    }
}

extension BlazeCardView {

    private enum Style {
        static let descriptionLabelFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let hideThisImage = UIImage(systemName: "minus.circle")
    }

    private enum Metrics {
        static let contentDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: 0.0, leading: 16.0, bottom: 8.0, trailing: 16.0)
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

    let onHideThisTap: UIActionHandler

    init(onHideThisTap: @escaping UIActionHandler = { _ in }) {
        self.onHideThisTap = onHideThisTap
    }
}
