import Foundation
import WordPressFlux

@objc public protocol ReaderCommentsNotificationSheetDelegate: AnyObject {
    func didToggleNotificationSwitch(_ isOn: Bool, completion: @escaping (Bool) -> Void)
    func didTapUnfollowConversation()
}

@objc class ReaderCommentsNotificationSheetViewController: UIViewController {

    // MARK: Properties

    private weak var delegate: ReaderCommentsNotificationSheetDelegate?

    private var isNotificationEnabled: Bool {
        didSet {
            guard oldValue != isNotificationEnabled else {
                return
            }

            updateViews()
        }
    }

    // MARK: Views

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel, switchContainer, unfollowButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 15.0
        stackView.setCustomSpacing(9.0, after: descriptionLabel)

        return stackView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.descriptionLabelFont
        label.textColor = Style.textColor
        label.numberOfLines = 0
        label.setText(.descriptionTextForDisabledNotifications)

        return label
    }()

    private lazy var switchContainer: UIView = {
        let stackView = UIStackView(arrangedSubviews: [switchLabel, UIView(), switchButton])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20.0

        return stackView
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = Style.switchLabelFont
        label.textColor = Style.textColor
        label.numberOfLines = 0
        label.setText(.notificationSwitchLabelText)

        return label
    }()

    private lazy var switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.onTintColor = Style.switchOnTintColor
        switchButton.isOn = isNotificationEnabled

        switchButton.on(.valueChanged, call: switchValueChanged)
        return switchButton
    }()

    private lazy var unfollowButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.unfollowButtonTitle, for: .normal)
        button.setTitleColor(Style.textColor, for: .normal)
        button.setBackgroundImage(.renderBackgroundImage(fill: .clear, border: Style.buttonBorderColor), for: .normal)

        button.titleLabel?.font = Style.buttonTitleLabelFont
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0

        // add constraints to the button's title label so it can contain multi-line cases properly.
        if let label = button.titleLabel {
            button.pinSubviewToAllEdgeMargins(label)
        }

        button.on(.touchUpInside, call: unfollowButtonTapped)
        return button
    }()

    // MARK: Lifecycle

    required init(isNotificationEnabled: Bool, delegate: ReaderCommentsNotificationSheetDelegate? = nil) {
        self.isNotificationEnabled = isNotificationEnabled
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()

        // prevent Notices from being shown while the bottom sheet is displayed.
        ActionDispatcher.dispatch(NoticeAction.lock)
    }
}

// MARK: Drawer Presentable

extension ReaderCommentsNotificationSheetViewController: DrawerPresentable {
    var allowsUserTransition: Bool {
        return false
    }

    var collapsedHeight: DrawerHeight {
        if traitCollection.verticalSizeClass == .compact {
            return .maxHeight
        }

        view.layoutIfNeeded()
        return .contentHeight(containerStackView.frame.height
                                + BottomSheetViewController.Constants.additionalContentTopMargin
                                + view.safeAreaInsets.bottom
                                + Constants.contentInset)
    }

    func handleDismiss() {
        // flush out the queued Notices before unlocking. Otherwise, all the Notices would be shown one after the other until the queue is empty.
        ActionDispatcher.dispatch(NoticeAction.empty)
        ActionDispatcher.dispatch(NoticeAction.unlock)
    }
}

// MARK: - Private Helpers

private extension ReaderCommentsNotificationSheetViewController {
    typealias Style = WPStyleGuide.ReaderCommentsNotificationSheet

    struct Constants {
        static let contentInset: CGFloat = 20
    }

    func configureViews() {
        view.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: Constants.contentInset),
            containerStackView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -Constants.contentInset),
            containerStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Constants.contentInset)
        ])

        updateViews()
    }

    func updateViews() {
        descriptionLabel.setText(isNotificationEnabled ? .descriptionTextForEnabledNotifications : .descriptionTextForDisabledNotifications)
        switchButton.isOn = isNotificationEnabled

        // changes to the description label may change the content height. inform the drawer to recalculate its position.
        if let drawer = presentedVC {
            drawer.transition(to: drawer.currentPosition)
        }
    }

    func switchValueChanged(_ sender: UISwitch) {
        // nil delegate is most likely an implementation bug. For now, revert the changes to the switch button.
        guard let delegate = delegate else {
            DDLogInfo("\(Self.classNameWithoutNamespaces()): delegate instance is nil")
            isNotificationEnabled = !sender.isOn
            return
        }

        // prevent spam clicks by disabling the user interaction on the switch button.
        // the tint color is temporarily changed to indicate that some process is in progress.
        switchButton.onTintColor = Style.switchInProgressTintColor
        switchButton.isUserInteractionEnabled = false

        // optimistically update the views first.
        isNotificationEnabled = sender.isOn

        delegate.didToggleNotificationSwitch(sender.isOn) { success in
            if !success {
                // in case of failure, revert state changes.
                self.isNotificationEnabled = !sender.isOn
            }
            self.switchButton.onTintColor = Style.switchOnTintColor
            self.switchButton.isUserInteractionEnabled = true
        }
    }

    func unfollowButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.delegate?.didTapUnfollowConversation()
        }
    }
}

// MARK: - Localization

private extension String {
    static let descriptionTextForDisabledNotifications = NSLocalizedString("You’re following this conversation. "
                                                                            + "You will receive an email whenever a new comment is made.",
                                                                           comment: "Describes the expected behavior when the user enables in-app "
                                                                            + "notifications in Reader Comments.")
    static let descriptionTextForEnabledNotifications = NSLocalizedString("You’re following this conversation. "
                                                                            + "You will receive an email and a notification whenever a new comment is made.",
                                                                          comment: "Describes the expected behavior when the user disables in-app "
                                                                            + "notifications in Reader Comments.")
    static let notificationSwitchLabelText = NSLocalizedString("Enable in-app notifications",
                                                               comment: "Describes a switch component that toggles in-app notifications for a followed post.")
    static let unfollowButtonTitle = NSLocalizedString("Unfollow conversation",
                                                       comment: "Title for a button that unsubscribes the user from the post.")
}
