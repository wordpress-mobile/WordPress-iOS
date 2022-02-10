import UIKit
import WordPressShared

final class DashboardQuickActionsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            statsButton,
            postsButton,
            mediaButton,
            pagesButton
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.stackViewSpacing
        return stackView
    }()

    private lazy var statsButton: QuickActionButton = {
        let button = QuickActionButton(title: "Stats", image: .gridicon(.statsAlt))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var postsButton: QuickActionButton = {
        let button = QuickActionButton(title: "Posts", image: .gridicon(.posts))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var mediaButton: QuickActionButton = {
        let button = QuickActionButton(title: "Media", image: .gridicon(.image))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var pagesButton: QuickActionButton = {
        let button = QuickActionButton(title: "Pages", image: .gridicon(.pages))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?) {
        // TODO: hook up to buttons to vc
    }
}

extension DashboardQuickActionsCardCell {

    private func setup() {
        contentView.addSubview(scrollView)
        contentView.pinSubviewToAllEdges(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.stackViewHorizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.stackViewHorizontalPadding),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }
}

extension DashboardQuickActionsCardCell {

    private enum Constants {
        static let contentViewCornerRadius = 8.0
        static let stackViewSpacing = 16.0
        static let stackViewHorizontalPadding = 20.0
    }
}
