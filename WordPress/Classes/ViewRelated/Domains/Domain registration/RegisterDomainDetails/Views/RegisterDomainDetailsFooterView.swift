import UIKit

class RegisterDomainDetailsFooterView: UIView, NibLoadable {

    @IBOutlet weak var submitButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
        submitButton.configureAsPrimaryNUXButton()
        backgroundColor = .systemBackground
    }
}
