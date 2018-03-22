import UIKit

/// A small card-like view displaying helpful information or prompts to the user.
/// Initialize using the `controllerWithConfiguration` static method.
///
class FancyAlertViewController: UIViewController {

    /// Intended method of initialization
    static func controllerWithConfiguration(configuration: Config) -> FancyAlertViewController {
        let infoController = controller()
        infoController.configuration = configuration

        return infoController
    }

    private static func controller() -> FancyAlertViewController {
        return UIStoryboard(name: "FancyAlerts", bundle: Bundle.main)
            .instantiateInitialViewController() as! FancyAlertViewController
    }

    enum DividerPosition {
        case top
        case bottom
    }

    /// Enapsulates values for all UI components of the info dialog.
    ///
    struct Config {
        /// Convenience alias for a title and a handler for a UIButton
        typealias ButtonConfig = (title: String, handler: FancyAlertButtonHandler?)

        /// The title of the dialog
        let titleText: String?

        /// The body text of the dialog
        let bodyText: String?

        /// The image displayed at the top of the dialog
        let headerImage: UIImage?

        /// The position of the horizontal rule
        let dividerPosition: DividerPosition?

        /// Title / handler for the primary button on the dialog
        let defaultButton: ButtonConfig?

        /// Title / handler for the de-emphasised cancel button on the dialog
        let cancelButton: ButtonConfig?

        /// Title / handler for a link-style button displayed beneath the body text
        let moreInfoButton: ButtonConfig?

        /// Title handler for a small 'tag' style button displayed next to the title
        let titleAccessoryButton: ButtonConfig?

        /// A block to execute after this view controller has been dismissed
        let dismissAction: (() -> Void)?
    }

    // MARK: - Constants

    private struct Constants {
        static let cornerRadius: CGFloat = 15.0
        static let buttonFont = WPStyleGuide.fontForTextStyle(.headline)
        static let moreInfoFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        static let bodyFont = WPStyleGuide.fontForTextStyle(.body)
        static let headerImageVerticalConstraintCompact: CGFloat = 0.0
        static let headerImageVerticalConstraintRegular: CGFloat = 20.0
        static let headerBackgroundColor = WPStyleGuide.lightGrey()

        static let fadeAnimationDuration: TimeInterval = 0.3
        static let resizeAnimationDuration: TimeInterval = 0.3
        static let resizeAnimationDelay: TimeInterval = 0.3
    }

    // MARK: - IBOutlets

    /// Wraps the entire view to give it a background and rounded corners
    @IBOutlet private weak var wrapperView: UIView!

    @IBOutlet private weak var headerImageWrapperView: UIView!
    @IBOutlet private(set) weak var headerImageView: UIImageView!
    private var headerImageViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var headerImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var headerImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var headerImageViewWrapperBottomConstraint: NSLayoutConstraint?
    @IBOutlet private weak var buttonWrapperViewTopConstraint: NSLayoutConstraint?
    @IBOutlet private var titleAccessoryButtonTrailingConstraint: NSLayoutConstraint!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!

    /// Divides the primary buttons from the rest of the dialog
    @IBOutlet private weak var topDividerView: UIView!
    @IBOutlet private weak var bottomDividerView: UIView!
    @IBOutlet private weak var buttonWrapperView: UIView!
    @IBOutlet private weak var buttonStackView: UIStackView!

    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var defaultButton: UIButton!
    @IBOutlet private weak var moreInfoButton: UIButton!
    @IBOutlet private weak var titleAccessoryButton: UIButton!

    @IBOutlet private var contentViews: [UIView]!

    /// Gesture recognizer for taps on the dialog if no buttons are present
    ///
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer!

    /// Allows compact alerts to be dismissed by 'flinging' them offscreen
    ///
    fileprivate var handler: FlingableViewHandler!

    /// Stores handlers for buttons passed in the current configuration
    ///
    private var buttonHandlers = [UIButton: FancyAlertButtonHandler]()

    typealias FancyAlertButtonHandler = (FancyAlertViewController, UIButton) -> Void

    private(set) var configuration: Config?

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
    func setViewConfiguration(_ configuration: Config,
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

    override func viewDidLoad() {
        super.viewDidLoad()

        accessibilityViewIsModal = true

        view.backgroundColor = .clear

        dismissGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        view.addGestureRecognizer(dismissGestureRecognizer)

        wrapperView.layer.masksToBounds = true
        wrapperView.layer.cornerRadius = Constants.cornerRadius

        headerImageWrapperView.backgroundColor = Constants.headerBackgroundColor
        topDividerView.backgroundColor = WPStyleGuide.greyLighten30()
        bottomDividerView.backgroundColor = WPStyleGuide.lightGrey()

        WPStyleGuide.configureLabel(titleLabel, textStyle: .title2, fontWeight: .semibold)
        titleLabel.textColor = WPStyleGuide.darkGrey()
        WPStyleGuide.configureLabel(bodyLabel, textStyle: .body)
        bodyLabel.textColor = WPStyleGuide.darkGrey()

        WPStyleGuide.configureBetaButton(titleAccessoryButton)

        defaultButton.titleLabel?.font = Constants.buttonFont
        cancelButton.titleLabel?.font = Constants.buttonFont

        moreInfoButton.titleLabel?.font = Constants.moreInfoFont
        moreInfoButton.tintColor = WPStyleGuide.wordPressBlue()

        updateViewConfiguration()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateFlingableViewHandler()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            headerImageWrapperView.isHiddenInStackView = true
        } else if let _ = configuration?.headerImage {
            headerImageWrapperView.isHiddenInStackView = false
        }
    }

    /// MARK: - View configuration

    private func updateViewConfiguration() {
        guard isViewLoaded else { return }
        guard let configuration = configuration else { return }

        buttonHandlers.removeAll()

        titleLabel.text = configuration.titleText
        bodyLabel.text = configuration.bodyText

        updateDivider()

        updateHeaderImage()

        update(defaultButton, with: configuration.defaultButton)
        update(cancelButton, with: configuration.cancelButton)
        update(moreInfoButton, with: configuration.moreInfoButton)
        update(titleAccessoryButton, with: configuration.titleAccessoryButton)

        // If we have no title accessory button, we need to
        // disable the trailing constraint to allow the title to flow correctly
        titleAccessoryButtonTrailingConstraint.isActive = (configuration.titleAccessoryButton != nil)

        // If both primary buttons are hidden, we'll hide the bottom area of the dialog
        buttonWrapperView.isHiddenInStackView = isButtonless

        // If both primary buttons are hidden, we'll shrink the header image view down a little
        let constant = isImageCompact ? Constants.headerImageVerticalConstraintCompact : Constants.headerImageVerticalConstraintRegular
        headerImageViewTopConstraint.constant = constant
        headerImageViewBottomConstraint.constant = constant

        updateFlingableViewHandler()

        // If both primary buttons are hidden, the user can tap anywhere on the dialog to dismiss it
        dismissGestureRecognizer.isEnabled = isButtonless

        view.layoutIfNeeded()

        titleLabel.accessibilityHint = (isButtonless) ? NSLocalizedString("Double tap to dismiss", comment: "Voiceover accessibility hint informing the user they can double tap a modal alert to dismiss it") : nil

        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, titleLabel)
    }

    private func updateHeaderImage() {
        if let headerImage = configuration?.headerImage {
            headerImageView.image = headerImage
            headerImageWrapperView.isHiddenInStackView = false

            if let heightConstraint = headerImageViewHeightConstraint {
                headerImageView.removeConstraint(heightConstraint)
            }

            // set the aspect ratio constraint
            let imageAspectRatio = headerImage.size.height / headerImage.size.width
            headerImageViewHeightConstraint = headerImageView.heightAnchor.constraint(equalTo: headerImageView.widthAnchor, multiplier: imageAspectRatio)
            headerImageViewHeightConstraint?.isActive = true
        } else {
            headerImageWrapperView.isHiddenInStackView = true
        }
    }

    private func updateDivider() {
        topDividerView.isHiddenInStackView = configuration?.dividerPosition == .bottom
        bottomDividerView.isHiddenInStackView = isButtonless || configuration?.dividerPosition == .top

        // the image touches the divider if it is at the top
        headerImageViewWrapperBottomConstraint?.constant = configuration?.dividerPosition == .top ? 0.0 : Constants.headerImageVerticalConstraintRegular
        buttonWrapperViewTopConstraint?.constant = configuration?.dividerPosition == .top ? 0.0 : Constants.headerImageVerticalConstraintRegular
    }

    private func update(_ button: UIButton, with buttonConfig: Config.ButtonConfig?) {
        guard let buttonConfig = buttonConfig else {
            button.isHiddenInStackView = true
            return
        }

        button.isHiddenInStackView = false

        button.setTitle(buttonConfig.title, for: .normal)
        buttonHandlers[button] = buttonConfig.handler
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
        return defaultButton.isHiddenInStackView && cancelButton.isHiddenInStackView
    }

    /// The header image is compact if the divider is at the top or the alert is buttonless
    ///
    private var isImageCompact: Bool {
        return configuration?.dividerPosition == .top || isButtonless
    }

    // MARK: - Animation

    @objc func fadeAllViews(visible: Bool, alongside animation: ((FancyAlertViewController) -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: Constants.fadeAnimationDuration, animations: {
            self.contentViews.forEach { $0.alpha = (visible) ? UIKitConstants.alphaFull : UIKitConstants.alphaZero }
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

    override func accessibilityPerformEscape() -> Bool {
        dismissTapped()
        return true
    }
}

// MARK: - FlingableViewHandlerDelegate

extension FancyAlertViewController: FlingableViewHandlerDelegate {
    func flingableViewHandlerDidBeginRecognizingGesture(_ handler: FlingableViewHandler) {
        dismissGestureRecognizer.isEnabled = false
    }

    func flingableViewHandlerWasCancelled(_ handler: FlingableViewHandler) {
        dismissGestureRecognizer.isEnabled = true
    }

    func flingableViewHandlerDidEndRecognizingGesture(_ handler: FlingableViewHandler) {
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
