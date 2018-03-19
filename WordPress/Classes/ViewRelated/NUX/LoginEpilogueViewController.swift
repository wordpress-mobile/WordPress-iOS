import UIKit
import WordPressShared


// MARK: - LoginEpilogueViewController
//
class LoginEpilogueViewController: UIViewController {

    /// Button's Container View.
    ///
    @IBOutlet var buttonPanel: UIView!

    /// Separator: to be displayed above the actual buttons.
    ///
    @IBOutlet var shadowView: UIView!

    /// Connect Button!
    ///
    @IBOutlet var connectButton: UIButton!

    /// Continue Button.
    ///
    @IBOutlet var continueButton: UIButton!

    /// Links to the Epilogue TableViewController
    ///
    @objc var tableViewController: LoginEpilogueTableViewController?

    /// Closure to be executed upon dismissal.
    ///
    var onDismiss: (() -> Void)?

    /// Site that was just connected to our awesome app.
    ///
    var site: WordPressSite? {
        didSet {
            guard let site = site else {
                return
            }

            loadViewIfNeeded()
            refreshInterface(with: site)
        }
    }


    // MARK: - Lifecycle Methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.post(event: .loginEpilogueViewed)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? LoginEpilogueTableViewController {
            tableViewController = vc
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorPanelBasedOnTableViewContents()
    }
}


// MARK: - Configuration
//
private extension LoginEpilogueViewController {

    func configureButtons(numberOfBlogs: Int) {
        let connectTitle: String
        if numberOfBlogs == 0 {
            connectTitle = NSLocalizedString("Connect a site", comment: "Button title")
        } else {
            connectTitle = NSLocalizedString("Connect another site", comment: "Button title")
        }

        continueButton.setTitle(NSLocalizedString("Continue", comment: "A button title"),
                                 for: .normal)
        continueButton.accessibilityIdentifier = "Continue"
        connectButton.setTitle(connectTitle, for: .normal)

        if let site = site, case let .wpcom(_, _, isJetpackLogin, _) = site {
            connectButton.isHidden = isJetpackLogin
        }
    }

    func colorPanelBasedOnTableViewContents() {
        guard let tableView = tableViewController?.tableView,
            let buttonPanel = buttonPanel else {
                return
        }

        let contentSize = tableView.contentSize
        let screenHeight = UIScreen.main.bounds.size.height
        let panelHeight = buttonPanel.frame.size.height

        if contentSize.height > (screenHeight - panelHeight) {
            buttonPanel.backgroundColor = UIColor.white
            shadowView.isHidden = false
        } else {
            buttonPanel.backgroundColor = WPStyleGuide.lightGrey()
            shadowView.isHidden = true
        }
    }
}


// MARK: - Actions
//
extension LoginEpilogueViewController {

    @IBAction func dismissEpilogue() {
        onDismiss?()
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func handleConnectAnotherButton() {
        onDismiss?()
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "siteAddress") as? LoginSiteAddressViewController else {
            return
        }
        navigationController?.setViewControllers([controller], animated: true)
    }
}


// MARK: - Interface Private Methods
//
private extension LoginEpilogueViewController {

    /// Refreshes the UI so that the specified WordPressSite is displayed.
    ///
    func refreshInterface(with site: WordPressSite) {
        switch site {
        case .wporg(let username, let password, let xmlrpc, _):
            refreshInterfaceForSelfHosted(username: username, password: password, xmlrpc: xmlrpc)
        case .wpcom:
            refreshInterfaceForDotcom()
        }
    }
}


// MARK: - Dotcom-Y Methods
//
private extension LoginEpilogueViewController {

    /// Refreshes the interface so that the main WordPress.com account is onscreen.
    ///
    func refreshInterfaceForDotcom() {
        /// The self-hosted flow sets user info,  If no user info is set, assume a wpcom flow and try the default wp account.
        ///
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }

        tableViewController?.epilogueUserInfo = LoginEpilogueUserInfo(account: account)
        configureButtons(numberOfBlogs: account.blogs.count)
    }
}


// MARK: - SelfHosted-Y Methods
//
private extension LoginEpilogueViewController {

    /// Refreshes the Interface, to display a newly connected SelfHosted site, with the specified endpoint / credentials.
    ///
    func refreshInterfaceForSelfHosted(username: String, password: String, xmlrpc: String) {

        loadEpilogueInfo(username: username, password: password, xmlrpc: xmlrpc) { [weak self] epilogueInfo in
            guard let `self` = self else {
                return
            }

            self.tableViewController?.epilogueUserInfo = epilogueInfo
            self.tableViewController?.blog = self.loadBlog(with: username, and: xmlrpc)
            self.configureButtons(numberOfBlogs: 1)
        }
    }

    /// Loads the EpilogueInfo for a SelfHosted site, with the specified credentials, at the given endpoint.
    ///
    func loadEpilogueInfo(username: String, password: String, xmlrpc: String, completion: @escaping (LoginEpilogueUserInfo?) -> ()) {

        guard let usersService = UsersService(username: username, password: password, xmlrpc: xmlrpc) else {
            completion(nil)
            return
        }

        /// Load: User's Profile
        ///
        usersService.fetchProfile { userProfile in

            guard let userProfile = userProfile else {
                completion(nil)
                return
            }

            var epilogueInfo = LoginEpilogueUserInfo()
            epilogueInfo.update(with: userProfile)

            /// Load: Gravatar's Metadata
            ///
            let gravatarService = GravatarService()
            gravatarService.fetchProfile(email: userProfile.email) { gravatarProfile in
                if let gravatarProfile = gravatarProfile {
                    epilogueInfo.update(with: gravatarProfile)
                }

                completion(epilogueInfo)
            }
        }
    }

    /// Loads the Blog for a given Username / XMLRPC, if any.
    ///
    private func loadBlog(with username: String, and xmlrpc: String) -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.findBlog(withXmlrpc: xmlrpc, andUsername: username)
    }
}
