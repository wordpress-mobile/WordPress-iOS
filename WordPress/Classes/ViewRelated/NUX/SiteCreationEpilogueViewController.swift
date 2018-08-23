import UIKit
import WordPressAuthenticator


class SiteCreationEpilogueViewController: NUXViewController {

    // MARK: - Properties

    var siteToShow: Blog? {
        didSet {
            if let newBlog = siteToShow {
                WPTabBarController.sharedInstance().switchMySitesTabToBlogDetails(for: newBlog)
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - ButtonViewController

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(primary: ButtonTitles.primary, secondary: ButtonTitles.secondary)
        return buttonViewController
    }()


    // MARK: - View

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationSitePreviewViewController {
            vc.siteUrl = siteToShow?.url
        }
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationEpilogueViewController: NUXButtonViewControllerDelegate {

    // 'Write first post' button
    func primaryButtonPressed() {
        WPTabBarController.sharedInstance().showPostTab()
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // 'Configure' button
    func secondaryButtonPressed() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}


private extension SiteCreationEpilogueViewController {
    enum ButtonTitles {
        static let primary = NSLocalizedString("Write first post", comment: "On the final site creation page, button to allow the user to write a post for the newly created site.")
        static let secondary = NSLocalizedString("Configure", comment: "Button to allow the user to dismiss the final site creation page.")
    }
}
