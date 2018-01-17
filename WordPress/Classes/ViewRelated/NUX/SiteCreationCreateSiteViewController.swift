import UIKit

class SiteCreationCreateSiteViewController: NUXAbstractViewController {

    // MARK: - Properties

    // Used to store Site Creation user options.
    var siteOptions: [String: Any]?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        addWordPressLogoToNavController()
        // Remove help button.
        navigationItem.rightBarButtonItems = nil
        // Remove Back button. There's no going back now!
        navigationItem.hidesBackButton = true
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
