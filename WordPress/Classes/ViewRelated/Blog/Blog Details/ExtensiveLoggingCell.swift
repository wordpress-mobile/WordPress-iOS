import UIKit

class ExtensiveLoggingCell: UITableViewCell {

    private lazy var cardView: DashboardExtensiveLoggingCardView = {
        let view = DashboardExtensiveLoggingCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView)
    }

    func configure(with viewController: BlogDetailsViewController) {
        cardView.presenterViewController = viewController
        cardView.onTurnOffTapped = { [weak viewController] in
            viewController?.reloadTableView()
        }
    }
}
