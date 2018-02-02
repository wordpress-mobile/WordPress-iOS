import UIKit

@objc protocol SiteCreationNoSitesViewControllerDelegate {
    func addSiteButtonPressed()
}

class SiteCreationNoSitesViewController: UIViewController {

    // MARK: - Properties

    @objc weak var delegate: SiteCreationNoSitesViewControllerDelegate?
    @IBOutlet weak var noSitesTitle: UILabel!
    @IBOutlet weak var addSiteButton: NUXButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        WPStyleGuide.configureColors(for: view, andTableView: nil)
        configureElements()
    }

    private func configureElements() {
        noSitesTitle.text = NSLocalizedString("Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", comment: "Text shown when the account has no sites.")
        let buttonTitle = NSLocalizedString("Add new site", comment: "Title of button to add a new site.")
        addSiteButton?.setTitle(buttonTitle, for: UIControlState())
        addSiteButton?.setTitle(buttonTitle, for: .highlighted)
        addSiteButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        addSiteButton?.accessibilityIdentifier = "Add New Site Button"
    }

    // MARK: - Button Handling

    @IBAction func addSiteButtonPressed(_ sender: Any) {
        delegate?.addSiteButtonPressed()
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
