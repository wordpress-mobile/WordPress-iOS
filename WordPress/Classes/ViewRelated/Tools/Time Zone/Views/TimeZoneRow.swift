import UIKit

struct TimeZoneRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(TimeZoneTableViewCell.self)

    let title: String
    let leftSubtitle: String
    let rightSubtitle: String
    let action: ImmuTableAction?

    init(title: String,
         leftSubtitle: String,
         rightSubtitle: String,
         action: ImmuTableAction?) {
        self.title = title
        self.leftSubtitle = leftSubtitle
        self.rightSubtitle = rightSubtitle
        self.action = action
    }

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? TimeZoneTableViewCell else { return }

        cell.titleLabel.text = title
        cell.leftSubtitle.text = leftSubtitle
        cell.rightSubtitle.text = rightSubtitle
    }
}
