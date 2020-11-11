import UIKit
import WordPressUI

class SiteDesignPreviewViewController: UIViewController {
    let completion: SiteDesignStep.SiteDesignSelection
    let demoURL: URL?
    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var footerView: UIView!

    lazy var ghostView: GutenGhostView = {
        let ghost = GutenGhostView()
        ghost.hidesToolbar = true
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

    init(url: String, completion: @escaping SiteDesignStep.SiteDesignSelection) {
        self.completion = completion
        demoURL = URL(string: url)
        super.init(nibName: "\(SiteDesignPreviewViewController.self)", bundle: .main)
        self.title = NSLocalizedString("Preview", comment: "Title for screen to preview a selected homepage design")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGhostView()
        configureWebView()
        styleButtons()
        webView.scrollView.contentInset.bottom = footerView.frame.height
        webView.navigationDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if webView.isLoading {
            ghostView.startAnimation()
        }
    }

    @IBAction func actionButtonSelected(_ sender: Any) {
    }

    private func configureWebView() {
        guard let demoURL = demoURL else { return }
        let request = URLRequest(url: demoURL)
        webView.load(request)
    }

    private func styleButtons() {
        primaryActionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
        primaryActionButton.backgroundColor = accentColor
        primaryActionButton.layer.cornerRadius = 8
    }

    private func addGhostView() {
        let top = NSLayoutConstraint(item: ghostView, attribute: .top, relatedBy: .equal, toItem: webView, attribute: .top, multiplier: 1, constant: 1)
        let bottom = NSLayoutConstraint(item: ghostView, attribute: .bottom, relatedBy: .equal, toItem: webView, attribute: .bottom, multiplier: 1, constant: 1)
        let leading = NSLayoutConstraint(item: ghostView, attribute: .leading, relatedBy: .equal, toItem: webView, attribute: .leading, multiplier: 1, constant: 1)
        let trailing = NSLayoutConstraint(item: ghostView, attribute: .trailing, relatedBy: .equal, toItem: webView, attribute: .trailing, multiplier: 1, constant: 1)
        view.addSubview(ghostView)
        ghostView.addConstraints([top, bottom, leading, trailing])
    }
}

extension SiteDesignPreviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ghostView.stopGhostAnimation()
        ghostView.animatableSetIsHidden(true)
    }
}
