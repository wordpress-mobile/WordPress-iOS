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

    var contentViewHeightConstraint: NSLayoutConstraint?
    var contentViewWidthConstraint: NSLayoutConstraint?

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

        if traitCollection.horizontalSizeClass == .compact {

            NSLayoutConstraint.deactivate([contentViewHeightConstraint ?? NSLayoutConstraint()])
            NSLayoutConstraint.activate([contentViewWidthConstraint ?? NSLayoutConstraint()])
        } else {
            NSLayoutConstraint.deactivate([contentViewWidthConstraint ?? NSLayoutConstraint()])
            NSLayoutConstraint.activate([contentViewHeightConstraint ?? NSLayoutConstraint()])
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // change the scale of the view in regular horizontal size class (iPad) depending on the orientation
        guard contentViewHeightConstraint?.isActive == true else {
            return
        }
        contentViewHeightConstraint?.isActive = false
        setContentViewHeightConstraint()
        contentViewHeightConstraint?.isActive = true
    }

    private func configureMainStackView() {
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        mainStackView.addArrangedSubview(titleTopSpacer)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(titleContentSpacer)
        mainStackView.addArrangedSubview(contentView)
        mainStackView.addArrangedSubview(contentBottomSpacer)

        view.addSubview(mainStackView)
    }

    private func configureTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1)
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        titleLabel.text = pageType.title
    }

    private func activateConstraints() {
        view.pinSubviewToAllEdges(mainStackView)

        setContentViewWidthConstraint()
        setContentViewHeightConstraint()

        let centeredContentViewConstraint = NSLayoutConstraint(item: contentView,
                                                               attribute: .centerY,
                                                               relatedBy: .equal,
                                                               toItem: view,
                                                               attribute: .centerY,
                                                               multiplier: 1.15,
                                                               constant: 0)
        centeredContentViewConstraint.priority = .init(999)

        NSLayoutConstraint.activate([contentView.heightAnchor.constraint(equalTo: contentView.widthAnchor),
                                     titleTopSpacer.heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor, multiplier: 0.18),
                                     titleContentSpacer.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.2),
                                     centeredContentViewConstraint,
                                     contentBottomSpacer.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.1)])

        if traitCollection.horizontalSizeClass == .compact {

            NSLayoutConstraint.activate([contentViewWidthConstraint ?? NSLayoutConstraint()])
        } else {

            NSLayoutConstraint.activate([contentViewHeightConstraint ?? NSLayoutConstraint()])
        }
    }

    private func setContentViewHeightConstraint() {
        contentViewHeightConstraint = NSLayoutConstraint(item: contentView,
                                                         attribute: .height,
                                                         relatedBy: .equal,
                                                         toItem: view,
                                                         attribute: .height,
                                                         multiplier: iPadHeightMultiplier,
                                                         constant: 0)
    }

    private func setContentViewWidthConstraint() {
        contentViewWidthConstraint = NSLayoutConstraint(item: contentView,
                                                        attribute: .width,
                                                        relatedBy: .equal,
                                                        toItem: view,
                                                        attribute: .width,
                                                        multiplier: 0.7,
                                                        constant: 0)
    }

    /// scale factor for the content view on iPad, depending on the orientation
    private var iPadHeightMultiplier: CGFloat {
        UIDevice.current.orientation.isPortrait ? 0.4 : 0.5
    }

    private func embedSwiftUIView<Content: View>(_ view: Content) -> UIView {
        let controller = UIHostingController(rootView: view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        return controller.view
    }

    private func makeContentView() -> UIView {
        switch pageType {
        case .intro:
            return UnifiedPrologueIntroContentView()
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
