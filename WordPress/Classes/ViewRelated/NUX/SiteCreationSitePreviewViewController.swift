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

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        congratulationsView.backgroundColor = WPStyleGuide.wordPressBlue()
        createWebView()
        loadSite()
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
}

// MARK: - WKNavigationDelegate
extension SiteCreationSitePreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        siteView.addSubview(self.webView!)
        siteView.isHidden = false
    }

}
