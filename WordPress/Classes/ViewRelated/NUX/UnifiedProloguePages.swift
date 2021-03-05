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
    private let stackView = UIStackView()
    private let titleLabel = UILabel()

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

        configureStackView()
        configureTitle()
    }

    private func configureStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        view.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: Metrics.verticalInset,
                                                                  left: Metrics.horizontalInset,
                                                                  bottom: Metrics.verticalInset, right: Metrics.horizontalInset))
    }

    private func configureTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)

        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1)
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        titleLabel.text = pageType.title
    }

    enum Metrics {
        static let verticalInset: CGFloat = 96
        static let horizontalInset: CGFloat = 24
    }
}
