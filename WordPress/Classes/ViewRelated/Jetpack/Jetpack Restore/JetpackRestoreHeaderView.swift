import Foundation
import Gridicons
import WordPressUI

class JetpackRestoreHeaderView: UIView, NibReusable {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.body.numberOfLines = 0
    }

    func configure(activity: FormattableActivity, restoreAction: JetpackRestoreAction) {
        switch restoreAction {
        case .restore:
            icon.image = UIImage.gridicon(.history)
            title.text = NSLocalizedString("Restore site", comment: "Label that describes the restore site action")
            let descriptionFormat = NSLocalizedString("%1$@ is the selected point for your restore.", comment: "Description for the restore action. $1$@ is a placeholder for the selected date.")
            // FIXME: Format date
            body.text = String(format: descriptionFormat, "Date")
            actionButton.setTitle(NSLocalizedString("Restore to this point", comment: "Button title for restore site action"), for: .normal)
        case .downloadBackup:
            icon.image = UIImage.gridicon(.history)
            title.text = NSLocalizedString("Create downloadable backup", comment: "Label that describes the download backup action")
            let descriptionFormat = NSLocalizedString("%1$@ is the selected point to create a downloadable backup.", comment: "Description for the download backup action. $1$@ is a placeholder for the selected date.")
            // FIXME: Format date
            body.text = String(format: descriptionFormat, "Date")
            actionButton.setTitle(NSLocalizedString("Create downloadable file", comment: "Button title for download backup action"), for: .normal)
        }
    }
}
