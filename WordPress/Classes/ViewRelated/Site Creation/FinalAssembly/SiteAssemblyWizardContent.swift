
import UIKit

// MARK: - SiteAssemblyWizardContent

final class SiteAssemblyWizardContent: UIViewController {

    // MARK: Properties

    private let siteCreator: SiteCreator

    private let service: SiteAssemblyService

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

    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
