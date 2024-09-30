import UIKit
import WordPressShared

// MARK: - SearchTableViewCellDelegate
//
public protocol SearchTableViewCellDelegate: AnyObject {
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
    @IBOutlet public var textField: LoginTextField!

    /// UITextField's listener
    ///
    open weak var delegate: SearchTableViewCellDelegate?

    /// If `true` the search delegate callback is called as the text field is edited.
    /// This class does not implement any Debouncer or assume a minimum character count because
    /// each search is different.
    ///
    open var liveSearch: Bool = false

    /// If `true` then the user can type in spaces regularly.  If `false` the whitespaces will be
    /// stripped before they're entered into the field.
    ///
    open var allowSpaces: Bool = true

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
        textField.returnKeyType = .search
        textField.contentInsets = Constants.textInsetsWithIcon
        textField.accessibilityIdentifier = "Search field"
        textField.leftViewImage = textField?.leftViewImage?.imageWithTintColor(WordPressAuthenticator.shared.style.placeholderColor)

        contentView.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }
}

// MARK: - Settings
//
private extension SearchTableViewCell {
    enum Constants {
        static let textInsetsWithIcon = WPStyleGuide.edgeInsetForLoginTextFields()
    }
}

// MARK: - UITextFieldDelegate
//
extension SearchTableViewCell: UITextFieldDelegate {
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if !liveSearch {
            delegate?.startSearch(for: "")
        }

        return true
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !liveSearch,
           let searchText = textField.text {
            delegate?.startSearch(for: searchText)
        }

        return false
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let sanitizedString: String

        if allowSpaces {
            sanitizedString = string
        } else {
            sanitizedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let hasValidEdits = sanitizedString.count > 0 || range.length > 0

        if hasValidEdits {
            guard let start = textField.position(from: textField.beginningOfDocument, offset: range.location),
                  let end = textField.position(from: start, offset: range.length),
                  let textRange = textField.textRange(from: start, to: end) else {

                // This shouldn't really happen but if it does, let's at least let the edit go through
                return true
            }

            textField.replace(textRange, withText: sanitizedString)

            if liveSearch {
                startLiveSearch()
            }
        }

        return false
    }

    /// Convenience method to abstract the logic that tells the delegate to start a live search.
    ///
    /// - Precondition: make sure you check if `liveSearch` is enabled before calling this method.
    ///
    private func startLiveSearch() {
        guard let delegate = delegate,
              let text = textField.text else {
            return
        }

        if text.count == 0 {
            delegate.startSearch(for: "")
        } else {
            delegate.startSearch(for: text)
        }
    }
}

// MARK: - Loader
//
public extension SearchTableViewCell {
    func showLoader() {
        guard let leftView = textField.leftView else { return }
        let spinner = UIActivityIndicatorView(frame: leftView.frame)
        addSubview(spinner)
        spinner.startAnimating()

        textField.leftView?.alpha = 0
    }

    func hideLoader() {
        for subview in subviews where subview is UIActivityIndicatorView {
            subview.removeFromSuperview()
            break
        }

        textField.leftView?.alpha = 1
    }
}
