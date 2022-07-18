import UIKit

class JetpackBadgeRow: ImmuTableRow {
    // TODO: either the action or the configure method could be used to add the presenting action when needed
    var action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {

    }
    static let cell = ImmuTableCell.class(JetpackBadgeCell.self)
}
