import UIKit
import WordPressFlux
import WordPressUI

public protocol ReaderCommentsNotificationSheetDelegate: AnyObject {
    func didToggleNotificationSwitch(_ isOn: Bool, completion: @escaping (Bool) -> Void)
    func didTapUnfollowConversation()
}

final class ReaderCommentsNotificationSheetViewController: UIViewController {

    // MARK: Properties

    private weak var delegate: ReaderCommentsNotificationSheetDelegate?

    private var isNotificationEnabled: Bool {
        didSet {
            guard oldValue != isNotificationEnabled else {
                return
            }
            updateViews(updatesContentSize: true)
        }
    }

    // MARK: Views

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        scrollView.addSubview(containerStackView)
        scrollView.pinSubviewToAllEdges(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        return scrollView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel, switchContainer, unfollowButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.setCustomSpacing(16, after: descriptionLabel)
        stackView.setCustomSpacing(16, after: switchContainer)
        return stackView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.descriptionLabelFont
        label.textColor = Style.textColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setText(Strings.descriptionTextForDisabledNotifications)
        return label
    }()

    private lazy var switchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews([switchLabel, switchButton])

        NSLayoutConstraint.activate([
            switchLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.switchLabelVerticalPadding),
            switchLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.switchLabelVerticalPadding),
            switchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switchLabel.trailingAnchor.constraint(equalTo: switchButton.leadingAnchor, constant: Constants.switchContainerContentSpacing),

            // prevent the UISwitch from getting shrinked in large content sizes.
            switchButton.widthAnchor.constraint(equalToConstant: switchButton.intrinsicContentSize.width),
            switchButton.centerYAnchor.constraint(equalTo: switchLabel.centerYAnchor),

            // prevent the edge of UISwitch from being clipped.
            switchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.switchButtonTrailingPadding)
        ])

        return view
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Style.switchLabelFont
        label.textColor = Style.textColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setText(Strings.notificationSwitchLabelText)

        return label
    }()

    private lazy var switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        switchButton.onTintColor = Style.switchOnTintColor
        switchButton.isOn = isNotificationEnabled

        switchButton.on(.valueChanged, call: switchValueChanged)
        return switchButton
    }()

    private lazy var unfollowButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(Strings.unfollowButtonTitle, for: .normal)
        button.setTitleColor(Style.textColor, for: .normal)
        button.setBackgroundImage(.renderBackgroundImage(fill: .clear, border: Style.buttonBorderColor), for: .normal)

        button.titleLabel?.font = Style.buttonTitleLabelFont
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true

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

        title = Strings.title
        view.backgroundColor = .systemBackground
        configureViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSize()
    }
}

// MARK: - Private Helpers

private extension ReaderCommentsNotificationSheetViewController {
    typealias Style = WPStyleGuide.ReaderCommentsNotificationSheet

    struct Constants {
        static var contentInsets = UIEdgeInsets(.all, 20)
        static var switchContainerContentSpacing: CGFloat = 4
        static var switchLabelVerticalPadding: CGFloat = 6
        static var switchButtonTrailingPadding: CGFloat = 2
    }

    func configureViews() {
        view.addSubview(scrollView)
        scrollView.pinEdges(insets: Constants.contentInsets)

        // don't update the content size at this state, because the layout pass has not completed.
        // doing so will cause the height to be incorrectly assigned to the preferredContentSize.
        updateViews(updatesContentSize: false)
    }

    func updateViews(updatesContentSize: Bool) {
        descriptionLabel.setText(isNotificationEnabled ? Strings.descriptionTextForEnabledNotifications : Strings.descriptionTextForDisabledNotifications)
        switchButton.isOn = isNotificationEnabled

        if updatesContentSize {
            view.layoutIfNeeded()
            updatePreferredContentSize()
        }
    }

    private func updatePreferredContentSize() {
        let verticalPadding = Constants.contentInsets.top + Constants.contentInsets.bottom
        preferredContentSize = CGSize(width: preferredContentSize.width, height: scrollView.contentSize.height + verticalPadding)
    }

    // MARK: Actions

    func switchValueChanged(_ sender: UISwitch) {
        // nil delegate is most likely an implementation bug. For now, revert the changes on the switch button when this happens.
        guard let delegate else {
            wpAssertionFailure("missing delegate")
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

private enum Strings {
    static let title = NSLocalizedString("reader.followConversationSettings.title", value: "Conversation Settings", comment: "Reader screen title for follow conversation settings")
    static let descriptionTextForDisabledNotifications = NSLocalizedString("You’re following this conversation. You will receive an email whenever a new comment is made.", comment: "Describes the expected behavior when the user enables in-app notifications in Reader Comments.")
    static let descriptionTextForEnabledNotifications = NSLocalizedString("You’re following this conversation. You will receive an email and a notification whenever a new comment is made.", comment: "Describes the expected behavior when the user disables in-app notifications in Reader Comments.")
    static let notificationSwitchLabelText = NSLocalizedString("Enable in-app notifications", comment: "Describes a switch component that toggles in-app notifications for a followed post.")
    static let unfollowButtonTitle = NSLocalizedString("Unfollow Conversation", comment: "Title for a button that unsubscribes the user from the post.")
}
