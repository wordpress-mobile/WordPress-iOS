import UIKit

protocol CommentModerationBarDelegate: AnyObject {
    func statusChangedTo(_ commentStatus: CommentStatusType)
}

private typealias Style = WPStyleGuide.CommentDetail.ModerationBar

class CommentModerationBar: UIView {

    // MARK: - Properties

    @IBOutlet private weak var contentView: UIView!

    @IBOutlet private weak var pendingButton: UIButton!
    @IBOutlet private weak var approvedButton: UIButton!
    @IBOutlet private weak var spamButton: UIButton!
    @IBOutlet private weak var trashButton: UIButton!

    @IBOutlet private weak var buttonStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonStackViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet private weak var firstDivider: UIView!
    @IBOutlet private weak var secondDivider: UIView!
    @IBOutlet private weak var thirdDivider: UIView!

    private var compactHorizontalPadding: CGFloat = 4
    private let iPadPaddingMultiplier: CGFloat = 0.33
    private let iPhonePaddingMultiplier: CGFloat = 0.15

    weak var delegate: CommentModerationBarDelegate?

    var commentStatus: CommentStatusType? {
        didSet {
            guard oldValue != commentStatus else {
                return
            }
            toggleButtonForStatus(oldValue)
            toggleButtonForStatus(commentStatus)
        }
    }

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadViewFromNib() else {
            DDLogError("CommentModerationBar: Failed loading view from nib.")
            return
        }

        // Save initial constraint value to use on device rotation.
        compactHorizontalPadding = buttonStackViewLeadingConstraint.constant

        view.frame = self.bounds
        configureView()
        self.addSubview(view)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(configureStackViewWidth),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        configureButtons()
        configureStackViewWidth()
    }

    func configureBackground() {
        contentView.backgroundColor = Style.barBackgroundColor
        contentView.layer.cornerRadius = Style.cornerRadius
    }

    func configureDividers() {
        firstDivider.configureAsDivider()
        secondDivider.configureAsDivider()
        thirdDivider.configureAsDivider()
    }

    func configureButtons() {
        pendingButton.configureFor(.pending)
        approvedButton.configureFor(.approved)
        spamButton.configureFor(.spam)
        trashButton.configureFor(.trash)
    }

    @objc func configureStackViewWidth() {
        // On devices with a lot of horizontal space, increase the buttonStackView margins
        // so the buttons are not severely stretched out. Specifically:
        // - iPad landscape
        // - Non split view iPhone landscape
        let horizontalPadding: CGFloat = {
            if WPDeviceIdentification.isiPad() &&
                UIDevice.current.orientation.isLandscape {
                return bounds.width * iPadPaddingMultiplier
            }

            if traitCollection.horizontalSizeClass == .compact &&
                traitCollection.verticalSizeClass == .compact {
                return bounds.width * iPhonePaddingMultiplier
            }

            return compactHorizontalPadding
        }()

        buttonStackViewLeadingConstraint.constant = horizontalPadding
        buttonStackViewTrailingConstraint.constant = horizontalPadding
    }

    func toggleButtonForStatus(_ status: CommentStatusType?) {
        guard let status = status else {
            return
        }

        switch status {
        case .pending:
            togglePending()
        case .approved:
            toggleApproved()
        case .unapproved:
            toggleTrash()
        case .spam:
            toggleSpam()
        default:
            break
        }
    }

    func togglePending() {
        pendingButton.toggleState()
        firstDivider.hideDivider(pendingButton.isSelected)
    }

    func toggleApproved() {
        approvedButton.toggleState()
        firstDivider.hideDivider(approvedButton.isSelected)
        secondDivider.hideDivider(approvedButton.isSelected)
    }

    func toggleSpam() {
        spamButton.toggleState()
        secondDivider.hideDivider(spamButton.isSelected)
        thirdDivider.hideDivider(spamButton.isSelected)
    }

    func toggleTrash() {
        trashButton.toggleState()
        thirdDivider.hideDivider(trashButton.isSelected)
    }

    // MARK: - Button Actions

    @IBAction func pendingTapped() {
        guard !pendingButton.isSelected else {
            return
        }

        updateStatusTo(.pending)
    }

    @IBAction func approvedTapped() {
        guard !approvedButton.isSelected else {
            return
        }

        updateStatusTo(.approved)
    }

    @IBAction func spamTapped() {
        guard !spamButton.isSelected else {
            return
        }

        updateStatusTo(.spam)
    }

    @IBAction func trashTapped() {
        guard !trashButton.isSelected else {
            return
        }

        updateStatusTo(.unapproved)
    }

    func updateStatusTo(_ status: CommentStatusType) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            commentStatus = status
            delegate?.statusChangedTo(status)
        }
    }

}

// MARK: - Moderation Button Types

enum ModerationButtonType {
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
        return Style.defaultImageFor(self)
    }

    var selectedIcon: UIImage? {
        return Style.selectedImageFor(self)
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
            backgroundColor = Style.buttonSelectedBackgroundColor
            layer.shadowColor = Style.buttonSelectedShadowColor
        } else {
            backgroundColor = Style.buttonDefaultBackgroundColor
            layer.shadowColor = Style.buttonDefaultShadowColor
        }
    }

    func configureFor(_ button: ModerationButtonType) {
        setTitle(button.label, for: UIControl.State())
        setImage(button.defaultIcon, for: UIControl.State())
        setImage(button.selectedIcon, for: .selected)

        commonConfigure()
    }

    func commonConfigure() {
        setTitleColor(Style.buttonDefaultTitleColor, for: UIControl.State())
        setTitleColor(Style.buttonSelectedTitleColor, for: .selected)

        layer.cornerRadius = Style.cornerRadius
        layer.shadowOffset = Style.buttonShadowOffset
        layer.shadowOpacity = Style.buttonShadowOpacity
        layer.shadowRadius = Style.buttonShadowRadius

        isExclusiveTouch = true

        verticallyAlignImageAndText()
        flipInsetsForRightToLeftLayoutDirection()
        configureState()
    }

}

// MARK: - UIView Extension

private extension UIView {

    func configureAsDivider() {
        hideDivider(false)

        if let existingConstraint = constraint(for: .width, withRelation: .equal) {
            existingConstraint.constant = .hairlineBorderWidth
        }
    }

    func hideDivider(_ hidden: Bool) {
        backgroundColor = hidden ? Style.dividerHiddenColor : Style.dividerColor
    }

}
