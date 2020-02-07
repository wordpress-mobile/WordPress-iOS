import Gridicons
import WebKit

/// An augmentation of WebKitViewController to provide Previewing for different devices
class PreviewWebKitViewController: WebKitViewController {

    let post: AbstractPost

    private let canPublish: Bool

    private weak var noResultsViewController: NoResultsViewController?

    private var selectedDevice: PreviewDeviceSelectionViewController.PreviewDevice = .default {
        didSet {
            if selectedDevice != oldValue {
                webView.reload()
            }
            showLabel(device: selectedDevice)
        }
    }

    lazy var publishButton: UIBarButtonItem = {
        let publishButton = UIBarButtonItem(title: Constants.publishButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(PreviewWebKitViewController.publishButtonPressed(_:)))
        publishButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2), NSAttributedString.Key.foregroundColor: Constants.publishButtonColor], for: .normal)
        return publishButton
    }()

    lazy var previewButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "icon-devices"), style: .plain, target: self, action: #selector(PreviewWebKitViewController.previewButtonPressed(_:)))
        button.title = NSLocalizedString("Preview Device", comment: "Title for web preview device switching button")
        button.accessibilityHint = NSLocalizedString("Change the device type used for preview", comment: "Accessibility hint for web preview device switching button")
        return button
    }()

    lazy var deviceLabel: PreviewDeviceLabel = {
        let label = PreviewDeviceLabel()
        label.insets = Constants.deviceLabelInset
        label.backgroundColor = Constants.deviceLabelBackgroundColor
        label.textColor = .textInverted
        return label
    }()

    /// Creates a view controller displaying a preview web view.
    /// - Parameters:
    ///   - post: The post to use for generating the preview URL and authenticating to the blog. **NOTE**: `previewURL` will be used as the URL instead, when available.
    ///   - previewURL: The URL to display in the preview web view.
    init(post: AbstractPost, previewURL: URL? = nil) {

        self.post = post

        let autoUploadInteractor = PostAutoUploadInteractor()

        let isNotCancelableWithFailedToUploadChanges: Bool = post.isFailed && post.hasLocalChanges() && !autoUploadInteractor.canCancelAutoUpload(of: post)
        canPublish = post.isDraft() || isNotCancelableWithFailedToUploadChanges

        guard let url = PreviewNonceHandler.nonceURL(post: post, previewURL: previewURL) else {
            super.init(configuration: WebViewControllerConfiguration(url: Constants.blankURL))
            return
        }

        let isPage = post is Page

        let configuration = WebViewControllerConfiguration(url: url)
        configuration.linkBehavior = isPage ? .hostOnly(url) : .urlOnly(url)
        configuration.opensNewInSafari = true
        configuration.authenticate(blog: post.blog)
        super.init(configuration: configuration)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func trackOpenEvent() {
        let eventProperties: [String: Any] = [
            "post_type": post.analyticsPostType ?? "unsupported",
            "blog_type": post.blog.analyticsType.rawValue
        ]
        WPAppAnalytics.track(.openedWebPreview, withProperties: eventProperties)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if webView.url?.absoluteString == Constants.blankURL?.absoluteString {
            showNoResults(withTitle: Constants.noPreviewTitle)
        }
        setupDeviceLabel()
    }

    // MARK: Toolbar Items

    override func configureToolbarButtons() {
        super.configureToolbarButtons()

        let items = toolbarItems(linkBehavior: linkBehavior)

        setToolbarItems(items, animated: false)
    }

    func toolbarItems(linkBehavior: LinkBehavior) -> [UIBarButtonItem] {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let items: [UIBarButtonItem]

        switch linkBehavior {
        case .all:
            items = [
                backButton,
                space,
                forwardButton,
                space,
                shareButton,
                space,
                safariButton
            ]
        case .hostOnly:
            if canPublish {
                items = [
                    backButton,
                    space,
                    forwardButton,
                    space,
                    previewButton
                ]
            } else {
                items = [
                    backButton,
                    space,
                    forwardButton,
                    space,
                    shareButton,
                    space,
                    safariButton,
                    space,
                    previewButton
                ]
            }
        case .urlOnly:
            if canPublish {
                items = [publishButton, space, previewButton]
            } else {
                items = [shareButton, space, safariButton, space, previewButton]
            }
        }

        return items
    }

    // MARK: Button Actionss

    @objc private func publishButtonPressed(_ sender: UIBarButtonItem) {
        PostCoordinator.shared.publish(post)
        dismiss(animated: true, completion: nil)
    }

    @objc private func previewButtonPressed(_ sender: UIBarButtonItem) {
        let popoverContentController = PreviewDeviceSelectionViewController()
        popoverContentController.selectedOption = selectedDevice
        popoverContentController.dismissHandler = { [weak self] option in
            self?.selectedDevice = option
        }

        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.popoverPresentationController?.delegate = self
        self.present(popoverContentController, animated: true, completion: nil)
    }

    private func showNoResults(withTitle title: String) {
        let controller = NoResultsViewController.controllerWith(title: title)
        noResultsViewController = controller
        addChild(controller)
        view.addSubview(controller.view)
        view.pinSubviewToAllEdges(controller.view)
        noResultsViewController?.didMove(toParent: self)
    }

    // MARK: Selected Device Label

    private func setupDeviceLabel() {
        view.addSubview(deviceLabel)

        deviceLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        deviceLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        view.addConstraints([
            deviceLabel.rightAnchor.constraint(equalTo: view.safeRightAnchor, constant: Constants.deviceLabelPadding),
            deviceLabel.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: Constants.deviceLabelPadding)
        ])
        showLabel(device: selectedDevice)
    }

    private func showLabel(device: PreviewDeviceSelectionViewController.PreviewDevice) {
        deviceLabel.isHidden = device == .default
        deviceLabel.text = device.title
    }

    enum Constants {
        static let deviceLabelPadding: CGFloat = 4

        static let deviceLabelInset = UIEdgeInsets(top: 6, left: 6, bottom: 8, right: 8)

        static let deviceLabelBackgroundColor = UIColor.text.withAlphaComponent(0.8)

        static let devicePickerPopoverOffset: (CGFloat, CGFloat) = (x: -36, y: -2)

        static let noPreviewTitle = NSLocalizedString("No Preview URL available", comment: "missing preview URL for blog post preview")

        static let publishButtonTitle = NSLocalizedString("Publish", comment: "Label for the publish (verb) button. Tapping publishes a draft post.")

        static let publishButtonColor = UIColor.muriel(color: MurielColor.accent)

        static let blankURL = URL(string: "about:blank")
    }
}

// MARK: UIPopoverPresentationDelegate

extension PreviewWebKitViewController {

    override func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        guard let navigationController = navigationController, popoverPresentationController.presentedViewController is PreviewDeviceSelectionViewController else {
            super.prepareForPopoverPresentation(popoverPresentationController)
            return
        }

        popoverPresentationController.permittedArrowDirections = .down

        popoverPresentationController.sourceRect = sourceRect(for: navigationController.toolbar, offsetBy: Constants.devicePickerPopoverOffset)
        popoverPresentationController.sourceView = navigationController.toolbar.superview
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Reset our source rect and view for a transition to a new size
        guard let navigationController = navigationController,
            let popoverPresentationController = presentedViewController?.presentationController as? UIPopoverPresentationController,
            popoverPresentationController.presentedViewController is PreviewDeviceSelectionViewController else {
                return
        }

        popoverPresentationController.sourceRect = sourceRect(for: navigationController.toolbar, offsetBy: Constants.devicePickerPopoverOffset)
        popoverPresentationController.sourceView = navigationController.toolbar.superview
    }

    /// Returns a rect that represents the far right corner of `view` offset by `offsetBy`.
    /// - Parameter view: The view to use for finding the upper right corner.
    /// - Parameter offsetBy: An x, y pair to offset the view's coordinates by
    func sourceRect(for view: UIView, offsetBy offset: (x: CGFloat, y: CGFloat)) -> CGRect {
        return CGRect(origin: view.frame.topRightVertex, size: .zero).offsetBy(dx: offset.x, dy: offset.y)
    }
}

private extension CGRect {
    var topRightVertex: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
}

// MARK: WKNavigationDelegate

extension PreviewWebKitViewController {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if selectedDevice == .desktop {
            // Change the viewport scale to match a desktop environment
            webView.evaluateJavaScript("let parent = document.querySelector('meta[name=viewport]'); parent.setAttribute('content','initial-scale=0');", completionHandler: nil)
        }
    }
}
