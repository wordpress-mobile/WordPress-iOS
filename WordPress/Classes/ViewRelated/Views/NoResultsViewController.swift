import UIKit
import WordPressShared
import Reachability

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
/// If this view is presented as a result of connectivity issue we will override the title, subtitle, image and accessorySubview (if it was set) to default values defined in the NoConnection struct
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
    @IBOutlet weak var accessoryStackView: UIStackView!

    private(set) var isReachable = false

    // To allow storing values until view is loaded.
    private var titleText: String?
    private var subtitleText: String?
    private var attributedSubtitleText: NSAttributedString?
    private var buttonText: String?
    private var imageName: String?
    private var subtitleImageName: String?
    private var accessorySubview: UIView?
    private var hideImage = false

    /// Allows caller to customize subtitle attributed text after default styling.
    typealias AttributedSubtitleConfiguration = (_ attributedText: NSAttributedString) -> NSAttributedString?
    /// Called after default styling of attributed subtitle, if non nil.
    private var configureAttributedSubtitle: AttributedSubtitleConfiguration? = nil

    private var displayTitleViewOnly = false
    private var titleOnlyLabel: UILabel?
    // To adjust title view on rotation.
    private var titleLabelLeadingConstraint: NSLayoutConstraint?
    private var titleLabelTrailingConstraint: NSLayoutConstraint?
    private var titleLabelCenterXConstraint: NSLayoutConstraint?
    private var titleLabelMaxWidthConstraint: NSLayoutConstraint?
    private var titleLabelTopConstraint: NSLayoutConstraint?

    //For No results on connection issue
    private let reachability = Reachability.forInternetConnection()

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(view: view, tableView: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reachability?.startNotifier()
        configureView()
        startAnimatingIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachability?.stopNotifier()
        stopAnimatingIfNeeded()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        configureView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setAccessoryViewsVisibility()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        DispatchQueue.main.async {
            self.configureTitleViewConstraints()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTitleOnlyLabelHeight()
    }

    /// Public method to get controller instance and set view values.
    ///
    /// - Parameters:
    ///   - title:              Main descriptive text. Required.
    ///   - buttonTitle:        Title of action button. Optional.
    ///   - subtitle:           Secondary descriptive text. Optional.
    ///   - attributedSubtitle: Secondary descriptive attributed text. Optional.
    ///   - attributedSubtitleConfiguration: Called after default styling, for subtitle attributed text customization.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc class func controllerWith(title: String,
                                    buttonTitle: String? = nil,
                                    subtitle: String? = nil,
                                    attributedSubtitle: NSAttributedString? = nil,
                                    attributedSubtitleConfiguration: AttributedSubtitleConfiguration? = nil,
                                    image: String? = nil,
                                    subtitleImage: String? = nil,
                                    accessoryView: UIView? = nil) -> NoResultsViewController {
        let controller = NoResultsViewController.controller()
        controller.configure(title: title, buttonTitle: buttonTitle, subtitle: subtitle, attributedSubtitle: attributedSubtitle, attributedSubtitleConfiguration: attributedSubtitleConfiguration, image: image, subtitleImage: subtitleImage, accessoryView: accessoryView)
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
    ///   - attributedSubtitleConfiguration: Called after default styling, for subtitle attributed text customization.
    ///   - image:              Name of image file to use. Optional.
    ///   - subtitleImage:      Name of image file to use in place of subtitle. Optional.
    ///   - accessoryView:      View to show instead of the image. Optional.
    ///
    @objc func configure(title: String,
                         noConnectionTitle: String? = nil,
                         buttonTitle: String? = nil,
                         subtitle: String? = nil,
                         noConnectionSubtitle: String? = nil,
                         attributedSubtitle: NSAttributedString? = nil,
                         attributedSubtitleConfiguration: AttributedSubtitleConfiguration? = nil,
                         image: String? = nil,
                         subtitleImage: String? = nil,
                         accessoryView: UIView? = nil) {
        isReachable = reachability?.isReachable() ?? false
        if !isReachable {
            titleText = noConnectionTitle != nil ? noConnectionTitle : NoConnection.title
            let subtitle = noConnectionSubtitle != nil ? noConnectionSubtitle : NoConnection.subTitle
            subtitleText = subtitle
            attributedSubtitleText = NSAttributedString(string: subtitleText!)
        } else {
            titleText = title
            subtitleText = subtitle
            attributedSubtitleText = attributedSubtitle
        }

        configureAttributedSubtitle = attributedSubtitleConfiguration
        buttonText = buttonTitle
        imageName = !isReachable ? NoConnection.imageName : image
        subtitleImageName = subtitleImage
        accessorySubview = !isReachable ? nil : accessoryView
        displayTitleViewOnly = false
    }

    /// Public method to show the title specifically formatted for no search results.
    /// When the view is configured, it will display just a label with specific constraints.
    ///
    /// - Parameters:
    ///   - title:  Main descriptive text. Required.
    func configureForNoSearchResults(title: String) {
        configure(title: title)
        displayTitleViewOnly = true
    }

    /// Public method to remove No Results View from parent view.
    ///
    @objc func removeFromView() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
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

        let attributes: [NSAttributedString.Key: Any] = [
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

    /// Public method to expose the private configure view method
    ///
    func updateView() {
        stopAnimatingIfNeeded()
        configureView()
        startAnimatingIfNeeded()
    }

    /// Public method to reset the button text
    ///
    func resetButtonText() {
        buttonText = nil
    }

    /// Public method to expose the private set accessory views method
    ///
    func updateAccessoryViewsVisibility() {
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
        titleLabel.textColor = .text

        subtitleTextView.textColor = .textSubtle

        if let subtitleText = subtitleText {
            subtitleTextView.attributedText = nil
            subtitleTextView.text = subtitleText
            subtitleTextView.isSelectable = false
        }

        if let attributedSubtitleText = attributedSubtitleText {
            subtitleTextView.attributedText = applyMessageStyleTo(attributedString: attributedSubtitleText)
            if let attributedSubtitle = configureAttributedSubtitle?(subtitleTextView.attributedText) {
                subtitleTextView.attributedText = attributedSubtitle
            }
            subtitleTextView.isSelectable = true
        }

        let hasSubtitleText = subtitleText != nil || attributedSubtitleText != nil
        let hasSubtitleImage = subtitleImageName != nil
        let showSubtitle = hasSubtitleText && !hasSubtitleImage
        subtitleTextView.isHidden = !showSubtitle
        subtitleImageView.isHidden = !hasSubtitleImage
        subtitleImageView.tintColor = titleLabel.textColor
        configureSubtitleView()

        if let buttonText = buttonText {
            actionButton?.setTitle(buttonText, for: UIControl.State())
            actionButton?.setTitle(buttonText, for: .highlighted)
            actionButton?.titleLabel?.adjustsFontForContentSizeCategory = true
            actionButton?.accessibilityIdentifier = accessibilityIdentifier(for: buttonText)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }

        if let accessorySubview = accessorySubview {
            accessoryView.subviews.forEach { view in
                stopAnimatingViewIfNeeded(view)
                view.removeFromSuperview()
            }
            accessoryView.addSubview(accessorySubview)
        }

        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        }

        if let subtitleImageName = subtitleImageName {
            subtitleImageView.image = UIImage(named: subtitleImageName)
        }

        setAccessoryViewsVisibility()
        configureForTitleViewOnly()

        view.layoutIfNeeded()
    }

    func configureSubtitleView() {
        // remove the extra space iOS puts on a UITextView
        subtitleTextView.textContainerInset = UIEdgeInsets.zero
        subtitleTextView.textContainer.lineFragmentPadding = 0
    }

    func setAccessoryViewsVisibility() {

        if hideImage {
            accessoryStackView.isHidden = true
            return
        }

        // Always hide the accessory/image stack view when in iPhone landscape.
        accessoryStackView.isHidden = UIDevice.current.orientation.isLandscape && WPDeviceIdentification.isiPhone()

        // If there is an accessory view, show that.
        accessoryView.isHidden = accessorySubview == nil
        // Otherwise, show the image view, unless it's set never to show.
        imageView.isHidden = (hideImage == true) ? true : !accessoryView.isHidden
    }

    func viewIsVisible() -> Bool {
        return isViewLoaded && view.window != nil
    }

    // MARK: - Configure for Title View Only

    func configureForTitleViewOnly() {

        titleOnlyLabel?.removeFromSuperview()

        guard displayTitleViewOnly == true else {
            noResultsView.isHidden = false
            return
        }

        titleOnlyLabel = copyTitleLabel()

        guard let titleOnlyLabel = titleOnlyLabel else {
            return
        }

        noResultsView.isHidden = true
        titleOnlyLabel.frame = view.frame
        view.addSubview(titleOnlyLabel)
        configureTitleViewConstraints()
    }

    func copyTitleLabel() -> UILabel? {
        // Copy the `titleLabel` to get the style for Title View Only label
        let data = NSKeyedArchiver.archivedData(withRootObject: titleLabel)
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UILabel ?? nil
    }

    func configureTitleViewConstraints() {

        guard self.viewIsVisible(),
            displayTitleViewOnly == true else {
            return
        }

        resetTitleViewConstraints()
        titleOnlyLabel?.translatesAutoresizingMaskIntoConstraints = false


        let availableWidth = view.frame.width - TitleLabelConstraints.leading + TitleLabelConstraints.trailing

        if availableWidth < TitleLabelConstraints.maxWidth {
            guard let titleLabelLeadingConstraint = titleLabelLeadingConstraint,
                let titleLabelTrailingConstraint = titleLabelTrailingConstraint,
                let titleLabelTopConstraint = titleLabelTopConstraint else {
                    return
            }

            NSLayoutConstraint.activate([titleLabelTopConstraint, titleLabelLeadingConstraint, titleLabelTrailingConstraint])
        } else {
            guard let titleLabelMaxWidthConstraint = titleLabelMaxWidthConstraint,
                let titleLabelCenterXConstraint = titleLabelCenterXConstraint,
                let titleLabelTopConstraint = titleLabelTopConstraint else {
                    return
            }

            NSLayoutConstraint.activate([titleLabelTopConstraint, titleLabelMaxWidthConstraint, titleLabelCenterXConstraint])
        }
    }

    func resetTitleViewConstraints() {
        titleLabelTrailingConstraint?.isActive = false
        titleLabelLeadingConstraint?.isActive = false
        titleLabelMaxWidthConstraint?.isActive = false
        titleLabelCenterXConstraint?.isActive = false

        guard let titleOnlyLabel = titleOnlyLabel else {
            return
        }

        titleLabelTopConstraint = titleOnlyLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: TitleLabelConstraints.top)
        titleLabelLeadingConstraint = titleOnlyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: TitleLabelConstraints.leading)
        titleLabelTrailingConstraint = titleOnlyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: TitleLabelConstraints.trailing)
        titleLabelCenterXConstraint = titleOnlyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        titleLabelMaxWidthConstraint = titleOnlyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: TitleLabelConstraints.maxWidth)
    }

    func adjustTitleOnlyLabelHeight() {

        guard let titleOnlyLabel = titleOnlyLabel else {
            return
        }

        var titleOnlyLabelFrame = titleOnlyLabel.frame
        titleOnlyLabel.sizeToFit()
        titleOnlyLabelFrame.size.height = titleOnlyLabel.frame.height
        titleOnlyLabel.frame = titleOnlyLabelFrame
    }

    struct TitleLabelConstraints {
        static let top = CGFloat(64)
        static let leading = CGFloat(38)
        static let trailing = CGFloat(-38)
        static let maxWidth = CGFloat(360)
    }

    // MARK: - Button Handling

    @IBAction func actionButtonPressed(_ sender: UIButton) {
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

    func startAnimatingIfNeeded() {
        guard let animatedBox = accessorySubview as? WPAnimatedBox else {
            return
        }
        animatedBox.animate(afterDelay: 0.1)
    }

    func stopAnimatingViewIfNeeded(_ view: UIView?) {
        guard let animatedBox = view as? WPAnimatedBox else {
            return
        }
        animatedBox.suspendAnimation()
    }

    func stopAnimatingIfNeeded() {
        stopAnimatingViewIfNeeded(accessorySubview)
    }

    struct NoConnection {
        static let title: String = NSLocalizedString("Unable to load this page right now.", comment: "Title for No results full page screen displayed when there is no connection")
        static let subTitle: String = NSLocalizedString("Check your network connection and try again.", comment: "Subtitle for No results full page screen displayed when there is no connection")
        static let imageName = "cloud"
    }
}
