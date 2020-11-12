import Foundation
import CocoaLumberjack
import WordPressShared

/// This class will display the Blog's "Speed you site" settings, and will allow the user to modify them.
/// Upon selection, WordPress.com backend will get hit, and the new value will be persisted.
///
open class JetpackSpeedUpSiteSettingsViewController: UITableViewController {

    // MARK: - Private Properties

    fileprivate var blog: Blog!
    fileprivate var service: BlogJetpackSettingsService!
    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Computed Properties

    fileprivate var settings: BlogSettings {
        return blog.settings!
    }

    // MARK: - Initializer

    @objc public convenience init(blog: Blog) {
        self.init(style: .grouped)
        self.blog = blog
        self.service = BlogJetpackSettingsService(managedObjectContext: settings.managedObjectContext!)
    }

    // MARK: - View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Speed up your site", comment: "Title for the Speed up your site Settings Screen")
        ImmuTable.registerRows([SwitchRow.self], tableView: tableView)
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        reloadViewModel()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadViewModel()
        refreshSettings()
    }

    // MARK: - Model

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {

        let serveImagesFromOurServers = SwitchRow(title: NSLocalizedString("Serve images from our servers",
                                                                           comment: "Title for the Serve images from our servers setting"),
                                                  value: self.settings.jetpackServeImagesFromOurServers,
                                                  onChange: self.serveImagesFromOurServersValueChanged())

        let lazyLoadImages = SwitchRow(title: NSLocalizedString("\"Lazy-load\" images",
                                                          comment: "Title for the lazy load images setting"),
                                       value: self.settings.jetpackLazyLoadImages,
                                       onChange: self.lazyLoadImagesValueChanged())

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: "",
                rows: [serveImagesFromOurServers],
                footerText: NSLocalizedString("Jetpack will optimize your images and serve them from the server " +
                                              "location nearest to your visitors. Using our global content delivery " +
                                              "network will boost the loading speed of your site.",
                                              comment: "Footer for the Serve images from our servers setting")),


            ImmuTableSection(
                headerText: "",
                rows: [lazyLoadImages],
                footerText: NSLocalizedString("Improve your site's speed by only loading images visible on the screen. " +
                                              "New images will load just before they scroll into view. This prevents " +
                                              "viewers from having to download all the images on a page all at once, " +
                                              "even ones they can't see.",
                                              comment: "Footer for the Serve images from our servers setting")),
        ])
    }

    // MARK: - Row Handlers

    fileprivate func serveImagesFromOurServersValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            self.settings.jetpackServeImagesFromOurServers = newValue
            self.reloadViewModel()
            self.service.updateJetpackServeImagesFromOurServersModuleSettingForBlog(self.blog,
                                                                                    success: {},
                                                                                    failure: { [weak self] (_) in
                                                                                        self?.refreshSettingsAfterSavingError()
                                                                                    })
        }
    }

    fileprivate func lazyLoadImagesValueChanged() -> (_ newValue: Bool) -> Void {
        return { [unowned self] newValue in
            self.settings.jetpackLazyLoadImages = newValue
            self.reloadViewModel()
            self.service.updateJetpackLazyImagesModuleSettingForBlog(self.blog,
                                                                     success: {},
                                                                     failure: { [weak self] (_) in
                                                                         self?.refreshSettingsAfterSavingError()
                                                                     })
        }
    }

    // MARK: - Persistance

    fileprivate func refreshSettings() {
        service.syncJetpackModulesForBlog(blog,
                                          success: { [weak self] in
                                              self?.reloadViewModel()
                                              DDLogInfo("Reloaded Speed up site settings")
                                          },
                                          failure: { (error: Error?) in
                                              DDLogError("Error while syncing blog Speed up site settings: \(String(describing: error))")
                                          })
    }

    fileprivate func refreshSettingsAfterSavingError() {
        let errorTitle = NSLocalizedString("Error updating speed up site settings",
                                           comment: "Title of error dialog when updating speed up site settings fail.")
        let errorMessage = NSLocalizedString("Please contact support for assistance.",
                                             comment: "Message displayed on an error alert to prompt the user to contact support")
        WPError.showAlert(withTitle: errorTitle, message: errorMessage, withSupportButton: true)
        refreshSettings()
    }

}
