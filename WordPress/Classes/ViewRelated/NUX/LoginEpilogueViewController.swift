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

    private func configureButtons(numberOfBlogs: Int) {
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

        if jetpackLogin {
            connectButton?.isHidden = true
        }
    }

    private func colorPanelBasedOnTableViewContents() {
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
