import UIKit

struct TimeZoneRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(TimeZoneTableViewCell.self)

    let title: String
    let leftSubtitle: String
    let rightSubtitle: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? TimeZoneTableViewCell else { return }

        cell.titleLabel.text = title
        cell.leftSubtitle.text = leftSubtitle
        cell.rightSubtitle.text = rightSubtitle
    }
}
