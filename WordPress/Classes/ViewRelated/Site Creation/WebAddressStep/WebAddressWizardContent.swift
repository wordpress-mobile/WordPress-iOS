import UIKit

final class WebAddressWizardContent: UIViewController {
    private let service: SiteAddressService
    private var dataCoordinator: (UITableViewDataSource & UITableViewDelegate)?
    private let selection: (SiteAddress) -> Void

    @IBOutlet weak var table: UITableView!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Choose a domain name for your site", comment: "Create site, step 4. Select domain name. Title")
        let subtitle = NSLocalizedString("This is where people will find you on the internet", comment: "Create site, step 4. Select domain name. Subtitle")
        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    init(service: SiteAddressService, selection: @escaping (SiteAddress) -> Void) {
        self.service = service
        self.selection = selection
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //setupTable()
    }

    private func didSelect(_ segment: SiteAddress) {
        selection(segment)
    }
}
