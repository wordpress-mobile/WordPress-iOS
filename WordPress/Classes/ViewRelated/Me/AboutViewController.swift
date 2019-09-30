import Foundation
import WordPressShared
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class AboutViewController: UITableViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupTableView()
        setupDismissButtonIfNeeded()
    }


    // MARK: - Private Helpers
    fileprivate func setupNavigationItem() {
        title = NSLocalizedString("About", comment: "About this app (information page title)")

        // Don't show 'About' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    fileprivate func setupTableView() {
        // Load and Tint the Logo
        let color                   = UIColor.primary
        let tintedImage             = UIImage(named: "icon-wp")?.withRenderingMode(.alwaysTemplate)
        let imageView               = UIImageView(image: tintedImage)
        imageView.tintColor = color
        imageView.autoresizingMask  = [.flexibleLeftMargin, .flexibleRightMargin]
        imageView.contentMode       = .top

        // Let's add a bottom padding!
        imageView.frame.size.height += iconBottomPadding

        // Finally, setup the TableView
        tableView.tableHeaderView   = imageView
        tableView.contentInset      = WPTableViewContentInsets

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    fileprivate func setupDismissButtonIfNeeded() {
        // Don't display a dismiss button, unless this is the only view in the stack!
        if navigationController?.viewControllers.count > 1 {
            return
        }

        let title = NSLocalizedString("Close", comment: "Dismiss the current view")
        let style = WPStyleGuide.barButtonStyleForBordered()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: style, target: self, action: #selector(AboutViewController.dismissWasPressed(_:)))
    }



    // MARK: - Button Helpers
    @IBAction func dismissWasPressed(_ sender: AnyObject) {
        dismiss(animated: true)
    }



    // MARK: - UITableView Methods
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = WPTableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        }

        let row = rows[indexPath.section][indexPath.row]

        cell!.textLabel?.text       = row.title
        cell!.detailTextLabel?.text = row.details ?? String()
        if row.handler != nil {
            WPStyleGuide.configureTableViewActionCell(cell)
        } else {
            WPStyleGuide.configureTableViewCell(cell)
            cell?.selectionStyle = .none
        }

        return cell!
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section != (rows.count - 1) {
            return nil
        }
        return footerTitleText
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textAlignment = .center
        }
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        if let handler = rows[indexPath.section][indexPath.row].handler {
            handler()
        }
    }



    // MARK: - Private Helpers
    fileprivate func displayWebView(_ urlString: String) {
        displayWebView(URL(string: urlString))
    }

    private func displayWebView(_ url: URL?, title: String? = nil) {
        guard let url = url else {
            return
        }

        if let title = title {
            present(webViewController: WebViewControllerFactory.controller(url: url, title: title))
        }
        else {
            present(webViewController: WebViewControllerFactory.controller(url: url))
        }
    }

    private func present(webViewController: UIViewController) {
        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true)
        }
    }

    fileprivate func displayRatingPrompt() {
        // Note:
        // Let's follow the same procedure executed as in NotificationsViewController, so that if the user
        // manually decides to rate the app, we don't render the prompt!
        //
        WPAnalytics.track(.appReviewsRatedApp)
        AppRatingUtility.shared.ratedCurrentVersion()
        UIApplication.shared.open(AppRatingUtility.shared.appReviewUrl)
    }

    fileprivate func displayTwitterAccount() {
        let twitterURL = URL(string: WPTwitterWordPressMobileURL)!
        UIApplication.shared.open(twitterURL)
    }

    // MARK: - Nested Row Class
    fileprivate class Row {
        let title: String
        let details: String?
        let handler: (() -> Void)?

        init(title: String, details: String?, handler: (() -> Void)?) {
            self.title      = title
            self.details    = details
            self.handler    = handler
        }
    }



    // MARK: - Private Constants
    fileprivate let reuseIdentifier = "reuseIdentifierValue1"
    fileprivate let iconBottomPadding   = CGFloat(30)
    fileprivate let footerBottomPadding = CGFloat(12)



    // MARK: - Private Properties
    fileprivate lazy var footerTitleText: String = {
        let year = Calendar.current.component(.year, from: Date())
        let localizedTitleText = NSLocalizedString("© %ld Automattic, Inc.", comment: "About View's Footer Text. The variable is the current year")
        return String(format: localizedTitleText, year)
    }()

    fileprivate var rows: [[Row]] {
        let appsBlogHostname = URL(string: WPAutomatticAppsBlogURL)?.host ?? String()

        let acknowledgementsString = NSLocalizedString("Acknowledgements", comment: "Displays the list of third-party libraries we use")

        return [
            [
                Row(title: NSLocalizedString("Version", comment: "Displays the version of the App"),
                    details: Bundle.main.shortVersionString(),
                    handler: nil),

                Row(title: NSLocalizedString("Terms of Service", comment: "Opens the Terms of Service Web"),
                    details: nil,
                    handler: { self.displayWebView(URL(string: WPAutomatticTermsOfServiceURL)?.appendingLocale()) }),

                Row(title: NSLocalizedString("Privacy Policy", comment: "Opens the Privacy Policy Web"),
                    details: nil,
                    handler: { self.displayWebView(WPAutomatticPrivacyURL) }),
            ],
            [
                Row(title: NSLocalizedString("Twitter", comment: "Launches the Twitter App"),
                    details: WPTwitterWordPressHandle,
                    handler: { self.displayTwitterAccount() }),

                Row(title: NSLocalizedString("Blog", comment: "Opens the WordPress Mobile Blog"),
                    details: appsBlogHostname,
                    handler: { self.displayWebView(WPAutomatticAppsBlogURL) }),

                Row(title: NSLocalizedString("Rate us on the App Store", comment: "Prompts the user to rate us on the store"),
                    details: nil,
                    handler: { self.displayRatingPrompt() }),

                Row(title: NSLocalizedString("Source Code", comment: "Opens the Github Repository Web"),
                    details: nil,
                    handler: { self.displayWebView(WPGithubMainURL) }),

                Row(title: acknowledgementsString,
                    details: nil,
                    handler: {
                        let url = Bundle.main.url(forResource: "acknowledgements", withExtension: "html")
                        self.displayWebView(url, title: acknowledgementsString)
                }),
            ]
        ]
    }
}
