import UIKit

protocol SiteCreationDomainSearchTableViewCellDelegate {
    func startSearch(for: String)
}

class SiteCreationDomainSearchTableViewCell: UITableViewCell {
    @IBOutlet var textField: LoginTextField?
    private var placeholder: String
    public static let cellIdentifier = "SiteCreationDomainSearchTableViewCell"
    open var delegate: SiteCreationDomainSearchTableViewCellDelegate?

    required init?(coder aDecoder: NSCoder) {
        placeholder = ""
        super.init(coder: aDecoder)
    }

    init(placeholder: String) {
        self.placeholder = placeholder
        super.init(style: .default, reuseIdentifier: SiteCreationDomainSearchTableViewCell.cellIdentifier)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textField?.text = placeholder
        textField?.delegate = self
    }
}

extension SiteCreationDomainSearchTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delegate?.startSearch(for: textField.text ?? "")
        return false
    }
}
