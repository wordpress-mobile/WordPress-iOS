import UIKit
import WordPressUI

class SiteDesignPreviewViewController: UIViewController, NoResultsViewHost {
    let completion: SiteDesignStep.SiteDesignSelection
    let siteDesign: RemoteSiteDesign
    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    private var estimatedProgressObserver: NSKeyValueObservation?

    lazy var ghostView: GutenGhostView = {
        let ghost = GutenGhostView()
        ghost.hidesToolbar = true
        ghost.translatesAutoresizingMaskIntoConstraints = false
        return ghost
    }()

    private var accentColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.muriel(color: .accent, .shade40)
                } else {
                    return UIColor.muriel(color: .accent, .shade50)
                }
            }
        } else {
            return UIColor.muriel(color: .accent, .shade50)
        }
    }

    init(siteDesign: RemoteSiteDesign, completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        self.siteDesign = siteDesign
        super.init(nibName: "\(SiteDesignPreviewViewController.self)", bundle: .main)
        self.title = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        styleButtons()
        webView.scrollView.contentInset.bottom = footerView.frame.height
        webView.navigationDelegate = self
        webView.backgroundColor = .basicBackground
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewViewed(siteDesign)
        observeProgressEstimations()
        navigationItem.rightBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
    }

    deinit {
        removeProgressObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func actionButtonSelected(_ sender: Any) {
        SiteCreationAnalyticsHelper.trackSiteDesignSelected(siteDesign)
        dismiss(animated: true)
        completion(siteDesign)
    }

    private func configureWebView() {
        guard let demoURL = URL(string: siteDesign.demoURL) else { return }
        let request = URLRequest(url: demoURL)
        webView.customUserAgent = WPUserAgent.wordPress()
        webView.load(request)
    }

    private func styleButtons() {
        primaryActionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        primaryActionButton.backgroundColor = accentColor
        primaryActionButton.layer.cornerRadius = 8
    }

    private func handleError(_ error: Error) {
        SiteCreationAnalyticsHelper.trackError(error)
        configureAndDisplayNoResults(on: webView,
                                     title: NSLocalizedString("Unable to load this content right now.", comment: "Informing the user that a network request failed becuase the device wasn't able to establish a network connection."))
        progressBar.animatableSetIsHidden(true)
        removeProgressObserver()
    }

    private func observeProgressEstimations() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] (webView, _) in
            self?.progressBar.progress = Float(webView.estimatedProgress)
        }
    }

    private func removeProgressObserver() {
        estimatedProgressObserver?.invalidate()
        estimatedProgressObserver = nil
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true)
    }
}

extension SiteDesignPreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoading(siteDesign)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SiteCreationAnalyticsHelper.trackSiteDesignPreviewLoaded(siteDesign)
        progressBar.animatableSetIsHidden(true)
        removeProgressObserver()
    }
}
