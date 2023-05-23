import UIKit
import WordPressFlux

final class DashboardRegisterDomainCardCell: UICollectionViewCell, Reusable {

    // MARK: - Constants

    enum Constants {
        static let spacing: CGFloat = 20
        static let iconSize = CGSize(width: 18, height: 18)
        static let constraintPriority = UILayoutPriority(999)
    }

    private enum Strings {
        static let title = NSLocalizedString("Register Domain", comment: "Action to redeem domain credit.")
        static let content = NSLocalizedString(
            "All WordPress.com plans include a custom domain name. Register your free premium domain now.",
            comment: "Information about redeeming domain credit on site dashboard."
        )
    }

    private static var hasLoggedDomainCreditPromptShownEvent: Bool = false

    // MARK: - Views

    private let frameView = BlogDashboardCardFrameView()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.content
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        return label
    }()

    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let headerMargins = frameView.headerMargins
        self.contentStackView.layoutMargins = .init(top: 0, left: headerMargins.left, bottom: 0, right: headerMargins.right)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard !Self.hasLoggedDomainCreditPromptShownEvent else {
            return
        }
        WPAnalytics.track(WPAnalyticsStat.domainCreditPromptShown)
        Self.hasLoggedDomainCreditPromptShownEvent = true
    }

    // MARK: - Helpers

    private func commonInit() {
        frameView.setTitle(Strings.title, titleHint: nil)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: Constants.constraintPriority)
        contentStackView.addArrangedSubview(contentLabel)
        frameView.add(subview: contentStackView)
    }
}
