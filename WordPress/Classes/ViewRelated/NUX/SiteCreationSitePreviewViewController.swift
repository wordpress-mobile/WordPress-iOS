import UIKit
import WebKit

class SiteCreationSitePreviewViewController: UIViewController {

    // MARK: - Properties

    var siteUrl: String?

    @IBOutlet weak var siteView: UIView!
    @IBOutlet weak var congratulationsView: UIView!
    @IBOutlet weak var congratulationsLabel: UILabel!
    @IBOutlet weak var siteReadyLabel: UILabel!

    /// Due to build error when adding WKWebView in a storyboard, must create it
    /// programatically for < iOS 11.
    /// https://stackoverflow.com/a/46649435/3354034
    private var webView: WKWebView?

    private var timeExpired: Bool = false
    private var siteLoaded: Bool = false

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        congratulationsView.backgroundColor = WPStyleGuide.wordPressBlue()
        createWebView()
        loadSite()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Show Congratulations view for 4 seconds.
        Timer.scheduledTimer(timeInterval: 4,
                             target: self,
                             selector: #selector(setTimeExpired),
                             userInfo: nil,
                             repeats: false)
    }

    @objc private func setTimeExpired() {
        timeExpired = true
        showSite()
    }

    private func setLabelText() {
        congratulationsLabel.text = NSLocalizedString("Congratulations!", comment: "")
        siteReadyLabel.text = NSLocalizedString("Your site is ready.", comment: "")
    }

    // MARK: - Web View

    private func createWebView() {
        webView = WKWebView(frame: view.frame)
        webView?.navigationDelegate = self
    }

    private func loadSite() {
        if let webView = webView,
            let siteUrl = siteUrl,
            let url = URL(string: siteUrl) {
            webView.load(URLRequest(url: url))
        }
    }

    private func showSite() {
        if siteLoaded == true && timeExpired == true {
            siteView.addSubview(self.webView!)
            siteView.isHidden = false
        }
    }
}

// MARK: - WKNavigationDelegate
extension SiteCreationSitePreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        siteLoaded = true
        showSite()
    }

}
