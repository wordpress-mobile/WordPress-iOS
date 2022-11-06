import UIKit

class MigrationStepView: UIView {

    private let headerView: MigrationHeaderView
    private let centerView: UIView
    private let actionsView: MigrationActionsView

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerView, actionsView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(headerView: MigrationHeaderView,
         actionsView: MigrationActionsView,
         centerView: UIView) {

        self.headerView = headerView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.directionalLayoutMargins = Self.headerViewMargins
        self.centerView = centerView
        self.actionsView = actionsView
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let headerViewMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 30, trailing: 30)
}
