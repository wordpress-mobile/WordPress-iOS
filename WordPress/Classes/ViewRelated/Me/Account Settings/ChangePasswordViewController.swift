class ChangePasswordViewController: SettingsTextViewController, UITextFieldDelegate {
    typealias ChangePasswordSaveAction = (String) -> ()

    private var onSaveActionPress: ChangePasswordSaveAction?
    private var currentValue: String = ""
    private var username: String = ""
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()

    convenience init(username: String, onSaveActionPress: @escaping ChangePasswordSaveAction) {
        self.init(text: "", placeholder: "\(Constants.placeholder)", hint: Constants.description)
        self.onSaveActionPress = onSaveActionPress
        self.username = username
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hiddenTextField = UITextField(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        hiddenTextField.text = username
        hiddenTextField.textContentType = .username
        hiddenTextField.isAccessibilityElement = false
        hiddenTextField.isEnabled = false
        view.addSubview(hiddenTextField)

        mode = .newPassword
        navigationItem.title = Constants.title
        navigationItem.rightBarButtonItem = saveBarButtonItem

        setNeedsSaveButtonIsEnabled()
    }


    // MARK: - Private methods

    private func save() {
        view.endEditing(true)
        onSaveActionPress?(currentValue)
    }

    private func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = currentValue.isValidPassword()
    }


    // MARK: - UITextFieldDelegate

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        currentValue = ""
        setNeedsSaveButtonIsEnabled()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            currentValue = text.replacingCharacters(in: range, with: string)
        }
        setNeedsSaveButtonIsEnabled()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let isValidPassword = currentValue.isValidPassword()
        if isValidPassword {
            save()
        }
        return isValidPassword
    }


    // MARK: - Constants

    private enum Constants {
        static let title = NSLocalizedString("Change Password", comment: "Main title")
        static let description = NSLocalizedString("Your password should be at least six characters long. To make it stronger, use upper and lower case letters, numbers, and symbols like ! \" ? $ % ^ & ).", comment: "Help text that describes how the password should be. It appears while editing the password")
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let placeholder = NSLocalizedString("New password", comment: "Placeholder text for password field")
    }
}

private extension String {
    func isValidPassword() -> Bool {
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(.){6,}$")
        return passwordTest.evaluate(with: self)
    }
}
