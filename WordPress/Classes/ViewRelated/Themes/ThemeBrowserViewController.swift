import Foundation

public enum ThemeType {
    case All
    case Free
    case Premium
    
    static let types = [All, Free, Premium]

    var title: String {
        switch self {
        case .All:
            return NSLocalizedString("All", comment: "Browse all themes selection title")
        case .Free:
            return NSLocalizedString("Free", comment: "Browse free themes selection title")
        case .Premium:
            return NSLocalizedString("Premium", comment: "Browse premium themes selection title")
        }
    }
    
    var predicate: NSPredicate? {
        switch self {
        case .All:
            return nil
        case .Free:
            return NSPredicate(format: "premium == 0")
        case .Premium:
            return NSPredicate(format: "premium == 1")
        }
    }
}

public protocol ThemePresenter: class {
    func currentTheme() -> Theme?
    var searchType: ThemeType { get set }
    
    func presentCustomizeForTheme(theme: Theme?)
    func presentDemoForTheme(theme: Theme?)
    func presentDetailsForTheme(theme: Theme?)
    func presentSupportForTheme(theme: Theme?)
}

@objc public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, ThemePresenter, WPContentSyncHelperDelegate {
    
    // MARK: - Properties: must be set by parent
    
    /**
     *  @brief      The blog this VC will work with.
     *  @details    Must be set by the creator of this VC.
     */
    public var blog : Blog!
    
    // MARK: - Properties
    
    /**
     *  @brief      The FRC this VC will use to display filtered content.
     */
    private lazy var themesController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: Theme.entityName())
        fetchRequest.fetchBatchSize = 20
        let sort = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.themeService.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        frc.delegate = self
        
        return frc
    }()
    private var themesCount: NSInteger {
        return themesController.fetchedObjects?.count ?? 0
    }
	private var isEmpty: Bool {
        return searchName.isEmpty && themesCount == 0
    }

    /**
     *  @brief      Searching support
     */
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .None
        searchController.searchBar.autocorrectionType = .No
        searchController.searchBar.barTintColor = WPStyleGuide.wordPressBlue()

        return searchController
    }()
    private var searchName = "" {
        didSet {
            if searchName != oldValue {
                fetchThemes()
                reloadThemes()
            }
       }
    }
    public var searchType = ThemeType.All {
        didSet {
            if searchType != oldValue {
                fetchThemes()
                reloadThemes()
            }
        }
    }
    
    /**
     *  @brief      Collection view support
     */
    
    private enum Section {
        case Info
        case Themes
    }
    private var sections: [Section]!
    
    private func reloadThemes() {
        collectionView?.reloadData()
    }
    private func themeAtIndex(index: Int) -> Theme? {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        return themesController.objectAtIndexPath(indexPath) as? Theme
    }
   
    /**
     *  @brief      The themes service we'll use in this VC and its helpers
     */
    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var syncHelper: WPContentSyncHelper!
    private var syncingPage = 0
    private let syncPadding = 5
    private var fetchAnimation = false
    
    // MARK: - Private Aliases
    
    private typealias Styles = WPStyleGuide.Themes
    
     /**
     *  @brief      Convenience method for browser instantiation
     *
     *  @param      blog     The blog to browse themes for
     *
     *  @returns    ThemeBrowserViewController instance
     */
    public class func browserWithBlog(blog: Blog) -> ThemeBrowserViewController {
        let storyboard = UIStoryboard(name: "ThemeBrowser", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController() as! ThemeBrowserViewController
        viewController.blog = blog
        
        return viewController
    }
    
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Themes", comment: "Title of Themes browser page")
        
        WPStyleGuide.configureColorsForView(view, collectionView:collectionView)
        
        fetchThemes()
        sections = isEmpty ? [.Themes] : [.Info, .Themes]

        updateActiveTheme()
        setupSyncHelper()
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Syncing the list of themes
    
    private func updateActiveTheme() {
        let lastActiveThemeId = blog.currentThemeId
        
        themeService.getActiveThemeForBlog(blog,
            success: { [weak self] (theme: Theme?) in
                if lastActiveThemeId != theme?.themeId {
                    self?.collectionView?.collectionViewLayout.invalidateLayout()
                }
            },
            failure: { (error : NSError!) in
                DDLogSwift.logError("Error updating active theme: \(error.localizedDescription)")
        })
    }
    
    private func setupSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper.delegate = self
        
        showFetchAnimationIfEmpty()
        syncHelper.syncContent()
    }
    
    private func syncMoreIfNeeded(themeIndex: NSInteger) {
        let paddedCount = themeIndex + syncPadding
        if paddedCount >= themesCount && syncHelper.hasMoreContent {
            showFetchAnimationIfEmpty()
            syncHelper.syncMoreContent()
        }
    }
    
    private func syncThemePage(page: NSInteger, success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        assert(page > 0)
        
        syncingPage = page
        themeService.getThemesForBlog(blog,
            page: syncingPage,
            sync: page == 1,
            success: {(themes: [Theme]?, hasMore: Bool) in
                if let success = success {
                    success(hasMore: hasMore)
                }
            },
            failure: { (error : NSError!) in
                DDLogSwift.logError("Error syncing themes: \(error.localizedDescription)")
                if let failure = failure {
                    failure(error: error)
                }
            })
    }
    
    public func currentTheme() -> Theme? {
        guard let themeId = blog.currentThemeId where !themeId.isEmpty else {
            return nil
        }
        
        for theme in blog.themes as! Set<Theme> {
            if theme.themeId == themeId {
                return theme
            }
        }
        
        return nil
    }
    
    private func showFetchAnimationIfEmpty() {
        guard isEmpty else {
            return
        }
        
        fetchAnimation = true
        let title = NSLocalizedString("Fetching Themes...", comment:"Text displayed while fetching themes")
        WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: self.view)
    }
    
    private func hideFetchAnimation() {
        guard fetchAnimation else {
            reloadThemes()
            return
        }

        fetchAnimation = false
        sections = [.Info, .Themes]
        collectionView?.collectionViewLayout.invalidateLayout()
        WPNoResultsView.removeFromView(view)
    }

    // MARK: - WPContentSyncHelperDelegate
    
    func syncHelper(syncHelper:WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {        
        syncThemePage(1, success: success, failure: failure)
    }
    
    func syncHelper(syncHelper:WPContentSyncHelper, syncMoreWithSuccess success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {
        let nextPage = syncingPage + 1
        syncThemePage(nextPage, success: success, failure: failure)
    }
    
    func syncContentEnded() {
        hideFetchAnimation()
    }
    
    func hasNoMoreContent() {
        syncingPage = 0
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDataSource
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .Info: return 0
        case .Themes: return themesCount
        }
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ThemeBrowserCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThemeBrowserCell.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserCell
        
        cell.theme = themeAtIndex(indexPath.row)
        
        syncMoreIfNeeded(indexPath.row)
        
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ThemeBrowserHeaderView.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserHeaderView
            header.presenter = self
            return header
        case UICollectionElementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserFooterView", forIndexPath: indexPath)
            return footer
        default:
            fatalError("Unexpected theme browser element");
        }
    }
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDelegate

    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let theme = themeAtIndex(indexPath.row) {
            if theme.isCurrentTheme() {
                presentCustomizeForTheme(theme)
            } else {
                presentDemoForTheme(theme)
            }
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  referenceSizeForHeaderInSection section:NSInteger) -> CGSize {
        guard sections[section] == .Info else {
            return CGSize.zero
        }
        let height = Styles.headerHeight(isViewHorizontallyCompact())
        
        return CGSize(width: 0, height: height)
    }

    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let parentViewWidth = collectionView.frame.size.width
        
        return Styles.cellSizeForFrameWidth(parentViewWidth)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
            guard sections[section] == .Themes && syncHelper.isLoadingMore else {
                return CGSize.zero
            }
            
            return CGSize(width: 0, height: Styles.footerHeight)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        switch sections.count {
        case 1:
            return Styles.externalMargins
        default:
            return Styles.internalMargins
        }
    }

    // MARK: - Search support
    
    @IBAction func didTapSearchButton(sender: UIButton) {
        searchController.active = true
        if sections.count > 1 {
            collectionView?.performBatchUpdates({
                self.collectionView?.deleteSections(NSIndexSet(index: 0))
                self.sections = [.Themes]
            }, completion: nil)
        }
    }

    // MARK: - UISearchControllerDelegate

    public func willDismissSearchController(searchController: UISearchController) {
        if sections.count == 1 {
            collectionView?.performBatchUpdates({
                self.collectionView?.insertSections(NSIndexSet(index: 0))
                self.sections = [.Info, .Themes]
            }, completion: nil)
        }
    }

    public func presentSearchController(searchController: UISearchController) {
        presentViewController(searchController, animated: true, completion: nil)
    }

    // MARK: - UISearchResultsUpdating
    
    public func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchName = searchController.searchBar.text ?? ""
    }

    // MARK: - NSFetchedResultsController helpers

    private func searchNamePredicate() -> NSPredicate? {
        guard !searchName.isEmpty else {
            return nil
        }
        
        return NSPredicate(format: "name contains[c] %@", searchName)
    }
    
    private func browsePredicate() -> NSPredicate? {
        let blogPredicate = NSPredicate(format: "blog == %@", self.blog)

        let subpredicates = [blogPredicate, searchNamePredicate(), searchType.predicate].flatMap { $0 }
        switch subpredicates.count {
        case 1:
            return subpredicates[0]
        default:
            return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        }
    }
    
    private func fetchThemes() {
        do {
            themesController.fetchRequest.predicate = browsePredicate()
            try themesController.performFetch()
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching themes: \(error.localizedDescription)")
        }
    }
  
    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        hideFetchAnimation()
    }
    
    // MARK: - ThemePresenter
    
    public func presentCustomizeForTheme(theme: Theme?) {
        guard let theme = theme, url = NSURL(string: theme.customizeUrl()) else {
            return
        }
        
        presentUrlForTheme(url)
    }

    public func presentDemoForTheme(theme: Theme?) {
        guard let theme = theme, url = NSURL(string: theme.demoUrl) else {
            return
        }
        
        presentUrlForTheme(url)
    }

    public func presentDetailsForTheme(theme: Theme?) {
        guard let theme = theme, url = NSURL(string: theme.detailsUrl()) else {
            return
        }
        
        presentUrlForTheme(url)
    }
    
    public func presentSupportForTheme(theme: Theme?) {
        guard let theme = theme, url = NSURL(string: theme.supportUrl()) else {
            return
        }
        
        presentUrlForTheme(url)
    }
    
    public func presentUrlForTheme(url: NSURL) {
        let webViewController = WPWebViewController(URL: url)
        
        webViewController.authToken = blog.authToken
        webViewController.username = blog.usernameForSite
        webViewController.password = blog.password
        webViewController.wpLoginURL = NSURL(string: blog.loginUrl())
        
        navigationController?.pushViewController(webViewController, animated:true)
    }
}
