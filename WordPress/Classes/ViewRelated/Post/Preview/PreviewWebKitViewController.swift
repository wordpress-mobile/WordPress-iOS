import Gridicons
import WebKit

/// An augmentation of WebKitViewController to provide Previewing for different devices
class PreviewWebKitViewController: WebKitViewController {

    private let canPublish: Bool

    let post: AbstractPost

    private weak var noResultsViewController: NoResultsViewController?

    private var selectedDevice: PreviewDeviceSelectionViewController.PreviewDevice = .default

    lazy var publishButton: UIBarButtonItem = {
        let publishButton = UIBarButtonItem(title: NSLocalizedString("Publish", comment: "Label for the publish (verb) button. Tapping publishes a draft post."),
                                            style: .plain,
                                            target: self,
                                            action: #selector(PreviewWebKitViewController.publishButtonPressed(_:)))
        publishButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.muriel(color: MurielColor(name: .pink))], for: .normal)
        return publishButton
    }()

    lazy var previewButton: UIBarButtonItem = {
        return UIBarButtonItem(image: Gridicon.iconOfType(.computer), style: .plain, target: self, action: #selector(PreviewWebKitViewController.previewButtonPressed(_:)))
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
            super.init(configuration: WebViewControllerConfiguration(url: URL(string: "about:blank")!))
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

    override func viewDidLoad() {
        super.viewDidLoad()
        if webView.url?.absoluteString == "about:blank" {
            showNoResults(withTitle: NSLocalizedString("No Preview URL available", comment: "missing preview URL for blog post preview") )
        }
    }

    override func configureToolbarButtons() {
        super.configureToolbarButtons()

        let items = toolbarItems(linkBehavior: linkBehavior)

        setToolbarItems(items, animated: false)
    }

    func toolbarItems(linkBehavior: LinkBehavior) -> [UIBarButtonItem] {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let items: [UIBarButtonItem]

        switch linkBehavior {
        case .all, .hostOnly:
            items = [
                backButton,
                space,
                forwardButton,
                space,
                shareButton,
                space,
                safariButton
            ]
        case .urlOnly:
            if canPublish {
                items = [publishButton, space, previewButton]
            } else {
                items = [shareButton, space, safariButton, space, previewButton]
            }
        }

        return items
    }

    @objc private func publishButtonPressed(_ sender: UIBarButtonItem) {
        PostCoordinator.shared.publish(post)
        dismiss(animated: true, completion: nil)
    }

    @objc private func previewButtonPressed(_ sender: UIBarButtonItem) {
        let popoverContentController = PreviewDeviceSelectionViewController()
        popoverContentController.selectedOption = selectedDevice
        popoverContentController.dismissHandler = { [weak self] option in
            self?.selectedDevice = option
            self?.webView.reload()
        }

        popoverContentController.modalPresentationStyle = .popover
        popoverContentController.popoverPresentationController!.delegate = self
        self.present(popoverContentController, animated: true, completion: nil)
    }

    private func showNoResults(withTitle title: String) {
        let controller = NoResultsViewController.controllerWith(title: title)
        controller.delegate = self
        noResultsViewController = controller
        addChild(controller)
        view.addSubview(controller.view)
        view.pinSubviewToAllEdges(controller.view)
        noResultsViewController?.didMove(toParent: self)
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

        popoverPresentationController.sourceRect = CGRect(x: navigationController.toolbar.frame.maxX - 36, y: navigationController.toolbar.frame.minY - 2, width: 0, height: 0)
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
            popoverPresentationController.presentedViewController is PreviewDeviceSelectionViewController else { return }

        popoverPresentationController.sourceRect = CGRect(x: navigationController.toolbar.frame.maxX - 36, y: navigationController.toolbar.frame.minY - 2, width: 0, height: 0)
        popoverPresentationController.sourceView = navigationController.toolbar.superview
    }
}

// MARK: WKNavigationDelegate

extension PreviewWebKitViewController {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if selectedDevice == .desktop {
            // Change the viewport scale to match a desktop environment
            webView.evaluateJavaScript("let originalVp = document.querySelector('meta[name=viewport]').cloneNode(true); originalVp.setAttribute('name', 'original_viewport' ); document.querySelector('head').appendChild(originalVp); parent = document.querySelector('meta[name=viewport]'); parent.setAttribute('content','initial-scale=0');", completionHandler: nil)
        }
    }
}

// MARK: NoResultsViewController Delegate

extension PreviewWebKitViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        noResultsViewController?.removeFromView()
        webView.reload()
    }

    func dismissButtonPressed() {
    }
}
