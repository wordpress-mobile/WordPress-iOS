import UIKit

@objc
class MigrationSuccessCell: UITableViewCell {

    var onTap: (() -> Void)?
    var cardView: MigrationSuccessCardView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let view = MigrationSuccessCardView() {
            self.onTap?()
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        contentView.pinSubviewToAllEdges(view)
        cardView = view
    }

    @objc func configureForSidebarMode() {
        cardView?.backgroundColor = .clear
    }

    @objc(configureWithViewController:)
    func configure(with viewController: UIViewController) {
        self.onTap = { [weak viewController] in
            guard let viewController else {
                return
            }
            let handler = MigrationSuccessActionHandler()
            handler.showDeleteWordPressOverlay(with: viewController)
        }
    }
}

extension BlogDetailsViewController {

    @objc func migrationSuccessSectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}

        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .migrationSuccess)
        return section
    }
}
