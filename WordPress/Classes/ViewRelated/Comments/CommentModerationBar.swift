import UIKit

class CommentModerationBar: UIView {

    // MARK: - Properties

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var pendingButton: UIButton!

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadViewFromNib() else {
            DDLogError("CommentModerationBar: Failed loading view from nib.")
            return
        }

        view.frame = self.bounds
        configureView()
        self.addSubview(view)
    }

}

// MARK: - Private Extension

private extension CommentModerationBar {

    // MARK: - Configure

    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: "\(CommentModerationBar.self)", bundle: Bundle.main)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }

    func configureView() {
        configureBackground()
        pendingButton.configureFor(.pending)
    }

    func configureBackground() {
        contentView.backgroundColor = .tertiaryFill
        contentView.layer.cornerRadius = 15
    }

    // MARK: - Button Actions

    @IBAction func pendingTapped(_ sender: UIButton) {
        sender.toggleState()
    }

}

// MARK: - Moderation Button Types

private enum ModerationButtonType {
    case pending
    case approved
    case spam
    case trash

    var label: String {
        switch self {
        case .pending:
            return NSLocalizedString("Pending", comment: "Button title for Pending comment state.")
        default:
            return ""
        }
    }

    var defaultIcon: UIImage? {
        switch self {
        case .pending:
            return UIImage(systemName: "tray")?.imageWithTintColor(.textSubtle)
        default:
            return UIImage()
        }
    }

    var selectedIcon: UIImage? {
        switch self {
        case .pending:
            return UIImage(systemName: "tray.fill")?.imageWithTintColor(.muriel(name: .yellow, .shade30))
        default:
            return UIImage()
        }
    }
}

// MARK: - UIButton Extension

private extension UIButton {

    func toggleState() {
        isSelected.toggle()
        configureState()
    }

    func configureState() {
        if isSelected {
            backgroundColor = .white
            layer.shadowColor = UIColor.black.cgColor
        } else {
            backgroundColor = .clear
            layer.shadowColor = UIColor.clear.cgColor
        }
    }

    func configureFor(_ button: ModerationButtonType) {
        setTitle(button.label, for: UIControl.State())
        setImage(button.defaultIcon, for: UIControl.State())
        setImage(button.selectedIcon, for: .selected)

        commonConfigure()
    }

    func commonConfigure() {
        setTitleColor(.textSubtle, for: UIControl.State())
        setTitleColor(.black, for: .selected)

        layer.cornerRadius = 15
        layer.shadowOffset = CGSize(width: 0, height: 2.0)
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 2.0

        verticallyAlignImageAndText()
        flipInsetsForRightToLeftLayoutDirection()
        configureState()
    }

}
