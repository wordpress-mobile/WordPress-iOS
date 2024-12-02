import UIKit

/// A small card-like view displaying helpful information or prompts to the user.
/// Initialize using the `controllerWithConfiguration` static method.
///
open class FancyAlertViewController: UIViewController {

    /// Intended method of initialization
    public static func controllerWithConfiguration(configuration: Config) -> FancyAlertViewController {
        let infoController = controller()
        infoController.configuration = configuration

        return infoController
    }

    private static func controller() -> FancyAlertViewController {
        let bundle = Bundle.wordPressUIBundle
        return UIStoryboard(name: "FancyAlerts", bundle: bundle).instantiateInitialViewController() as! FancyAlertViewController
    }

    public enum DividerPosition {
        case top
        case topWithPadding
        case bottom
    }

    /// Enapsulates values for all UI components of the info dialog.
    ///
    public struct Config {
        /// Convenience alias for a title and a handler for a UIButton
        public typealias ButtonConfig = (title: String, handler: FancyAlertButtonHandler?)

        public struct SwitchConfig {

            /// Closure representing the action of pressing the switch.
            ///
            /// - Parameters:
            ///     - controller: the fancy alert VC.
            ///     - theSwitch: the switch that received the tap.
            ///
            public typealias Action = (_ controller: FancyAlertViewController, _ theSwitch: UISwitch) -> Void
            public typealias OptionalAction = Action?

            /// The initial value for the switch
            let initialValue: Bool

            /// The text shown next to the switch.
            let text: String

            /// Action closure executed each time the switch is activated
            let action: Action?

            /// Default initializer
            public init(initialValue: Bool,
                        text: String,
                        action: Action? = nil) {

                self.initialValue = initialValue
                self.text = text
                self.action = action
            }
        }

        /// The title of the dialog
        let titleText: String?

        /// The body text of the dialog
        let bodyText: String?

        /// The image displayed at the top of the dialog
        let headerImage: UIImage?

        /// Background color for the header section
        let headerBackgroundColor: UIColor?

        /// The position of the horizontal rule
        let dividerPosition: DividerPosition?

        /// Title / handler for the primary button on the dialog
        let defaultButton: ButtonConfig?

        /// Title / handler for the de-emphasised cancel button on the dialog
        let cancelButton: ButtonConfig?

        /// Title / handler for a second de-emphasised button on the dialog
        let neverButton: ButtonConfig?

        /// Title / handler for a link-style button displayed beneath the body text
        let moreInfoButton: ButtonConfig?

        /// Title handler for a small 'tag' style button displayed next to the title
        let titleAccessoryButton: ButtonConfig?

        /// Configuration for the switch at the bottom of the alert.
        let switchConfig: SwitchConfig?

        /// A block to execute when the view has appeared
        let appearAction: (() -> Void)?

        /// A block to execute after this view controller has been dismissed
        let dismissAction: (() -> Void)?

        /// Config Initializer. Required since the default one cannot be set as public.
        ///
        public init(titleText: String?,
                    bodyText: String?,
                    headerImage: UIImage?,
                    headerBackgroundColor: UIColor? = nil,
                    dividerPosition: DividerPosition?,
                    defaultButton: ButtonConfig?,
                    cancelButton: ButtonConfig?,
                    neverButton: ButtonConfig? = nil,
                    moreInfoButton: ButtonConfig? = nil,
                    titleAccessoryButton: ButtonConfig? = nil,
                    switchConfig: SwitchConfig? = nil,
                    appearAction: (() -> Void)? = nil,
                    dismissAction: (() -> Void)? = nil) {

            self.titleText = titleText
            self.bodyText = bodyText
            self.headerImage = headerImage
            self.headerBackgroundColor = headerBackgroundColor
            self.dividerPosition = dividerPosition
            self.defaultButton = defaultButton
            self.cancelButton = cancelButton
            self.neverButton = neverButton
            self.moreInfoButton = moreInfoButton
            self.titleAccessoryButton = titleAccessoryButton
            self.switchConfig = switchConfig
            self.appearAction = appearAction
            self.dismissAction = dismissAction
        }
    }

    // MARK: - Constants

    private struct Constants {
        static let cornerRadius: CGFloat = 15.0
        static let headerImageVerticalConstraintCompact: CGFloat = 0.0
        static let headerImageVerticalConstraintRegular: CGFloat = 20.0

        static let fadeAnimationDuration: TimeInterval = 0.3
        static let resizeAnimationDuration: TimeInterval = 0.3
        static let resizeAnimationDelay: TimeInterval = 0.3
    }

    // MARK: - Properties

    /// Header's Height
    ///
    private var headerImageViewHeightConstraint: NSLayoutConstraint?

    /// Gesture recognizer for taps on the dialog if no buttons are present
    ///
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer!

    /// Allows compact alerts to be dismissed by 'flinging' them offscreen
    ///
    fileprivate var handler: FlingableViewHandler!

    /// Stores handlers for buttons passed in the current configuration
    ///
    private var buttonHandlers = [UIButton: FancyAlertButtonHandler]()

    /// FancyAlertButtonHandler: onTouchUP callback!
    ///
    public typealias FancyAlertButtonHandler = (FancyAlertViewController, UIButton) -> Void

    /// Active Configuration
    ///
    private(set) var configuration: Config?

    /// FancyAlertView Reference
    ///
    @IBOutlet private weak var alertView: FancyAlertView!

    /// The configuration determines the content and visibility of all UI
    /// components in the dialog. Changing this value after presenting the
    /// dialog is supported, and will result in the view (optionally) fading
    /// to the new values and resizing itself to fit.
    ///
    /// - parameters:
    ///   - configuration: A new configuration to display.
    ///   - animated: If true, the UI will animate as it updates to reflect the new configuration.
    ///   - alongside: An optional animation block which will be animated
    ///                alongside the new configuration's fade in animation.
    ///
    open func setViewConfiguration(_ configuration: Config,
                                   animated: Bool,
                                   alongside animation: ((FancyAlertViewController) -> Void)? = nil) {
        self.configuration = configuration

        if animated {
            fadeAllViews(visible: false, completion: { _ in
                UIView.animate(withDuration: Constants.resizeAnimationDuration,
                               delay: Constants.resizeAnimationDelay,
                               options: [],
                               animations: {
                                self.updateViewConfiguration()
                }, completion: { _ in
                    self.fadeAllViews(visible: true, alongside: animation)
                })
            })
        } else {
            updateViewConfiguration()
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        accessibilityViewIsModal = true

        view.backgroundColor = .clear

        dismissGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        view.addGestureRecognizer(dismissGestureRecognizer)

        alertView.wrapperView.layer.masksToBounds = true
        alertView.wrapperView.layer.cornerRadius = Constants.cornerRadius

        updateViewConfiguration()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateFlingableViewHandler()

        self.configuration?.appearAction?()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            alertView.headerImageWrapperView.isHiddenInStackView = true
        } else if let _ = configuration?.headerImage {
            alertView.headerImageWrapperView.isHiddenInStackView = false
        }

        alertView.updateButtonLayout()
    }

    // MARK: - View configuration

    private func updateViewConfiguration() {
        guard isViewLoaded else { return }
        guard let configuration else { return }

        buttonHandlers.removeAll()

        alertView.titleLabel.text = configuration.titleText
        alertView.bodyLabel.text = configuration.bodyText

        alertView.titleLabel.adjustsFontForContentSizeCategory = true
        alertView.bodyLabel.adjustsFontForContentSizeCategory = true

        updateDivider()

        updateHeader()

        update(alertView.defaultButton, with: configuration.defaultButton)
        update(alertView.cancelButton, with: configuration.cancelButton)
        update(alertView.neverButton, with: configuration.neverButton)
        update(alertView.moreInfoButton, with: configuration.moreInfoButton)
        update(alertView.titleAccessoryButton, with: configuration.titleAccessoryButton)
        updateBottomSwitch(with: configuration.switchConfig)

        alertView.defaultButton.accessibilityIdentifier = "fancy-alert-view-default-button"
        alertView.cancelButton.accessibilityIdentifier = "fancy-alert-view-cancel-button"

        // If we have no title accessory button, we need to
        // disable the trailing constraint to allow the title to flow correctly
        alertView.titleAccessoryButtonTrailingConstraint.isActive = (configuration.titleAccessoryButton != nil)

        // If both primary buttons are hidden, we'll hide the bottom area of the dialog
        alertView.buttonWrapperView.isHiddenInStackView = isButtonless

        // If both primary buttons are hidden, we'll shrink the header image view down a little
        let constant = isImageCompact ? Constants.headerImageVerticalConstraintCompact : Constants.headerImageVerticalConstraintRegular
        alertView.headerImageViewTopConstraint.constant = constant
        alertView.headerImageViewBottomConstraint.constant = constant

        updateFlingableViewHandler()

        // If both primary buttons are hidden, the user can tap anywhere on the dialog to dismiss it
        dismissGestureRecognizer.isEnabled = isButtonless

        view.layoutIfNeeded()

        alertView.updateButtonLayout()

        alertView.titleLabel.accessibilityHint = (isButtonless) ? NSLocalizedString("Double tap to dismiss", comment: "Voiceover accessibility hint informing the user they can double tap a modal alert to dismiss it") : nil

        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: alertView.titleLabel)
    }

    private func updateHeader() {
        if let headerImage = configuration?.headerImage {
            alertView.headerImageView.image = headerImage
            alertView.headerImageWrapperView.isHiddenInStackView = false

            if let heightConstraint = headerImageViewHeightConstraint {
                alertView.headerImageView.removeConstraint(heightConstraint)
            }

            // set the aspect ratio constraint
            let imageAspectRatio = headerImage.size.height / headerImage.size.width
            headerImageViewHeightConstraint = alertView.headerImageView.heightAnchor.constraint(equalTo: alertView.headerImageView.widthAnchor, multiplier: imageAspectRatio)
            headerImageViewHeightConstraint?.isActive = true
        } else {
            alertView.headerImageWrapperView.isHiddenInStackView = true
        }

        if let headerBackgroundColor = configuration?.headerBackgroundColor {
            alertView.headerBackgroundColor = headerBackgroundColor
        }
    }

    private func updateDivider() {
        guard let dividerPosition = configuration?.dividerPosition else {
            return
        }

        switch dividerPosition {
        case .bottom:
            alertView.topDividerView.isHiddenInStackView = true
            alertView.bottomDividerView.isHiddenInStackView = isButtonless

            alertView.headerImageViewWrapperBottomConstraint?.constant = Constants.headerImageVerticalConstraintRegular
            alertView.buttonWrapperViewTopConstraint?.constant = Constants.headerImageVerticalConstraintRegular
        case .top:
            alertView.topDividerView.isHiddenInStackView = false
            alertView.bottomDividerView.isHiddenInStackView = true

            // the image touches the divider if it is at the top
            alertView.headerImageViewWrapperBottomConstraint?.constant = 0.0
            alertView.buttonWrapperViewTopConstraint?.constant = 0.0
        case .topWithPadding:
            alertView.topDividerView.isHiddenInStackView = false
            alertView.bottomDividerView.isHiddenInStackView = true

            alertView.headerImageViewWrapperBottomConstraint?.constant = 0.0
            alertView.buttonWrapperViewTopConstraint?.constant = 0.0
            alertView.headerImageViewTopConstraint.constant = 0.0
            alertView.headerImageViewWrapperTopConstraint.constant = 0.0
        }
    }

    private func update(_ button: UIButton, with buttonConfig: Config.ButtonConfig?) {
        guard let buttonConfig else {
            button.isHiddenInStackView = true
            return
        }

        button.isHiddenInStackView = false

        button.setTitle(buttonConfig.title, for: .normal)
        buttonHandlers[button] = buttonConfig.handler
    }

    private func updateBottomSwitch(with config: Config.SwitchConfig?) {
        guard let config else {
            alertView.bottomSwitchStackView.isHiddenInStackView = true
            return
        }

        alertView.bottomSwitchStackView.isHiddenInStackView = false

        alertView.bottomSwitch.setOn(config.initialValue, animated: false)
        alertView.bottomSwitch.on(.touchUpInside) { [unowned self] theSwitch in
            config.action?(self, theSwitch)
        }
        alertView.bottomSwitchLabel.text = config.text
    }

    private func updateFlingableViewHandler() {
        guard view.superview != nil else { return }

        if handler == nil {
            handler = FlingableViewHandler(targetView: view)
            handler.delegate = self
        }

        // Flingable handler is active if both buttons are hidden
        handler.isActive = isButtonless
    }

    /// An alert is buttonless if both of the bottom buttons are hidden
    ///
    private var isButtonless: Bool {
        return alertView.defaultButton.isHiddenInStackView && alertView.cancelButton.isHiddenInStackView
    }

    /// The header image is compact if the divider is at the top or the alert is buttonless
    ///
    private var isImageCompact: Bool {
        return configuration?.dividerPosition == .top || isButtonless
    }

    // MARK: - Bottom Switch

    public func isBottomSwitchOn() -> Bool {
        return alertView.bottomSwitch.isOn
    }

    // MARK: - Animation

    @objc func fadeAllViews(visible: Bool, alongside animation: ((FancyAlertViewController) -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: Constants.fadeAnimationDuration, animations: {
            self.alertView.contentViews.forEach { $0.alpha = (visible) ? 1 : 0 }
            animation?(self)
        }, completion: completion)
    }

    // MARK: - Actions

    @objc fileprivate func dismissTapped() {
        dismiss(animated: true, completion: {
            self.configuration?.dismissAction?()
        })
    }

    @IBAction private func buttonTapped(_ sender: UIButton) {
        // Offload to a handler if one is configured for this button
        if let handler = buttonHandlers[sender] {
            handler(self, sender)
        }
    }

    override open func accessibilityPerformEscape() -> Bool {
        dismissTapped()
        return true
    }
}

// MARK: - FlingableViewHandlerDelegate

extension FancyAlertViewController: FlingableViewHandlerDelegate {
    public func flingableViewHandlerDidBeginRecognizingGesture(_ handler: FlingableViewHandler) {
        dismissGestureRecognizer.isEnabled = false
    }

    public func flingableViewHandlerWasCancelled(_ handler: FlingableViewHandler) {
        dismissGestureRecognizer.isEnabled = true
    }

    public func flingableViewHandlerDidEndRecognizingGesture(_ handler: FlingableViewHandler) {
        dismissTapped()
    }
}

private extension UIView {
    /// Required to work around a bug in UIStackView where items don't become
    /// hidden / unhidden correctly if you set their `isHidden` property
    /// to the same value twice in a row. See http://www.openradar.me/22819594
    ///
    var isHiddenInStackView: Bool {
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }

        get {
            return isHidden
        }
    }
}
