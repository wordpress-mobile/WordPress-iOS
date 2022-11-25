import UIKit

@objc
class MigrationSuccessCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let view = MigrationSuccessCardView() {
            // TODO: add card presentation logic here
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        contentView.pinSubviewToAllEdges(view)
    }
}

class MigrationSuccessRow: ImmuTableRow {
    var action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {

    }

    static let cell = ImmuTableCell.class(MigrationSuccessCell.self)
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
