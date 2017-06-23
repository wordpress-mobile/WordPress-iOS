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

        /// Title / handler for the primary button on the dialog
        let defaultButton: ButtonConfig?

        /// Title / handler for the de-emphasised cancel button on the dialog
        let cancelButton: ButtonConfig?

        /// Title / handler for a link-style button displayed beneath the body text
        let moreInfoButton: ButtonConfig?

        /// Title handler for a small 'tag' style button displayed next to the title
        let titleAccessoryButton: ButtonConfig?
    }

    // MARK: - Constants

    private struct Constants {
        static let cornerRadius: CGFloat = 15.0
        static let buttonFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let headerImageVerticalConstraintCompact: CGFloat = 0.0
        static let headerImageVerticalConstraintRegular: CGFloat = 20.0
    }

    // MARK - IBOutlets

    /// Wraps the entire view to give it a background and rounded corners
    @IBOutlet weak var wrapperView: UIView!

    @IBOutlet weak var headerImageWrapperView: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerImageViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    /// Divides the primary buttons from the rest of the dialog
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var buttonWrapperView: UIView!
    @IBOutlet weak var buttonStackView: UIStackView!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var defaultButton: UIButton!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var titleAccessoryButton: UIButton!

    /// Gesture recognizer for taps on the dialog if no buttons are present
    ///
    private var dismissGestureRecognizer: UITapGestureRecognizer!

    /// Stores handlers for buttons passed in the current configuration
    ///
    private var buttonHandlers = [UIButton: FancyAlertButtonHandler]()

    typealias FancyAlertButtonHandler = (FancyAlertViewController) -> Void

    /// The configuration determines the content and visibility of all UI
    /// components in the dialog. Changing this value after presenting the
    /// dialog is supported, and will result in the view fading to the new
    /// values and resizing itself to fit.
    ///
    var configuration: Config? {
        didSet {
            updateViewConfiguration()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dismissGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        view.addGestureRecognizer(dismissGestureRecognizer)

        wrapperView.layer.masksToBounds = true
        wrapperView.layer.cornerRadius = Constants.cornerRadius

        headerImageWrapperView.backgroundColor = WPStyleGuide.lightGrey()
        headerImageWrapperView.superview?.backgroundColor = WPStyleGuide.lightGrey()
        dividerView.backgroundColor = WPStyleGuide.lightGrey()

        titleLabel.textColor = WPStyleGuide.darkGrey()
        bodyLabel.textColor = WPStyleGuide.greyDarken10()

        configureBetaButton(titleAccessoryButton)

        defaultButton.titleLabel?.font = Constants.buttonFont
        cancelButton.titleLabel?.font = Constants.buttonFont

        moreInfoButton.titleLabel?.font = WPFontManager.systemBoldFont(ofSize: bodyLabel.font.pointSize)
        moreInfoButton.tintColor = WPStyleGuide.wordPressBlue()

        updateViewConfiguration()
    }

    private func updateViewConfiguration() {
        guard isViewLoaded else { return }
        guard let configuration = configuration else { return }

        buttonHandlers.removeAll()

        titleLabel.text = configuration.titleText
        bodyLabel.text = configuration.bodyText

        updateHeaderImage()

        update(defaultButton, with: configuration.defaultButton)
        update(cancelButton, with: configuration.cancelButton)
        update(moreInfoButton, with: configuration.moreInfoButton)
        update(titleAccessoryButton, with: configuration.titleAccessoryButton)

        // If both primary buttons are hidden, we'll hide the bottom area of the dialog
        let bothButtonsHidden = defaultButton.isHiddenInStackView && cancelButton.isHiddenInStackView
        buttonWrapperView.isHiddenInStackView = bothButtonsHidden
        dividerView.isHiddenInStackView = bothButtonsHidden

        // If both primary buttons are hidden, we'll shrink the header image view down a little
        let constant = bothButtonsHidden ? Constants.headerImageVerticalConstraintCompact : Constants.headerImageVerticalConstraintRegular
        headerImageViewTopConstraint.constant = constant
        headerImageViewBottomConstraint.constant = constant

        // If both primary buttons are hidden, the user can tap anywhere on the dialog to dismiss it
        dismissGestureRecognizer.isEnabled = bothButtonsHidden
    }

    private func updateHeaderImage() {
        if let headerImage = configuration?.headerImage {
            headerImageView.image = headerImage
            headerImageWrapperView.isHiddenInStackView = false
        } else {
            headerImageWrapperView.isHiddenInStackView = true
        }
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

    func configureBetaButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11.0)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 3.0

        button.tintColor = WPStyleGuide.darkGrey()
        button.setTitleColor(WPStyleGuide.darkGrey(), for: .disabled)
        button.layer.borderColor = WPStyleGuide.greyLighten20().cgColor

        let verticalInset = CGFloat(6.0)
        let horizontalInset = CGFloat(8.0)
        button.contentEdgeInsets = UIEdgeInsets(top: verticalInset,
                                                left: horizontalInset,
                                                bottom: verticalInset,
                                                right: horizontalInset)
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func buttonTapped(_ sender: UIButton) {
        // Offload to a handler if one is configured for this button
        if let handler = buttonHandlers[sender] {
            handler(self)
        }
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
