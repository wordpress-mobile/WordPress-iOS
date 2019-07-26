class ChangeUsernameLabel: UIView, NibLoadable {
    @IBOutlet private var textLabel: UILabel!
    private var state: State = .neutral {
        didSet {
            textLabel.textColor = state.color
        }
    }

    class func label(text: String, for state: State = .neutral) -> ChangeUsernameLabel {
        let label = ChangeUsernameLabel.loadFromNib()
        label.set(text: text, for: state)
        return label
    }

    func set(text: String, for state: State = .neutral) {
        textLabel.text = text
        self.state = state
    }

    enum State {
        case neutral
        case success
        case error

        var color: UIColor {
            switch self {
            case .neutral:
                return .neutral
            case .success:
                return .success
            case .error:
                return .error
            }
        }
    }
}
