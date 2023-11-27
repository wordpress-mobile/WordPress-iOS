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
    private let centerView: UIView?
    private let actionsView: MigrationActionsView

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerView, UIView()].compactMap { $0 })
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.directionalLayoutMargins = Constants.mainStackViewMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.setCustomSpacing(Constants.stackViewSpacing, after: headerView)
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

    private lazy var minContentHeightConstraint: NSLayoutConstraint = {
        return contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    }()

    // MARK: - Init

    init(headerView: MigrationHeaderView,
         actionsView: MigrationActionsView,
         centerView: UIView? = nil) {
        self.headerView = headerView
        self.centerView = centerView
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
        minContentHeightConstraint.isActive = true

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

    // MARK: - Layout Subviews

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutMainScrollView()
        self.layoutContentView()
    }

    private func layoutMainScrollView() {
        let bottomInset = actionsView.frame.size.height - safeAreaInsets.bottom
        self.mainScrollView.contentInset = .init(
            top: additionalContentInset.top,
            left: additionalContentInset.left,
            bottom: bottomInset + additionalContentInset.bottom,
            right: additionalContentInset.right
        )
        self.mainScrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        self.mainScrollView.setNeedsLayout()
        self.mainScrollView.layoutIfNeeded()
    }

    private func layoutContentView() {
        self.minContentHeightConstraint.constant = 0
        let contentViewHeight = contentView.systemLayoutSizeFitting(
            .init(width: bounds.width, height: UIView.noIntrinsicMetric),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let scrollViewHeight = mainScrollView.frame.height
        let scrollViewInsets = mainScrollView.adjustedContentInset
        let visibleHeight = scrollViewHeight - (scrollViewInsets.top + scrollViewInsets.bottom)
        if contentViewHeight < visibleHeight {
            self.minContentHeightConstraint.constant = visibleHeight
        }
    }

    // MARK: - Types

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
        static let mainStackViewMargins = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
    }
}
