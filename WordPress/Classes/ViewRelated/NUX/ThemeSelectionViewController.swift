import UIKit

class ThemeSelectionViewController: UIViewController, LoginWithLogoAndHelpViewController, NSFetchedResultsControllerDelegate, WPContentSyncHelperDelegate {

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescrLabel: UILabel!

    var siteType: SiteType!
    private typealias Styles = WPStyleGuide.Themes

    private var helpBadge: WPNUXHelpBadgeLabel!
    private var helpButton: UIButton!

    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var themesSyncHelper: WPContentSyncHelper!

    private lazy var themesController: NSFetchedResultsController<NSFetchRequestResult> = {
        return self.createThemesFetchedResultsController()
    }()

    private var themeCount: NSInteger {
        return themesController.fetchedObjects?.count ?? 0
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        fetchThemes()
        setupThemesSyncHelper()
        syncContent()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, collectionView: collectionView)
        let (helpButtonResult, helpBadgeResult) = addHelpButtonToNavController()
        helpButton = helpButtonResult
        helpBadge = helpBadgeResult
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")

        stepLabel.text = NSLocalizedString("STEP 2 OF 4", comment: "Step for view.")
        stepDescrLabel.text = NSLocalizedString("Get started fast with one of our popular themes. Once your site is created, you can browse and choose from hundreds more.", comment: "Shown during the theme selection step of the site creation flow.")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    // MARK: - Theme Fetching

    private func createThemesFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Theme.entityName())
        fetchRequest.fetchBatchSize = 4
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.themeService.managedObjectContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self

        return frc
    }

    private func fetchThemes() {
        do {
            themesController.fetchRequest.predicate = themesPredicate()
            try themesController.performFetch()
        } catch {
            DDLogError("Error fetching themes: \(error)")
        }
    }

    private func themesPredicate() -> NSPredicate? {

        // TODO: replace with new endpoint.

        let blogThemes = ["Independent Publisher 2", "Penscratch 2", "Intergalactic 2", "Libre 2"]
        let websiteThemes = ["Radcliffe 2", "Karuna", "Dara", "Twenty Seventeen"]
        let portfolioThemes = ["AltoFocus", "Rebalance", "Sketch", "Lodestar"]

        var themes: [String]
        switch siteType {
        case .blog: themes = blogThemes
        case .website: themes = websiteThemes
        case .portfolio: themes = portfolioThemes
        default: themes = blogThemes
        }

        var predicates = [NSPredicate]()
        for themeName in themes {
            predicates.append(NSPredicate(format: "name = %@", themeName))
        }

        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    // MARK: - Theme Syncing

    fileprivate func setupThemesSyncHelper() {
        themesSyncHelper = WPContentSyncHelper()
        themesSyncHelper.delegate = self
    }

    private func syncContent() {
        themesSyncHelper.syncContent()
    }

    fileprivate func syncThemePage(_ page: NSInteger, success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
        assert(page > 0)
        let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount()

        // TODO: replace with new endpoint.

        _ = themeService.getThemesFor(account,
                                      page: page,
                                      success: { (_, _, _) in
        },
                                      failure: { (error) in
                                        DDLogError("Error syncing themes: \(String(describing: error?.localizedDescription))")
                                        if let failure = failure,
                                            let error = error {
                                            failure(error as NSError)
                                        }
        })
    }

    // MARK: - WPContentSyncHelperDelegate

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        if syncHelper == themesSyncHelper {
            syncThemePage(1, success: success, failure: failure)
        }
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        // Nothing to be done here. There will only be one page.
    }

    // MARK: - NSFetchedResultsControllerDelegate

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateResults()
    }

    private func updateResults() {
        collectionView?.reloadData()
    }

    // MARK: - LoginWithLogoAndHelpViewController

    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComCreateSiteTheme)
    }

    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }

    // MARK: - Helpers

    private func themeAtIndexPath(_ indexPath: IndexPath) -> Theme? {
        return themesController.object(at: IndexPath(row: indexPath.row, section: 0)) as? Theme
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UICollectionViewDelegate

extension ThemeSelectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let theme = themeAtIndexPath(indexPath) else {
            return
        }

        let message = "'\(theme.name!)' selected.\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle("OK")
        self.present(alertController, animated: true, completion: nil)
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension ThemeSelectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = Styles.cellSizeForFrameWidth(collectionView.frame.size.width)
        size.width *= 0.95
        size.height *= 0.95
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Styles.themeMargins
    }

}

// MARK: - UICollectionViewDataSource

extension ThemeSelectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectThemeCell.reuseIdentifier, for: indexPath) as! SelectThemeCell
        cell.displayTheme = themeAtIndexPath(indexPath)
        return cell
    }

}
