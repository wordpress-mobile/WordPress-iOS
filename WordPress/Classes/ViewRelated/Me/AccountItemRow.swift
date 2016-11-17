import Foundation
import WordPressShared

struct AccountItemRow : ImmuTableRow {
    typealias CellType = AccountCell
    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "AccountCell", bundle: NSBundle(forClass: CellType.self))
        return ImmuTableCell.Nib(nib, CellType.self)
    }()
    static var customHeight: Float = 44.0

    let account: Account
    let action: ImmuTableAction?
    let placeholder: UIImage

    func configureCell(cell: UITableViewCell) {
        guard let cell = cell as? AccountCell else { return }

        cell.usernameLabel?.text = account.username
        cell.profileImageView?.downloadGravatarWithEmail(account.email, placeholderImage: placeholder)

        cell.usernameLabel.textColor = WPStyleGuide.darkGrey()
        WPStyleGuide.configureTableViewCell(cell)
    }
}
