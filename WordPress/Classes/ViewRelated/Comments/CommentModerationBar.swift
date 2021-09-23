import UIKit

class CommentModerationBar: UIView {

    // MARK: - Properties

    @IBOutlet private weak var contentView: UIView!

    @IBOutlet private weak var pendingButton: UIButton!
    @IBOutlet private weak var approvedButton: UIButton!
    @IBOutlet private weak var spamButton: UIButton!
    @IBOutlet private weak var trashButton: UIButton!

    @IBOutlet private weak var firstDivider: UIView!
    @IBOutlet private weak var secondDivider: UIView!
    @IBOutlet private weak var thirdDivider: UIView!

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
        configureDividers()
        pendingButton.configureFor(.pending)
        approvedButton.configureFor(.approved)
        spamButton.configureFor(.spam)
        trashButton.configureFor(.trash)
    }

    func configureBackground() {
        contentView.backgroundColor = .tertiaryFill
        contentView.layer.cornerRadius = 15
    }

    func configureDividers() {
        firstDivider.configureAsDivider()
        secondDivider.configureAsDivider()
        thirdDivider.configureAsDivider()
    }

    // MARK: - Button Actions

    @IBAction func pendingTapped(_ sender: UIButton) {
        sender.toggleState()
        firstDivider.isHidden = sender.isSelected
    }

    @IBAction func approvedTapped(_ sender: UIButton) {
        sender.toggleState()
        firstDivider.isHidden = sender.isSelected
        secondDivider.isHidden = sender.isSelected
    }

    @IBAction func spamTapped(_ sender: UIButton) {
        sender.toggleState()
        secondDivider.isHidden = sender.isSelected
        thirdDivider.isHidden = sender.isSelected
    }

    @IBAction func trashTapped(_ sender: UIButton) {
        sender.toggleState()
        thirdDivider.isHidden = sender.isSelected
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
        case .approved:
            return NSLocalizedString("Approved", comment: "Button title for Approved comment state.")
        case .spam:
            return NSLocalizedString("Spam", comment: "Button title for Spam comment state.")
        case .trash:
            return NSLocalizedString("Trash", comment: "Button title for Trash comment state.")
        }
    }

    var defaultIcon: UIImage? {
        switch self {
        case .pending:
            return UIImage(systemName: "tray")?.imageWithTintColor(.textSubtle)
        case .approved:
            return UIImage(systemName: "checkmark.circle")?.imageWithTintColor(.textSubtle)
        case .spam:
            return UIImage(systemName: "exclamationmark.octagon")?.imageWithTintColor(.textSubtle)
        case .trash:
            return UIImage(systemName: "trash")?.imageWithTintColor(.textSubtle)
        }
    }

    var selectedIcon: UIImage? {
        switch self {
        case .pending:
            return UIImage(systemName: "tray.fill")?.imageWithTintColor(.muriel(name: .yellow, .shade30))
        case .approved:
            return UIImage(systemName: "checkmark.circle.fill")?.imageWithTintColor(.muriel(name: .green, .shade40))
        case .spam:
            return UIImage(systemName: "exclamationmark.octagon.fill")?.imageWithTintColor(.muriel(name: .orange, .shade40))
        case .trash:
            return UIImage(systemName: "trash.fill")?.imageWithTintColor(.muriel(name: .red, .shade40))
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
        configureState()
    }

}

// MARK: - UIView Extension

private extension UIView {
    func configureAsDivider() {
        backgroundColor = .textSubtle

        if let existingConstraint = constraint(for: .width, withRelation: .equal) {
            existingConstraint.constant = .hairlineBorderWidth
        }
    }
}
