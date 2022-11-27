import UIKit

class MigrationStepView: UIView {

    private let headerView: MigrationHeaderView
    private let centerView: UIView
    private let actionsView: MigrationActionsView

    private lazy var centerContentView: UIView = {
        let view = UIView()
        view.addSubview(centerView)
        return view
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerContentView])
        stackView.axis = .vertical
        stackView.spacing = Constants.stackViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
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

    init(headerView: MigrationHeaderView,
         actionsView: MigrationActionsView,
         centerView: UIView) {

        self.headerView = headerView
        self.centerView = centerView
        centerView.translatesAutoresizingMaskIntoConstraints = false
        self.actionsView = actionsView
        headerView.directionalLayoutMargins = Constants.headerViewMargins
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        backgroundColor = MigrationAppearance.backgroundColor
        addSubview(mainScrollView)
        addSubview(actionsView)
        activateConstraints()
    }

    private func activateConstraints() {
        centerContentView.pinSubviewToAllEdges(centerView, insets: Constants.centerContentMargins)
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
        mainScrollView.contentInset.bottom = bottomInset + Constants.additionalBottomContentInset
        mainScrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        mainScrollView.contentInset.top = Constants.topContentInset
    }

    private enum Constants {
        /// Adds space between the content bottom edge and actions sheet top edge.
        ///
        /// Bottom inset is added to the `scrollView` so the content is not covered by the Actions Sheet view.
        /// The value of the bottom inset is computed in `layoutSubviews`.
        static let additionalBottomContentInset: CGFloat = 10

        /// Adds top padding to the `scrollView`.
        static let topContentInset: CGFloat = UINavigationBar().intrinsicContentSize.height

        static let centerContentMargins = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        static let stackViewSpacing: CGFloat = 20
        static let headerViewMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30)
    }
}
