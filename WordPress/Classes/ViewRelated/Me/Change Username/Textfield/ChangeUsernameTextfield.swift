class ChangeUsernameTextfield: UIView, NibLoadable {
    var textDidChange: ((String) -> Void)?
    var textDidBeginEditing: ((ChangeUsernameTextfield) -> Void)?
    var text: String? {
        return textField.text
    }
    @IBOutlet private var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        addTopBorder(withColor: .neutral(shade: .shade10))
        addBottomBorder(withColor: .neutral(shade: .shade10))
    }

    func set(text: String) {
        textField.text = text
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}

extension ChangeUsernameTextfield: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let newText = text.replacingCharacters(in: range, with: string)
            textDidChange?(newText)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textDidBeginEditing?(self)
    }
}
