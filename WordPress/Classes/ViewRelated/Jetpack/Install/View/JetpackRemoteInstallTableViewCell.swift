import UIKit

@objcMembers
class JetpackRemoteInstallTableViewCell: UITableViewCell {

    // MARK: Properties

    private var blog: Blog?
    private weak var presenterViewController: BlogDetailsViewController?

    private lazy var cardViewModel: JetpackRemoteInstallCardViewModel = {
        let onHideThisTap: UIActionHandler = { [weak self] _ in
            JetpackInstallPluginHelper.hideCard(for: self?.blog)
            self?.presenterViewController?.reloadTableView()
        }
        return JetpackRemoteInstallCardViewModel(onHideThisTap: onHideThisTap)
    }()

    private lazy var cardView: JetpackRemoteInstallCardView = {
        let cardView = JetpackRemoteInstallCardView(cardViewModel)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    func configure(blog: Blog, viewController: BlogDetailsViewController?) {
        self.blog = blog
        self.presenterViewController = viewController
    }

    private func setupView() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

}

// MARK: - BlogDetailsViewController view model

extension BlogDetailsViewController {

    @objc func jetpackInstallSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}
        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .jetpackInstallCard)
        return section
    }

}
