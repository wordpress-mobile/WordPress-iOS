import UIKit
import Lottie

class JetpackBrandingMenuCardCell: UITableViewCell {

    // MARK: Private Variables

    /// Sets the animation based on the language orientation
    private var animation: Animation? {
        traitCollection.layoutDirection == .leftToRight ?
        Animation.named(Constants.animationLtr) :
        Animation.named(Constants.animationRtl)
    }

    // MARK: Lazy Loading Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.configureButtonContainerStackView()
        frameView.hideHeader()

        // NOTE: Remove the logic when support for iOS 14 is dropped
        if #available (iOS 15.0, *) {
            // assign an empty closure so the button appears.
            frameView.onEllipsisButtonTap = {}
            frameView.ellipsisButton.showsMenuAsPrimaryAction = true
//            frameView.ellipsisButton.menu = contextMenu
        } else {
            // Show a fallback implementation using `MenuSheetViewController`.
            // iOS 13 doesn't support showing UIMenu programmatically.
            // iOS 14 doesn't support `UIDeferredMenuElement.uncached`.
            frameView.onEllipsisButtonTap = { [weak self] in
//                self?.showMenuSheet()
            }
        }

        return frameView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.spacing
        stackView.layoutMargins = Metrics.containerMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([logosSuperview, descriptionLabel])
        return stackView
    }()

    private lazy var logosSuperview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(logosAnimationView)

        view.topAnchor.constraint(equalTo: logosAnimationView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: logosAnimationView.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: logosAnimationView.leadingAnchor).isActive = true

        return view
    }()

    private lazy var logosAnimationView: AnimationView = {
        let view = AnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animation = animation

        // Height Constraint
        view.heightAnchor.constraint(equalToConstant: Metrics.animationsViewHeight).isActive = true

        // Width constraint to achieve aspect ratio
        let animationSize = animation?.size ?? .init(width: 1, height: 1)
        let ratio = animationSize.width / animationSize.height
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio).isActive = true

        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupViews()
        setupContent()
    }

    // MARK: Helpers

    private func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: Metrics.cardFrameConstraintPriority)
        cardFrameView.add(subview: containerStackView)
    }

    private func setupContent() {
        logosAnimationView.play()
        descriptionLabel.text = "Hello there!!!!!!!!!!!!!"
    }

}

private extension JetpackBrandingMenuCardCell {

    enum Metrics {
        static let spacing: CGFloat = 12
        static let containerMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let cardFrameConstraintPriority = UILayoutPriority(999)
        static let animationsViewHeight: CGFloat = 32
    }

    enum Constants {
        static let animationLtr = "JetpackAllFeaturesLogosAnimation_ltr"
        static let animationRtl = "JetpackAllFeaturesLogosAnimation_rtl"
    }
}

// TODO: Consider moving to a different file
extension JetpackBrandingMenuCardCell {

    @objc(configureWithViewController:)
    func configure(with viewController: UIViewController) {
        // TODO: To be implemented
    }
}

// TODO: Consider moving to a different file
extension BlogDetailsViewController {

    @objc func jetpackCardSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}

        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackBrandingCard)
        return section
    }
}
