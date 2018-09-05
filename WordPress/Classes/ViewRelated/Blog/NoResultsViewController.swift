import UIKit

@objc protocol NoResultsViewControllerDelegate {
    @objc optional func actionButtonPressed()
    @objc optional func dismissButtonPressed()
}

/// A view to show when there are no results for a given situation.
/// Ex: My Sites > account has no sites; My Sites > all sites are hidden.
/// The title will always show.
/// The image will always show unless:
///     - an accessoryView is provided.
///     - hideImage is set to true.
/// The action button is shown by default, but will be hidden if button title is not provided.
/// The subtitle is optional and will only show if provided.
///
@objc class NoResultsViewController: UIViewController {

    // MARK: - Properties

    @objc weak var delegate: NoResultsViewControllerDelegate?
    @IBOutlet weak var noResultsView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleTextView: UITextView!
    @IBOutlet weak var subtitleImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var accessoryView: UIView!

    // To allow storing values until view is loaded.
    private var titleText: String?
    private var subtitleText: String?
    private var attributedSubtitleText: NSAttributedString?
    private var buttonText: String?
    private var imageName: String?
    private var subtitleImageName: String?
    private var accessorySubview: UIView?
    private var hideImage = false

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureView()
        startAnimatingIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAnimatingIfNeeded()
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        configureView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setAccessoryViewsVisibility()
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

    /// Public method to get controller instance and set view values.
    ///
    /// - Parameters:
    ///   - title:              Main descriptive text. Required.
    ///   - buttonTitle:        Title of action button. Optional.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc class func controllerWith(title: String,
                                    buttonTitle: String? = nil,
                                    image: String? = nil,
                                    subtitleImage: String? = nil,
                                    accessoryView: UIView? = nil) -> NoResultsViewController {
        let controller = NoResultsViewController.controller()
        controller.titleText = title
        controller.buttonText = buttonTitle
        controller.imageName = image
        controller.subtitleImageName = subtitleImage
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

    /// Public method to provide values for text elements.
    ///
    /// - Parameters:
    ///   - title:              Main descriptive text. Required.
    ///   - buttonTitle:        Title of action button. Optional.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc func configure(title: String,
                         buttonTitle: String? = nil,
                         image: String? = nil,
                         subtitleImage: String? = nil,
                         accessoryView: UIView? = nil) {
        titleText = title
        buttonText = buttonTitle
        imageName = image
        subtitleImageName = subtitleImage
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

    /// Public method to get an attributed string styled for No Results.
    ///
    /// - Parameters:
    ///   - attributedString: The attributed string to be styled.
    ///
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

    /// Public class method to get an animated box to show while loading.
    /// NB : the current implementation vends a WPAnimatedBox instance, which should be stopped via suspendAnimation.
    ///
    @objc class func loadingAccessoryView() -> UIView {
        let boxView = WPAnimatedBox()
        return boxView
    }

    /// Public method to hide/show the image view.
    ///
    @objc func hideImageView(_ hide: Bool = true) {
        hideImage = hide
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

        let hasSubtitleText = subtitleText != nil || attributedSubtitleText != nil
        let hasSubtitleImage = subtitleImageName != nil
        let showSubtitle = hasSubtitleText && !hasSubtitleImage
        subtitleTextView.isHidden = !showSubtitle
        subtitleImageView.isHidden = !hasSubtitleImage
        subtitleImageView.tintColor = titleLabel.textColor

        if let buttonText = buttonText {
            configureButton()
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

        if let subtitleImageName = subtitleImageName {
            subtitleImageView.image = UIImage(named: subtitleImageName)
        }

        view.layoutIfNeeded()
    }

    func configureButton() {
        actionButton.contentEdgeInsets = DefaultRenderMetrics.contentInsets

        let normalImage = renderBackgroundImage(fill: WPStyleGuide.mediumBlue(), border: WPStyleGuide.wordPressBlue())
        let highlightedImage = renderBackgroundImage(fill: WPStyleGuide.wordPressBlue(), border: WPStyleGuide.wordPressBlue())

        actionButton.setBackgroundImage(normalImage, for: .normal)
        actionButton.setBackgroundImage(highlightedImage, for: .highlighted)
    }

    func renderBackgroundImage(fill: UIColor, border: UIColor) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: DefaultRenderMetrics.backgroundImageSize)
        let image = renderer.image { context in

            let lineWidthInPixels = 1 / UIScreen.main.scale
            let cgContext = context.cgContext

            // Apply a 1px inset to the bounds, for our bezier (so that the border doesn't fall outside)
            var bounds = renderer.format.bounds
            bounds.origin.x += lineWidthInPixels
            bounds.origin.y += lineWidthInPixels
            bounds.size.height -= lineWidthInPixels * 2 + DefaultRenderMetrics.backgroundShadowOffset.height
            bounds.size.width -= lineWidthInPixels * 2 + DefaultRenderMetrics.backgroundShadowOffset.width

            let path = UIBezierPath(roundedRect: bounds, cornerRadius: DefaultRenderMetrics.backgroundCornerRadius)

            // Draw: Background + Shadow
            cgContext.saveGState()
            cgContext.setShadow(offset: DefaultRenderMetrics.backgroundShadowOffset,
                                blur: DefaultRenderMetrics.backgroundShadowBlurRadius,
                                color: border.cgColor)
            fill.setFill()

            path.fill()

            cgContext.restoreGState()

            // Draw: Border
            border.setStroke()
            path.stroke()
        }

        return image.resizableImage(withCapInsets: DefaultRenderMetrics.backgroundCapInsets)
    }

    struct DefaultRenderMetrics {
        public static let backgroundImageSize = CGSize(width: 44, height: 44)
        public static let backgroundCornerRadius = CGFloat(8)
        public static let backgroundCapInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        public static let backgroundShadowOffset = CGSize(width: 0, height: 2)
        public static let backgroundShadowBlurRadius = CGFloat(0)
        public static let contentInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    }

    func setAccessoryViewsVisibility() {
        let hideAll = UIDeviceOrientationIsLandscape(UIDevice.current.orientation) && WPDeviceIdentification.isiPhone()

        if hideAll == true {
            // Hide the accessory and image views in iPhone landscape to ensure entire view fits on screen
            imageView.isHidden = true
            accessoryView.isHidden = true
        } else {
            // If there is an accessory view, show that.
            accessoryView.isHidden = accessorySubview == nil
            // Otherwise, show the image view, unless it's set never to show.
            imageView.isHidden = (hideImage == true) ? true : !accessoryView.isHidden
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

    // MARK: - `WPAnimatedBox` resource management

    private func startAnimatingIfNeeded() {
        guard let animatedBox = accessorySubview as? WPAnimatedBox else {
            return
        }
        animatedBox.animate(afterDelay: 0.1)
    }

    private func stopAnimatingIfNeeded() {
        guard let animatedBox = accessorySubview as? WPAnimatedBox else {
            return
        }
        animatedBox.suspendAnimation()
    }
}
