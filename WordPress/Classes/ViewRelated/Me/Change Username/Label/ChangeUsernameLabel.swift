class ChangeUsernameLabel: UIView, NibLoadable {
    @IBOutlet private var textLabel: UILabel!
    private var state: AccountSettingsState = .stationary {
        didSet {
            textLabel.textColor = color
        }
    }
    private var color: UIColor {
        switch state {
        case .stationary, .loading:
            return .neutral
        case .success:
            return .success
        case .failure:
            return .error
        }
    }

    class func label(text: String, for state: AccountSettingsState = .stationary) -> ChangeUsernameLabel {
        let label = ChangeUsernameLabel.loadFromNib()
        label.set(text: text, for: state)
        return label
    }

    func set(text: String, for state: AccountSettingsState = .stationary) {
        textLabel.text = text
        self.state = state
    }
}
