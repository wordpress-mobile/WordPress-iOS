import UIKit

class MigrationStepView: UIView {

    // MARK: - Configuration

    var additionalContentInset = UIEdgeInsets(
        top: Constants.topContentInset,
        left: 0,
        bottom: Constants.additionalBottomContentInset,
        right: 0
    )

    // MARK: - Views

    private let headerView: MigrationHeaderView
    private let centerView: UIView
    private let actionsView: MigrationActionsView

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerView])
        stackView.axis = .vertical
        stackView.spacing = Constants.stackViewSpacing
        stackView.directionalLayoutMargins = Constants.mainStackViewMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStackView)
        return contentView
    }()

    private lazy var mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        return scrollView
    }()

    // MARK: - Init

    init(headerView: MigrationHeaderView,
         actionsView: MigrationActionsView,
         centerView: UIView) {
        self.headerView = headerView
        self.centerView = centerView
        centerView.translatesAutoresizingMaskIntoConstraints = false
        self.actionsView = actionsView
        headerView.directionalLayoutMargins = .zero
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        backgroundColor = MigrationAppearance.backgroundColor
        addSubview(mainScrollView)
        addSubview(actionsView)
        activateConstraints()
    }

    private func activateConstraints() {
        contentView.pinSubviewToAllEdges(mainStackView)

        NSLayoutConstraint.activate([
            mainScrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        mainScrollView.pinSubviewToAllEdges(contentView)

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            actionsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bottomInset = actionsView.frame.size.height - safeAreaInsets.bottom
        mainScrollView.contentInset = .init(
            top: additionalContentInset.top,
            left: additionalContentInset.left,
            bottom: bottomInset + additionalContentInset.bottom,
            right: additionalContentInset.right
        )
        mainScrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private enum Constants {
        /// Adds space between the content bottom edge and actions sheet top edge.
        ///
        /// Bottom inset is added to the `scrollView` so the content is not covered by the Actions Sheet view.
        /// The value of the bottom inset is computed in `layoutSubviews`.
        static let additionalBottomContentInset: CGFloat = 10

        /// Adds top padding to the `scrollView`.
        static let topContentInset: CGFloat = UINavigationBar().intrinsicContentSize.height

        // Main stack view spacing.
        static let stackViewSpacing: CGFloat = 20

        // Adds margins to the main sack view.
        static let mainStackViewMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30)
    }
}
