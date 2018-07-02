import UIKit
import WebKit

class SiteCreationSitePreviewViewController: UIViewController {

    // MARK: - Properties

    var siteUrl: String?

    @IBOutlet weak var siteView: UIView!
    @IBOutlet weak var congratulationsView: UIView!
    @IBOutlet weak var congratulationsLabel: UILabel!
    @IBOutlet weak var siteReadyLabel: UILabel!

    /// Due to build error when adding WKWebView in a storyboard, must create WKWebView
    /// programatically for < iOS 11.
    /// https://stackoverflow.com/a/46649435/3354034
    private var webView: WKWebView?

    /// Indicates if the allotted time showing the Congratulations view has expired.
    private var timeExpired: Bool = false
    /// Indicates if the new site has finished loading.
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
        congratulationsLabel.text = NSLocalizedString("Congratulations!", comment: "Message shown on the final page of the site creation process.")
        siteReadyLabel.text = NSLocalizedString("Your site is ready.", comment: "Message shown on the final page of the site creation process.")
    }

    // MARK: - Web View

    private func createWebView() {
        webView = WKWebView(frame: view.frame)
        webView?.navigationDelegate = self
        siteView.addSubview(self.webView!)
    }

    private func loadSite() {
        if let webView = webView,
            let siteUrl = siteUrl,
            let url = URL(string: siteUrl)?.appendingHideMasterbarParameters() {
                webView.load(URLRequest(url: url))
        }
    }

    /// If the site has finished loading and the Congratulations view has shown long enough,
    /// show the site and fade out the Congratulations view.
    private func showSite() {
        if siteLoaded && timeExpired {
            self.siteView.alpha = 1
            UIView.animate(withDuration: WPAnimationDurationDefault, animations: {
                self.congratulationsView.alpha = 0
            }, completion: nil)
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
