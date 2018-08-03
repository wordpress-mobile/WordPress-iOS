import UIKit
import WordPressAuthenticator

class RegisterDomainDetailsFooterView: UIView, NibLoadable {

    @IBOutlet weak var nuxButton: NUXButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        nuxButton.isPrimary = true
    }
}
