
import UIKit

import WordPressAuthenticator

// MARK: - SiteAssemblyWizardContent

final class SiteAssemblyWizardContent: UIViewController {

    // MARK: Properties

    private let siteCreator: SiteCreator

    private let service: SiteAssemblyService

    private let contentView = SiteAssemblyContentView()

    private let buttonViewController = NUXButtonViewController.instance()

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
        installButtonViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
        setNeedsStatusBarAppearanceUpdate()

        if let domainName = siteCreator.address?.domainName {
            contentView.domainName = domainName
        }

        let wizardOutput = siteCreator.build()
        service.createSite(creatorOutput: wizardOutput) { [contentView] status in
            contentView.status = status
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        contentView.adjustConstraints()
    }

    // MARK: Private behavior

    private func installButtonViewController() {
        buttonViewController.delegate = self

        let primaryButtonText = NSLocalizedString("Done",
                                                  comment: "Tapping a button with this label allows the user to exit the Site Creation flow")
        buttonViewController.setButtonTitles(primary: primaryButtonText)

        contentView.buttonContainerView = buttonViewController.view

        buttonViewController.willMove(toParent: self)
        addChild(buttonViewController)
        buttonViewController.didMove(toParent: self)
    }
}

// MARK: - NUXButtonViewControllerDelegate

extension SiteAssemblyWizardContent: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
        navigationController?.dismiss(animated: true)
    }
}
