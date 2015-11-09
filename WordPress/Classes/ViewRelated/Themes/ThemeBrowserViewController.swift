import Foundation

@objc public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchBarDelegate, WPContentSyncHelperDelegate {
    
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
        let predicate = NSPredicate(format: "blog == %@", self.blog)
        fetchRequest.predicate = predicate
        let sort = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.themeService.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching themes: \(error.localizedDescription)")
        }
        
        return frc
    }()
    private var themesCount: NSInteger {
        return themesController.fetchedObjects?.count ?? 0
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
    
    private func showFetchAnimationIfEmpty() {
        if themesCount == 0 {
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThemeBrowserCell", forIndexPath: indexPath) as! ThemeBrowserCell
        let theme = themesController.objectAtIndexPath(indexPath) as? Theme
        
        cell.theme = theme
        
        syncMoreIfNeeded(indexPath.row)
        
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserHeaderView", forIndexPath: indexPath)
            return header
        case UICollectionElementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserFooterView", forIndexPath: indexPath)
            return footer
        default:
            fatalError("Unexpected theme browser element");
        }
    }
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDelegate

    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let theme = themesController.objectAtIndexPath(indexPath) as? Theme {
            showDemoForTheme(theme)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let parentViewWidth = collectionView.frame.size.width
        let width = cellWidthForFrameWidth(parentViewWidth)
        
        return CGSize(width: width, height: ThemeBrowserCell.heightForWidth(width))
    }
    
    public func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int) -> CGSize {
            guard syncHelper.isLoadingMore else {
                return CGSize.zero
            }
            return CGSize(width: 0, height: Styles.footerHeight)
    }
    
    // MARK: - Layout calculation helper methods
    
    /**
     *  @brief      Calculates the cell width for parent frame
     *
     *  @param      parentViewWidth     The width of the parent view.
     *
     *  @returns    The requested cell width.
     */
    private func cellWidthForFrameWidth(parentViewWidth : CGFloat) -> CGFloat {
        let numberOfColumns = max(1, trunc(parentViewWidth / Styles.minimumColumnWidth))
        let numberOfMargins = numberOfColumns + 1
        let marginsWidth = numberOfMargins * Styles.columnMargin
        let columnsWidth = parentViewWidth - marginsWidth
        let columnWidth = trunc(columnsWidth / numberOfColumns)
        
        return columnWidth
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // SEARCH AWAY!!!
    }
    
    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        hideFetchAnimation()
        collectionView?.reloadData()
    }
    
    // MARK: - Theme actions
    
    private func showDemoForTheme(theme: Theme) {
        
        let url = NSURL(string: theme.demoUrl)
        let webViewController = WPWebViewController(URL: url)
        
        webViewController.authToken = blog.authToken
        webViewController.username = blog.usernameForSite
        webViewController.password = blog.password
        webViewController.wpLoginURL = NSURL(string: blog.loginUrl())
        
        let navController = UINavigationController(rootViewController: webViewController)
        presentViewController(navController, animated: true, completion: nil)
    }
    
}
