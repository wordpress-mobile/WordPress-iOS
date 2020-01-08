//
//  PostPreviewViewController.swift
//  WordPress
//
//  Created by Brandon Titus on 1/7/20.
//  Copyright © 2020 WordPress. All rights reserved.
//

import Foundation
import WebKit
import Gridicons

//TODO: Check whether we need `ParentPageSettingsViewController`
class NewPostPreviewViewController: UIViewController {
    var webView: WKWebView!

    var onClose: (() -> Void)? = nil

    let post: AbstractPost

    private let generator: PostPreviewGenerator

    private var reachabilityObserver: Any? = nil

    init(post: AbstractPost, previewURL: URL? = nil) {
        self.post = post
        generator = PostPreviewGenerator(post: post, previewURL: previewURL)
        super.init(nibName: nil, bundle: nil)
        generator.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var statusButtonItem: UIBarButtonItem = {
        let statusView = LoadingStatusView(title: NSLocalizedString("Loading", comment: "Label for button to present loading preview status"))
        let buttonItem = UIBarButtonItem(customView: statusView)
        buttonItem.accessibilityIdentifier = "Preview Status"
        return buttonItem
    }()

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Label for button to dismiss post preview"), style: .done, target: self, action: #selector(dismissPreview))
        buttonItem.accessibilityIdentifier = "Done"
        return buttonItem
    }()

    private lazy var shareBarButtonItem: UIBarButtonItem = {
        let image = Gridicon.iconOfType(.shareIOS)
        let buttonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(sharePost))
        buttonItem.accessibilityLabel = NSLocalizedString("Share", comment: "Title of the share button in the Post Editor.")
        buttonItem.accessibilityIdentifier = "Share"
        return buttonItem
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupBarButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshWebView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopWaitingForConnectionRestored()
    }

    private func refreshWebView() {
        generator.generate()
    }

    private func setupBarButtons() {
        navigationItem.rightBarButtonItems = [doneBarButtonItem, shareBarButtonItem]
        navigationItem.leftItemsSupplementBackButton = true
    }

    private func setupWebView() {
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        view.addSubview(webView)
        view.pinSubviewToAllEdges(webView)
    }

    @objc private func dismissPreview() {
        onClose?()
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc private func sharePost() {
        if let post = post as? Post {
            let sharingController = PostSharingController()
            sharingController.sharePost(post, fromBarButtonItem: shareBarButtonItem, inViewController: self)
        }
    }


    // MARK: Reachability

    private func reloadWhenConnectionRestored() {
        reachabilityObserver = ReachabilityUtils.observeOnceInternetAvailable { [weak self] in
            self?.refreshWebView()
        }
    }

    private func stopWaitingForConnectionRestored() {
        if let observer = reachabilityObserver {
            NotificationCenter.default.removeObserver(observer)
            reachabilityObserver = nil
        }
    }

    // MARK: Loading Animations

    private func startLoadAnimation() {
        navigationItem.setLeftBarButton(statusButtonItem, animated: true)
        navigationItem.title = nil
    }

    private func stopLoadAnimation() {
        navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        navigationItem.title = NSLocalizedString("Preview", comment: "Post Editor / Preview screen title.")
    }
}

extension NewPostPreviewViewController: PostPreviewGeneratorDelegate {
    func preview(_ generator: PostPreviewGenerator, attemptRequest request: URLRequest) {
        startLoadAnimation()
        webView.load(request)
        //TODO: Remove No Results View
    }

    func preview(_ generator: PostPreviewGenerator, loadHTML html: String) {
        webView.loadHTMLString(html, baseURL: nil)
        //TODO: Remove No Results View
    }

    func previewFailed(_ generator: PostPreviewGenerator, message: String) {
        //TODO: Show No Results with message
        reloadWhenConnectionRestored()
    }


}

extension NewPostPreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopLoadAnimation()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {

        //TODO: Remove this and handle all
        let error = error as NSError

        // Watch for NSURLErrorCancelled (aka NSURLErrorDomain error -999). This error is returned
        // when an asynchronous load is canceled. For example, a link is tapped (or some other
        // action that causes a new page to load) before the current page has completed loading.
        // It should be safe to ignore.
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return
        }

        // In iOS 11, it seems UIWebView is based on WebKit, and it's returning a different error when
        // we redirect and cancel a request from shouldStartLoadWithRequest:
        //
        //   Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
        //
        // I haven't found a relevant WebKit constant for error 102
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        stopLoadAnimation()

        let reasonString = "Generic web view error Error. Error code: \(error.code), Error domain: \(error.domain)"

        generator.previewRequestFailed(reason: reasonString)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let redirectRequest = generator.interceptRedirect(request: navigationAction.request)

        if let request = redirectRequest {
            decisionHandler(.cancel)
            webView.load(request)
            return
        }

        if navigationAction.request.url?.query == "action=postpass" {
            // Password-protected post, user entered password
            decisionHandler(.allow)
            return
        }

        if navigationAction.request.url?.absoluteString == post.permaLink {
            // Always allow loading the preview
            decisionHandler(.allow)
            return
        }

        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
