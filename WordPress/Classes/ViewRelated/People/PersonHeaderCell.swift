
import UIKit

class PersonHeaderCell: WPTableViewCell {

    static let identifier = "PersonHeaderCell"

    @IBOutlet weak var gravatarImageView: CircularImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
}
