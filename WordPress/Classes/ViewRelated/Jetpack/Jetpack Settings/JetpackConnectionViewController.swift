import Foundation

@objc
protocol JetpackConnectionDelegate {
    func jetpackDisconnectedForBlog(_ blog: Blog)
}

/// The purpose of this class is to manage the Jetpack Connection associated to a site.
///
open class JetpackConnectionViewController: UITableViewController {

    // MARK: - Private Properties

    fileprivate var blog: Blog!
    fileprivate var service: BlogJetpackSettingsService!
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Public Properties

    @objc var delegate: JetpackConnectionDelegate?

    // MARK: - Initializer

    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: blog.managedObjectContext!)
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Manage Connection", comment: "Title for the Jetpack Manage Connection Screen")
        ImmuTable.registerRows([DestructiveButtonRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        reloadViewModel()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let disconnectRow = DestructiveButtonRow(title: NSLocalizedString("Disconnect from WordPress.com",
                                                                          comment: "Disconnect from WordPress.com button"),
                                                 action: self.disconnectJetpackTapped(),
                                                 accessibilityIdentifier: "disconnectFromWordPress.comButton")
        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: "",
                rows: [disconnectRow],
                footerText: NSLocalizedString("Your site will no longer send data to WordPress.com and Jetpack features will stop working. You will lose access to the site on the app and you will have to re-add it with the site credentials.",
                                              comment: "Explanatory text bellow the Disconnect from WordPress.com button")
            )])
    }

    // MARK: - Row Handler

    func disconnectJetpackTapped() -> ImmuTableAction {
        return { [unowned self] row in
            self.tableView.deselectSelectedRowWithAnimation(true)
            let message = NSLocalizedString("Are you sure you want to disconnect Jetpack from the site?",
                                            comment: "Message prompting the user to confirm that they want to disconnect Jetpack from the site.")

            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Verb. A button title. Tapping cancels an action."))
            alertController.addDestructiveActionWithTitle(NSLocalizedString("Disconnect",
                                                                            comment: "Title for button that disconnects Jetpack from the site"),
                                                          handler: { action in
                                                              self.disconnectJetpack()
                                                          })
            WPAnalytics.trackEvent(.jetpackDisconnectTapped)
            self.present(alertController, animated: true)
        }
    }

    @objc func disconnectJetpack() {
        WPAnalytics.trackEvent(.jetpackDisconnectRequested)
        self.service.disconnectJetpackFromBlog(self.blog,
                                               success: { [weak self] in
                                                   if let blog = self?.blog {
                                                       // Jetpack was successfully disconnected, lets hide the blog,
                                                       // it should become unavailable the next time blogs are fetched
                                                       let context = ContextManager.sharedInstance().mainContext
                                                       let service = AccountService(managedObjectContext: context)
                                                       service.setVisibility(false, forBlogs: [blog])
                                                       try? context.save()
                                                       self?.delegate?.jetpackDisconnectedForBlog(blog)
                                                   } else {
                                                       self?.dismiss()
                                                   }
                                               },
                                               failure: { error in
                                                   let errorTitle = NSLocalizedString("Error disconnecting Jetpack",
                                                                                      comment: "Title of error dialog when disconnecting jetpack fails.")
                                                   let errorMessage = NSLocalizedString("Please contact support for assistance.",
                                                                                        comment: "Message displayed on an error alert to prompt the user to contact support")
                                                   WPError.showAlert(withTitle: errorTitle, message: errorMessage, withSupportButton: true)
                                                   DDLogError("Error disconnecting Jetpack: \(String(describing: error))")
                                               })
    }

    @objc func dismiss() {
        if isModal() {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

}
