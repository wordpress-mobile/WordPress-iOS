import UIKit

class MigrationStepView: UIView {

    private let headerView: MigrationHeaderView
    private let centerView: UIView
    private let actionsView: MigrationActionsView

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerView, centerView, actionsView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(Constants.textToButtonsSpacing, after: centerView)
        return stackView
    }()

    init(headerView: MigrationHeaderView,
         actionsView: MigrationActionsView,
         centerView: UIView) {

        self.headerView = headerView
        headerView.directionalLayoutMargins = Constants.contentMargins
        self.centerView = centerView
        centerView.directionalLayoutMargins = Constants.contentMargins
        self.actionsView = actionsView
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Constants {
        static let contentMargins = NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 30, trailing: 30)

        static let textToButtonsSpacing: CGFloat = 48
    }


}
