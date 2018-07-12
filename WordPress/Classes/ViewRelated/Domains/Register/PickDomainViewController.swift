import UIKit
import WordPressAuthenticator

class PickDomainViewController: UIViewController {

    @IBOutlet weak var buttonContainerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerHeightConstraint: NSLayoutConstraint!

    private var domainsTableViewController: PickDomainTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showButtonView(show: false, withAnimation: false)
    }

    @IBOutlet private var buttonViewContainer: UIView! {
        didSet {
            buttonViewController.move(to: self, into: buttonViewContainer)
        }
    }

    private lazy var buttonViewController: NUXButtonViewController = {
        let buttonViewController = NUXButtonViewController.instance()
        buttonViewController.delegate = self
        buttonViewController.setButtonTitles(
            primary: NSLocalizedString("Choose domain",
                                       comment: "Title for the Choose domain button")
        )
        return buttonViewController
    }()

    static func instance() -> PickDomainViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "PickDomainViewController") as! PickDomainViewController
        return controller
    }

    private func configure() {
        title = NSLocalizedString("Register domain",
                                  comment: "Title for the Register domain screen")
        addCancelBarButtonItem()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
    }

    private func addCancelBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel",
                                     comment: "Navigation bar cancel button for Register domain screen"),
            style: .plain,
            target: self,
            action: #selector(cancelBarButtonTapped)
        )
    }

    private func showButtonView(show: Bool, withAnimation: Bool) {

        let duration = withAnimation ? WPAnimationDurationDefault : 0

        UIView.animate(withDuration: duration, animations: {
            if show {
                self.buttonContainerViewBottomConstraint.constant = 0
            }
            else {
                // Move the view down double the height to ensure it's off the screen.
                // i.e. to defy iPhone X bottom gap.
                self.buttonContainerViewBottomConstraint.constant +=
                    self.buttonContainerHeightConstraint.constant * 2
            }

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? PickDomainTableViewController {
            domainsTableViewController = vc
            domainsTableViewController?.delegate = self
            domainsTableViewController?.siteName = nil
        }
    }

    // MARK: - Actions

    @objc private func cancelBarButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - SiteCreationDomainsTableViewControllerDelegate

extension PickDomainViewController: SiteCreationDomainsTableViewControllerDelegate {
    func domainSelected(_ domain: String) {
        //TODO: keep selected domain
        showButtonView(show: true, withAnimation: true)
    }

    func newSearchStarted() {
        showButtonView(show: false, withAnimation: true)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension PickDomainViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        // TODO: Proceed
    }
}
