import Foundation
import WordPressFlux

@objc public protocol ReaderCommentsNotificationSheetDelegate: AnyObject {
    func didToggleNotificationSwitch(_ isOn: Bool, completion: @escaping (Bool) -> Void)
    func didTapUnfollowConversation()
}

@objc class ReaderCommentsNotificationSheetViewController: UIViewController {

    // MARK: Properties

    private weak var delegate: ReaderCommentsNotificationSheetDelegate?

    /// used to cache the "correct" height for the ContainerStackView.
    private var contentHeight: CGFloat = .zero

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
        stackView.setCustomSpacing(Constants.switchContainerTopSpacing, after: descriptionLabel)
        stackView.setCustomSpacing(Constants.switchContainerBottomSpacing, after: switchContainer)

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

    private lazy var switchContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [switchLabel, switchButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill

        return stackView
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.font = Style.switchLabelFont
        label.textColor = Style.textColor
        label.numberOfLines = 0
        label.setText(.notificationSwitchLabelText)

        return label
    }()

    private lazy var switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.setContentHuggingPriority(.required, for: .horizontal)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        contentHeight = max(contentHeight, containerStackView.frame.size.height + verticalPadding)
        preferredContentSize = CGSize(width: preferredContentSize.width, height: contentHeight)
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
        return .intrinsicHeight
    }

    func handleDismiss() {
        // flush out the queued Notices before unlocking. Otherwise, all the Notices would be shown consecutively until the queue is empty.
        ActionDispatcher.dispatch(NoticeAction.empty)
        ActionDispatcher.dispatch(NoticeAction.unlock)
    }
}

// MARK: - Private Helpers

private extension ReaderCommentsNotificationSheetViewController {
    typealias Style = WPStyleGuide.ReaderCommentsNotificationSheet

    struct Constants {
        /// On iPad, the sheet is displayed without the `gripButton` and the additional top spacing that comes with it.
        /// The top padding is added in this case so the spacing looks good on iPad.
        static var contentInsets: NSDirectionalEdgeInsets = .init(top: (WPDeviceIdentification.isiPad() ? 20 : 0), leading: 20, bottom: 20, trailing: 20)
        static var switchContainerTopSpacing: CGFloat = 15.0
        static var switchContainerBottomSpacing: CGFloat = 21.0
    }

    /// Returns the vertical padding outside the intrinsic height of the `containerStackView`, so the component is displayed properly.
    var verticalPadding: CGFloat {
        return Constants.contentInsets.top
            + Constants.contentInsets.bottom
            + additionalVerticalPadding
    }

    /// Calculates the default top margin from the `BottomSheetViewController`, plus the bottom safe area inset.
    var additionalVerticalPadding: CGFloat {
        WPDeviceIdentification.isiPad() ? 0 : BottomSheetViewController.Constants.additionalContentTopMargin + view.safeAreaInsets.bottom
    }

    func configureViews() {
        view.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: Constants.contentInsets.top),
            containerStackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: Constants.contentInsets.leading),
            containerStackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -Constants.contentInsets.trailing),
            containerStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -Constants.contentInsets.bottom)
        ])

        updateViews()
    }

    func updateViews() {
        descriptionLabel.setText(isNotificationEnabled ? .descriptionTextForEnabledNotifications : .descriptionTextForDisabledNotifications)
        switchButton.isOn = isNotificationEnabled

        // changes to the description label may change the content height. inform the drawer to recalculate its position.
        if let drawer = presentedVC {
            // reset the stored content height so it can be recalculated properly.
            contentHeight = .zero
            drawer.transition(to: drawer.currentPosition)
        }
    }

    func switchValueChanged(_ sender: UISwitch) {
        // nil delegate is most likely an implementation bug. For now, revert the changes on the switch button when this happens.
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

            // On iPad, the view is displayed with a popover. Since the dismiss is called programmatically, it will not trigger `handleDismiss`
            // properly, causing the Notice to be forever locked. `handleDismiss` is called here to prevent such event from happening.
            //
            // Consecutive calls to the NoticeAction's `lock` or `unlock` does nothing if they're already in the desired state, so calling
            // `handleDismiss` multiple times should be fine.
            self.handleDismiss()
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
