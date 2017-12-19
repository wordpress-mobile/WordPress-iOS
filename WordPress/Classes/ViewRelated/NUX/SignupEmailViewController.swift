import UIKit

class SignupEmailViewController: UIViewController, LoginWithLogoAndHelpViewController {

    // MARK: - Properties

    private var helpBadge: WPNUXHelpBadgeLabel!
    private var helpButton: UIButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }

    func setupNavBar() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton

        addWordPressLogoToNavController()

        let (helpButtonResult, helpBadgeResult) = addHelpButtonToNavController()
        helpButton = helpButtonResult
        helpBadge = helpBadgeResult
    }

    // MARK: - Cancel Button Action

    @objc func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - LoginWithLogoAndHelpViewController methods

    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComSignupEmail)
    }

    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
