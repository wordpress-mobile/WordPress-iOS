import Gridicons
import WebKit
import WordPressShared

/// An augmentation of WebKitViewController to provide Previewing for different devices
class PreviewWebKitViewController: WebKitViewController {

    let post: AbstractPost?

    private let canPublish: Bool

    private weak var noResultsViewController: NoResultsViewController?

    private var selectedDevice: PreviewDeviceSelectionViewController.PreviewDevice = .default {
        didSet {
            if selectedDevice != oldValue {
                UIView.animate(withDuration: 0.2, animations: {
                    self.webView.alpha = 0
                }, completion: { _ in
                    self.webView.reload()
                })
            }
            showLabel(device: selectedDevice)
        }
    }

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
    init(post: AbstractPost, previewURL: URL? = nil, source: String) {

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

        /// When the counterpart app is installed, revert to the default link behavior from `WebKitViewController`
        /// to prevent links from being opened through the `externalLinkHandler`.
        ///
        /// This can be removed once the universal link routes for the WP app is removed.
        if !MigrationAppDetection.isCounterpartAppInstalled {
            configuration.linkBehavior = isPage ? .hostOnly(url) : .urlOnly(url)
        }

        configuration.opensNewInSafari = true
        configuration.authenticate(blog: post.blog)
        configuration.analyticsSource = source
        super.init(configuration: configuration)
    }

    @objc override init(configuration: WebViewControllerConfiguration) {
        post = nil
        canPublish = false
        super.init(configuration: configuration)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func trackOpenEvent() {
        guard let post = post else { return }

        let eventProperties: [String: Any] = [
            "post_type": post.analyticsPostType ?? "unsupported",
            "blog_type": post.blog.analyticsType.rawValue
        ]
        WPAppAnalytics.track(.openedWebPreview, withProperties: eventProperties)
    }

    override func viewDidLoad() {
        webView.alpha = 0

        super.viewDidLoad()
        if webView.url?.absoluteString == Constants.blankURL?.absoluteString {
            showNoResults(withTitle: Constants.noPreviewTitle)
        }
        setupDeviceLabel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setWidth(selectedDevice.width, viewWidth: size.width)
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
                safariButton,
                space,
                previewButton
            ]
        case .withBaseURLOnly:
            fallthrough
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
                items = [space, previewButton]
            } else {
                items = [shareButton, space, safariButton, space, previewButton]
            }
        }

        return items
    }

    // MARK: Button Actions

    @objc private func previewButtonPressed(_ sender: UIBarButtonItem) {
        let popoverContentController = PreviewDeviceSelectionViewController()
        popoverContentController.selectedOption = selectedDevice
        popoverContentController.onDeviceChange = { [weak self] option in
            self?.selectedDevice = option

            let properties: [AnyHashable: Any] = [
                "source": self?.analyticsSource ?? "unknown",
                "option": option.rawValue
            ]
            WPAnalytics.track(.previewWebKitViewDeviceChanged, properties: properties)
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

        static let noPreviewTitle = NSLocalizedString("No Preview URL available", comment: "missing preview URL for blog post preview")

        static let blankURL = URL(string: "about:blank")
    }
}

// MARK: UIPopoverPresentationDelegate

extension PreviewWebKitViewController {

    override func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        guard popoverPresentationController.presentedViewController is PreviewDeviceSelectionViewController else {
            super.prepareForPopoverPresentation(popoverPresentationController)
            return
        }

        popoverPresentationController.permittedArrowDirections = .down
        popoverPresentationController.barButtonItem = previewButton
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let popoverPresentationController = presentedViewController?.presentationController as? UIPopoverPresentationController else {
                return
        }

        prepareForPopoverPresentation(popoverPresentationController)
    }
}

// MARK: WKNavigationDelegate

extension PreviewWebKitViewController {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        setWidth(selectedDevice.width)
        webView.evaluateJavaScript(selectedDevice.viewportScript, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.2) {
            self.webView.alpha = 1
        }
    }
}
