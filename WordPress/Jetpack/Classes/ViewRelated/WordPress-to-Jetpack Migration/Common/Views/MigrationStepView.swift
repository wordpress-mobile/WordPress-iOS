import UIKit

class MigrationStepView: UIView {

    private let headerView: MigrationHeaderView
    private let centerView: UIView
    private let actionsView: MigrationActionsView

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerView])
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
        self.actionsView = actionsView
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        addSubview(mainScrollView)
        addSubview(actionsView)
        activateConstraints()
    }

    private func activateConstraints() {
        contentView.pinSubviewToAllEdges(mainStackView, insets: Constants.contentMargins)
        pinSubviewToAllEdges(mainScrollView)
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
        mainScrollView.contentInset.bottom = actionsView.frame.size.height + Constants.bottomMargin
    }

    private enum Constants {
        static let contentMargins = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        static let stackViewSpacing: CGFloat = 20
        static let bottomMargin: CGFloat = 20
    }
}
