import UIKit
import WordPressAuthenticator


@objc protocol NoResultsViewControllerDelegate {
    @objc optional func actionButtonPressed()
    @objc optional func dismissButtonPressed()
}

/// A view to show when there are no results for a given situation.
/// Ex: My Sites > account has no sites; My Sites > all sites are hidden.
/// The title will always show.
/// The image will always show unless an accessoryView is provided.
/// The action button is shown by default, but will be hidden if button title is not provided.
/// The subtitle is optional and will only show if provided.
///
@objc class NoResultsViewController: NUXViewController {

    // MARK: - Properties

    @objc weak var delegate: NoResultsViewControllerDelegate?
    @IBOutlet weak var noResultsView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleTextView: UITextView!
    @IBOutlet weak var actionButton: NUXButton!
    @IBOutlet weak var accessoryView: UIView!

    // To allow storing values until view is loaded.
    private var titleText: String?
    private var subtitleText: String?
    private var attributedSubtitleText: NSAttributedString?
    private var buttonText: String?
    private var imageName: String?
    private var accessorySubview: UIView?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        configureView()
    }

    /// Public method to get controller instance and set view values.
    ///
    /// - Parameters:
    ///   - title:              Main descriptive text. Required.
    ///   - buttonTitle:        Title of action button. Optional.
    ///   - subtitle:           Secondary descriptive text. Optional.
    ///   - attributedSubtitle: Secondary descriptive attributed text. Optional.
    ///   - image:              Name of image file to use. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc class func controllerWith(title: String,
                                    buttonTitle: String? = nil,
                                    subtitle: String? = nil,
                                    attributedSubtitle: NSAttributedString? = nil,
                                    image: String? = nil,
                                    accessoryView: UIView? = nil) -> NoResultsViewController {
        let controller = NoResultsViewController.controller()
        controller.titleText = title
        controller.subtitleText = subtitle
        controller.attributedSubtitleText = attributedSubtitle
        controller.buttonText = buttonTitle
        controller.imageName = image
        controller.accessorySubview = accessoryView
        return controller
    }

    /// Public method to get controller instance.
    /// As this only creates the controller, the configure method should be called
    /// to set the view values before presenting the No Results View.
    ///
    @objc class func controller() -> NoResultsViewController {
        let storyBoard = UIStoryboard(name: "NoResults", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "NoResults") as! NoResultsViewController
        return controller
    }

    /// Public method to provide values for text elements.
    ///
    /// - Parameters:
    ///   - title:              Main descriptive text. Required.
    ///   - buttonTitle:        Title of action button. Optional.
    ///   - subtitle:           Secondary descriptive text. Optional.
    ///   - attributedSubtitle: Secondary descriptive attributed text. Optional.
    ///   - image:              Name of image file to use. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc func configure(title: String,
                         buttonTitle: String? = nil,
                         subtitle: String? = nil,
                         attributedSubtitle: NSAttributedString? = nil,
                         image: String? = nil,
                         accessoryView: UIView? = nil) {
        titleText = title
        subtitleText = subtitle
        attributedSubtitleText = attributedSubtitle
        buttonText = buttonTitle
        imageName = image
        accessorySubview = accessoryView
    }

    /// Public method to remove No Results View from parent view.
    ///
    @objc func removeFromView() {
        willMove(toParentViewController: nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }

    /// Public method to show a 'Dismiss' button in the navigation bar in place of the 'Back' button.
    ///
    func showDismissButton() {
        navigationItem.hidesBackButton = true

        let dismissButton = UIBarButtonItem(title: NSLocalizedString("Dismiss", comment: "Dismiss button title."),
                                            style: .done,
                                            target: self,
                                            action: #selector(self.dismissButtonPressed))
        dismissButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Dismiss button title.")
        navigationItem.leftBarButtonItem = dismissButton
    }

    /// Public method to get the view height when adding the No Results View to a table cell.
    ///
    func heightForTableCell() -> CGFloat {
        return noResultsView.frame.height
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setAccessoryViewsVisibility()
    }

}

private extension NoResultsViewController {

    // MARK: - View

    func configureView() {

        guard let titleText = titleText else {
            return
        }

        titleLabel.text = titleText

        if let subtitleText = subtitleText {
            subtitleTextView.attributedText = nil
            subtitleTextView.text = subtitleText
            subtitleTextView.isSelectable = false
        }

        if let attributedSubtitleText = attributedSubtitleText {
            subtitleTextView.attributedText = applyMessageStyleTo(attributedString: attributedSubtitleText)
            subtitleTextView.isSelectable = true
        }

        let showSubtitle = subtitleText != nil || attributedSubtitleText != nil
        subtitleTextView.isHidden = !showSubtitle

        if let buttonText = buttonText {
            actionButton?.setTitle(buttonText, for: UIControlState())
            actionButton?.setTitle(buttonText, for: .highlighted)
            actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
            actionButton?.accessibilityIdentifier = accessibilityIdentifier(for: buttonText)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }

        if let accessorySubview = accessorySubview {
            accessoryView.addSubview(accessorySubview)
        }

        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        }

        view.layoutIfNeeded()
    }

    func setAccessoryViewsVisibility() {
        let hideAll = UIDeviceOrientationIsLandscape(UIDevice.current.orientation) && WPDeviceIdentification.isiPhone()

        if hideAll == true {
            // Hide the accessory and image views in iPhone landscape to ensure entire view fits on screen
            imageView.isHidden = true
            accessoryView.isHidden = true
        } else {
            // If there is an accessory view, show that.
            // Otherwise, show the image view.
            accessoryView.isHidden = accessorySubview == nil
            imageView.isHidden = !accessoryView.isHidden
        }
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: Any) {
        delegate?.actionButtonPressed?()
    }

    @objc func dismissButtonPressed() {
        delegate?.dismissButtonPressed?()
    }

    // MARK: - Helpers

    func accessibilityIdentifier(for string: String) -> String {
        let buttonIdFormat = NSLocalizedString("%@ Button", comment: "Accessibility identifier for buttons.")
        return String(format: buttonIdFormat, string)
    }

    func applyMessageStyleTo(attributedString: NSAttributedString) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = subtitleTextView.textAlignment

        let attributes: [NSAttributedStringKey: Any] = [
            .font: subtitleTextView.font!,
            .foregroundColor: subtitleTextView.textColor!,
            .paragraphStyle: paragraphStyle
        ]

        let fullTextRange = attributedString.string.foundationRangeOfEntireString
        let finalAttributedString = NSMutableAttributedString(attributedString: attributedString)
        finalAttributedString.addAttributes(attributes, range: fullTextRange)

        return finalAttributedString
    }
}
