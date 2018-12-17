
import UIKit

import WordPressAuthenticator

// MARK: - SiteAssemblyWizardContent

/// This view controller manages the final step in the enhanced site creation sequence - invoking the service &
/// apprising the user of the outcome.
///
final class SiteAssemblyWizardContent: UIViewController {

    // MARK: Properties

    /// The creator collects user input as they advance through the wizard flow.
    private let siteCreator: SiteCreator

    /// The service with which the final assembly interacts to coordinate site creation.
    private let service: SiteAssemblyService

    /// The content view serves as the root view of this view controller.
    private let contentView = SiteAssemblyContentView()

    /// We reuse a `NUXButtonViewController` from `WordPressAuthenticator`. Ideally this might be in `WordPressUI`.
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

        do {
            let wizardOutput = try siteCreator.build()

            contentView.domainName = wizardOutput.siteURLString
            service.createSite(creatorOutput: wizardOutput) { [contentView] status in
                contentView.status = status
            }
        } catch is SiteCreatorOutputError {
            DDLogError("Unable to proceed in Site Creation flow due to an apparent validation error")
            assertionFailure()
        } catch {
            DDLogError("Unable to proceed due to unexpected error")
            assertionFailure()
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
