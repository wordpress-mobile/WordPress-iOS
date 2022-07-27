import SwiftUI
import UIKit

enum UnifiedProloguePageType: CaseIterable {
    case intro
    case editor
    case notifications
    case analytics
    case reader

    var title: String {
        switch self {
        case .intro:
            return NSLocalizedString("Welcome to the world's most popular website builder.", comment: "Caption displayed in promotional screens shown during the login flow.")
        case .editor:
            return NSLocalizedString("With this powerful editor you can post on the go.", comment: "Caption displayed in promotional screens shown during the login flow.")
        case .notifications:
            return NSLocalizedString("See comments and notifications in real time.", comment: "Caption displayed in promotional screens shown during the login flow.")
        case .analytics:
            return NSLocalizedString("Watch your audience grow with in-depth analytics.", comment: "Caption displayed in promotional screens shown during the login flow.")
        case .reader:
            return NSLocalizedString("Follow your favorite sites and discover new blogs.", comment: "Caption displayed in promotional screens shown during the login flow.")
        }
    }
}

/// Simple container for each page of the login prologue.
///
class UnifiedProloguePageViewController: UIViewController {

    private let titleLabel = UILabel()

    lazy private var contentView: UIView = {
        makeContentView()
    }()

    private var pageType: UnifiedProloguePageType!

    let mainStackView = UIStackView()
    let titleTopSpacer = UIView()
    let titleContentSpacer = UIView()
    let contentBottomSpacer = UIView()

    var mainStackViewLeadingConstraint: NSLayoutConstraint?
    var mainStackViewTrailingConstraint: NSLayoutConstraint?
    var mainStackViewAspectConstraint: NSLayoutConstraint?
    var mainStackViewCenterAnchor: NSLayoutConstraint?

    init(pageType: UnifiedProloguePageType) {
        self.pageType = pageType

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear

        titleTopSpacer.translatesAutoresizingMaskIntoConstraints = false
        titleContentSpacer.translatesAutoresizingMaskIntoConstraints = false
        contentBottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        configureMainStackView()

        configureTitle()
    }

    override func viewDidLoad() {
        activateConstraints()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

        guard let previousTraitCollection = previousTraitCollection,
              traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass else {

            return
        }

        configureTitleFont()

        if traitCollection.horizontalSizeClass == .compact {
            deactivateRegularWidthConstraints()
            activateCompactWidthConstraints()

        } else {
            deactivateCompactWidthConstraints()
            activateRegularWidthConstraints()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // change the aspect ratio of the content in regular horizontal size class (iPad) depending on the orientation
        guard mainStackViewAspectConstraint?.isActive == true else {
            return
        }
        mainStackViewAspectConstraint?.isActive = false
        mainStackViewAspectConstraint = mainStackView.heightAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: iPadAspectRatio)
        mainStackViewAspectConstraint?.isActive = true
    }

    private func configureMainStackView() {
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        mainStackView.addArrangedSubviews([titleTopSpacer,
                                           titleLabel,
                                           titleContentSpacer,
                                           contentView,
                                           contentBottomSpacer])

        view.addSubview(mainStackView)
    }

    private func configureTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        configureTitleFont()
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true

        titleLabel.text = pageType.title
    }

    private func configureTitleFont() {

        guard let fontDescriptor = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .regular).fontDescriptor.withDesign(.serif) else {
            return
        }
        let size: CGFloat = traitCollection.horizontalSizeClass == .compact ? 0.0 : 40.0
        titleLabel.font = UIFontMetrics.default.scaledFont(for: UIFont(descriptor: fontDescriptor, size: size))
    }

    private func activateConstraints() {

        setMainStackViewConstraints()

        let centeredContentViewConstraint = NSLayoutConstraint(item: contentView,
                                                               attribute: .centerY,
                                                               relatedBy: .equal,
                                                               toItem: view,
                                                               attribute: .centerY,
                                                               multiplier: 1.15,
                                                               constant: 0)
        centeredContentViewConstraint.priority = .init(999)

        NSLayoutConstraint.activate([contentView.heightAnchor.constraint(equalTo: contentView.widthAnchor),
                                     mainStackView.topAnchor.constraint(equalTo: view.topAnchor),
                                     mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                     contentView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.7),
                                     titleTopSpacer.heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor, multiplier: 0.1),
                                     titleContentSpacer.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.2),
                                     centeredContentViewConstraint,
                                     titleLabel.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.95),
                                     contentBottomSpacer.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.1)])

        if traitCollection.horizontalSizeClass == .compact {

            activateCompactWidthConstraints()
        } else {

            activateRegularWidthConstraints()
        }
    }

    private func activateRegularWidthConstraints() {
        guard let stackViewAspect = mainStackViewAspectConstraint,
              let stackViewCenter = mainStackViewCenterAnchor else {
            return
        }

        NSLayoutConstraint.activate([stackViewAspect, stackViewCenter])
    }

    private func activateCompactWidthConstraints() {
        guard let stackViewLeading = mainStackViewLeadingConstraint,
              let stackViewTrailing = mainStackViewTrailingConstraint else {
            return
        }
        NSLayoutConstraint.activate([stackViewLeading, stackViewTrailing])
    }

    private func deactivateRegularWidthConstraints() {
        guard let stackViewAspect = mainStackViewAspectConstraint,
              let stackViewCenter = mainStackViewCenterAnchor else {
            return
        }
        NSLayoutConstraint.deactivate([stackViewAspect, stackViewCenter])
    }

    private func deactivateCompactWidthConstraints() {
        guard let stackViewLeading = mainStackViewLeadingConstraint,
              let stackViewTrailing = mainStackViewTrailingConstraint else {
            return
        }
        NSLayoutConstraint.deactivate([stackViewLeading, stackViewTrailing])
    }

    private func setMainStackViewConstraints() {

        mainStackViewLeadingConstraint = mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        mainStackViewTrailingConstraint = mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        mainStackViewAspectConstraint = mainStackView.heightAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: iPadAspectRatio)
        mainStackViewCenterAnchor = mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    }

    // use different aspect ratios on iPad depending on the orientation
    private var iPadAspectRatio: CGFloat {
        UIDevice.current.orientation.isPortrait ? 1.78 : 1.4
    }

    private func embedSwiftUIView<Content: View>(_ view: Content) -> UIView {
        UIView.embedSwiftUIView(view)
    }

    private func makeContentView() -> UIView {
        switch pageType {
        case .intro:
            return embedSwiftUIView(UnifiedPrologueIntroContentView())
        case .editor:
            return embedSwiftUIView(UnifiedPrologueEditorContentView())
        case .analytics:
            return embedSwiftUIView(UnifiedPrologueStatsContentView())
        case .notifications:
            return embedSwiftUIView(UnifiedPrologueNotificationsContentView())
        case .reader:
            return embedSwiftUIView(UnifiedPrologueReaderContentView())
        default:
            return UIView()
        }
    }

    enum Metrics {
        static let topInset: CGFloat = 96.0
        static let horizontalInset: CGFloat = 24.0
        static let titleToContentSpacing: CGFloat = 48.0
        static let heightRatio: CGFloat = WPDeviceIdentification.isiPad() ? 0.5 : 0.4
    }
}
