import UIKit
import WordPressShared


// MARK: - SearchTableViewCellDelegate
//
public protocol SearchTableViewCellDelegate: class {
    func startSearch(for: String)
}


// MARK: - SearchTableViewCell
//
open class SearchTableViewCell: UITableViewCell {

    /// UITableView's Reuse Identifier
    ///
    public static let reuseIdentifier = "SearchTableViewCell"

    /// Search 'UITextField's reference!
    ///
    @IBOutlet private var textField: LoginTextField!

    /// UITextField's listener
    ///
    open weak var delegate: SearchTableViewCellDelegate?

    /// Search UITextField's placeholder
    ///
    open var placeholder: String? {
        get {
            return textField.placeholder
        }
        set {
            textField.placeholder = newValue
        }
    }


    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        textField.contentInsets = Constants.textInsetsWithIcon
        textField.accessibilityIdentifier = "Search field"
        textField.leftViewImage = textField?.leftViewImage?.imageWithTintColor(Constants.leftImageTintColor)
    }
}


// MARK: - Settings
//
private extension SearchTableViewCell {
    enum Constants {
        static let textInsetsWithIcon = WPStyleGuide.edgeInsetForLoginTextFields()
        static let leftImageTintColor = WPStyleGuide.grey()
    }
}


// MARK: - UITextFieldDelegate
//
extension SearchTableViewCell: UITextFieldDelegate {
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.startSearch(for: "")
        return true
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchText = textField.text {
            delegate?.startSearch(for: searchText)
        }
        return false
    }
}
