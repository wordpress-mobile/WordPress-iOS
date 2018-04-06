import UIKit


// MARK: - SearchTableViewCellDelegate
//
protocol SearchTableViewCellDelegate {
    func startSearch(for: String)
}


// MARK: - SearchTableViewCell
//
class SearchTableViewCell: UITableViewCell {
    @IBOutlet var textField: LoginTextField!
    public static let cellIdentifier = "SearchTableViewCell"
    open var delegate: SearchTableViewCellDelegate?

    private enum Constants {
        static let textInsetsWithIcon = WPStyleGuide.edgeInsetForLoginTextFields()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(style: .default, reuseIdentifier: SearchTableViewCell.cellIdentifier)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        textField.contentInsets = Constants.textInsetsWithIcon
        textField.placeholder = NSLocalizedString("Type a keyword for more ideas", comment: "Placeholder text for domain search during site creation.")
        textField.accessibilityIdentifier = "Domain search field"
        textField.leftViewImage = textField?.leftViewImage?.imageWithTintColor(WPStyleGuide.grey())
    }
}

extension SearchTableViewCell: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.startSearch(for: "")
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            delegate?.startSearch(for: searchText)
        }
        return false
    }
}
