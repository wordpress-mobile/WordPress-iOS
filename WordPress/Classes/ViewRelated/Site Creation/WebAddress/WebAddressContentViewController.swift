import UIKit

class WebAddressContentViewController: CollapsableHeaderViewController {
    let tableView: UITableView
    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator
    private let service: SiteAddressService
    let completion: (DomainSuggestion) -> Void

    init(creator: SiteCreator, service: SiteAddressService, selection: @escaping (DomainSuggestion) -> Void) {
        self.siteCreator = creator
        self.service = service
        self.completion = selection
        tableView = UITableView(frame: .zero, style: .grouped)
        super.init(scrollableView: tableView,
                   mainTitle: NSLocalizedString("Choose a domain", comment: "Select domain name. Title"),
                   prompt: NSLocalizedString("This is where people will find you on the internet", comment: "Select domain name. Subtitle"),
                   primaryActionTitle: NSLocalizedString("Create Site", comment: "Button to progress to the next step"))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = NSLocalizedString("Domain", comment: "Shortened version of the main title of the Choose a Domain screen to be used in back navigation")
    }
}
