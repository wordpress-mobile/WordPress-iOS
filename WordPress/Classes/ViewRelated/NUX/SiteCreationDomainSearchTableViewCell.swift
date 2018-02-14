import UIKit

protocol SiteCreationDomainSearchTableViewCellDelegate {
    func startSearch(for: String)
}

class SiteCreationDomainSearchTableViewCell: UITableViewCell {
    @IBOutlet var textField: LoginTextField?
    private var placeholder: String
    public static let cellIdentifier = "SiteCreationDomainSearchTableViewCell"
    open var delegate: SiteCreationDomainSearchTableViewCellDelegate?

    private enum Constants {
        static let textInsetsWithIcon = WPStyleGuide.edgeInsetForLoginTextFields()
    }

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
        textField?.contentInsets = Constants.textInsetsWithIcon
        textField?.placeholder = NSLocalizedString("Type to get more suggestions", comment: "Placeholder text for domain search during site creation.")
        textField?.accessibilityIdentifier = "Domain search field"

        if let searchIcon = textField?.leftViewImage {
            textField?.leftViewImage = searchIcon.imageWithTintColor(WPStyleGuide.grey())
        }
    }
}

extension SiteCreationDomainSearchTableViewCell: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.delegate?.startSearch(for: "")
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            self.delegate?.startSearch(for: searchText)
        }
        return false
    }
}
