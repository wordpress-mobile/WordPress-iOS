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

        configureTitle()
        configureContentView()
    }

    private func configureTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1)
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        titleLabel.text = pageType.title

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Metrics.topInset),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.horizontalInset)
        ])
    }

    private func configureContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Metrics.titleToContentSpacing),
            contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Metrics.heightRatio),
            contentView.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: Metrics.heightRatio),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
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
