import UIKit

final class DashboardStatsStackView: UIStackView {

    // MARK: Public Variables

    var views: String? {
        didSet {
            viewsView?.countString = views
            updateAccessibility()
        }
    }

    var visitors: String? {
        didSet {
            visitorsView?.countString = visitors
            updateAccessibility()
        }
    }

    var likes: String? {
        didSet {
            likesView?.countString = likes
            updateAccessibility()
        }
    }

    // MARK: Private Properties

    var viewsView: DashboardSingleStatView?
    var visitorsView: DashboardSingleStatView?
    var likesView: DashboardSingleStatView?

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Helpers

    private func commonInit() {
        setupStackView()
        setupSubviews()
    }

    private func setupStackView() {
        axis = .horizontal
        translatesAutoresizingMaskIntoConstraints = false
        distribution = .fillEqually
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = Constants.statsStackViewMargins
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func setupSubviews() {
        let viewsView = DashboardSingleStatView(title: Strings.viewsTitle)
        let visitorsView = DashboardSingleStatView(title: Strings.visitorsTitle)
        let likesView = DashboardSingleStatView(title: Strings.likesTitle)
        self.viewsView = viewsView
        self.visitorsView = visitorsView
        self.likesView = likesView
        addArrangedSubviews([viewsView, visitorsView, likesView])
    }

    private func updateAccessibility() {
        guard let views = views,
              let visitors = visitors,
              let likes = likes else {
                  self.accessibilityLabel = Strings.errorTitle
                  return
        }
        let arguments = [views.accessibilityLabel ?? views,
                         visitors.accessibilityLabel ?? visitors,
                         likes.accessibilityLabel ?? likes]
        self.accessibilityLabel = String(format: Strings.accessibilityLabelFormat, arguments: arguments)
    }
}

// MARK: Constants

extension DashboardStatsStackView {
    enum Strings {
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let accessibilityLabelFormat = "\(viewsTitle) %@, \(visitorsTitle) %@, \(likesTitle) %@."
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
    }

    enum Constants {
        static let statsStackViewMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}
