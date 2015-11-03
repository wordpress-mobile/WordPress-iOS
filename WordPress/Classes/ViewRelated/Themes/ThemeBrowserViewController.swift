import Foundation

public protocol ThemePresenter {
    func presentCustomizeForTheme(theme: Theme?)
    func presentDemoForTheme(theme: Theme?)
    func presentDetailsForTheme(theme: Theme?)
    func presentSupportForTheme(theme: Theme?)
}

@objc public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchBarDelegate, ThemePresenter, WPContentSyncHelperDelegate {
    
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
    private var searchName = "" {
        didSet {
            fetchThemes()
       }
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

        setupSyncHelper()
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Syncing the list of themes
    
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
    
    private func currentTheme() -> Theme? {
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
        if isEmpty {
            fetchAnimation = true
            let title = NSLocalizedString("Fetching Themes...", comment:"Text displayed while fetching themes")
            WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: self.view)
        }
    }
    
    private func hideFetchAnimation() {
        if fetchAnimation {
            WPNoResultsView.removeFromView(view)
            fetchAnimation = false
        }
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
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func hasNoMoreContent() {
        syncingPage = 0
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDataSource
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themesCount
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ThemeBrowserCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThemeBrowserCell.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserCell
        let theme = themesController.objectAtIndexPath(indexPath) as? Theme
        
        cell.theme = theme
        
        syncMoreIfNeeded(indexPath.row)
        
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ThemeBrowserHeaderView.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserHeaderView
            header.configureWithTheme(currentTheme(), presenter: self)
            return header
        case UICollectionElementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserFooterView", forIndexPath: indexPath)
            return footer
        default:
            assert(false, "Unexpected theme browser element \(kind)")
        }
    }
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDelegate

    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let theme = themesController.objectAtIndexPath(indexPath) as? Theme {
            presentDemoForTheme(theme)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  referenceSizeForHeaderInSection section:NSInteger) -> CGSize {
        guard !isEmpty else {
            return CGSize.zero
        }
        let height = Styles.headerHeight(isViewHorizontallyCompact())
        
        return CGSize(width: 0, height: height)
    }

    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let parentViewWidth = collectionView.frame.size.width
        
        return Styles.cellSizeForFrameWidth(parentViewWidth)
    }
    
    public func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int) -> CGSize {
            guard syncHelper.isLoadingMore else {
                return CGSize.zero
            }
            
            return CGSize(width: 0, height: Styles.footerHeight)
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool  {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchName = searchText
    }
    
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchName = ""
        searchBar.resignFirstResponder()
    }
    
    public func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool  {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    // MARK: - NSFetchedResultsController helpers

    private func browsePredicate() -> NSPredicate {
        let blogPredicate = NSPredicate(format: "blog == %@", self.blog)
        guard !searchName.isEmpty else {
            return blogPredicate
        }
        
        let namePredicate = NSPredicate(format: "name contains[c] %@", searchName)
        
        let subpredicates = [blogPredicate, namePredicate]
        let browsePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        
        return browsePredicate
    }
    
    private func fetchThemes() {
        do {
            themesController.fetchRequest.predicate = browsePredicate()
            try themesController.performFetch()
            collectionView?.reloadData()
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching themes: \(error.localizedDescription)")
        }
    }
  
    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        hideFetchAnimation()
        collectionView?.reloadData()
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
        
        let navController = UINavigationController(rootViewController: webViewController)
        presentViewController(navController, animated: true, completion: nil)
    }
}
