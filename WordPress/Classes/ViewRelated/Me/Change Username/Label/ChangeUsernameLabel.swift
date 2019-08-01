class ChangeUsernameLabel: UIView, NibLoadable {
    @IBOutlet private var textLabel: UILabel!
    private var state: AccountSettingsState = .idle {
        didSet {
            textLabel.textColor = color
        }
    }
    private var color: UIColor {
        switch state {
        case .idle, .loading:
            return .neutral
        case .success:
            return .success
        case .failure:
            return .error
        }
    }

    class func label(text: String, for state: AccountSettingsState = .idle) -> ChangeUsernameLabel {
        let label = ChangeUsernameLabel.loadFromNib()
        label.set(text: text, for: state)
        return label
    }

    func set(text: String, for state: AccountSettingsState = .idle) {
        textLabel.text = text
        self.state = state
    }
}
