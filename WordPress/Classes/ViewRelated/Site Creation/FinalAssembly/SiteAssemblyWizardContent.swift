
import UIKit

// MARK: - SiteAssemblyWizardContent

final class SiteAssemblyWizardContent: UIViewController {

    // MARK: Properties

    private let siteCreator: SiteCreator

    private let service: SiteAssemblyService

    private let contentView = SiteAssemblyContentView()

    // MARK: SiteAssemblyWizardContent

    init(creator: SiteCreator, service: SiteAssemblyService) {
        self.siteCreator = creator
        self.service = service

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: UIViewController

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func loadView() {
        super.loadView()
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
        setNeedsStatusBarAppearanceUpdate()

        let wizardOutput = siteCreator.build()
        service.createSite(creatorOutput: wizardOutput) { [contentView] status in
            contentView.status = status
        }
    }
}
