import Foundation

public protocol ThemePresenter {
    func presentCustomizeForTheme(theme: Theme?)
    func presentDemoForTheme(theme: Theme?)
    func presentDetailsForTheme(theme: Theme?)
    func presentSupportForTheme(theme: Theme?)
}

public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchBarDelegate, ThemePresenter {
    
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
            managedObjectContext: self.managedObjectContext,
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
    
    /**
     *  @brief      The themes service we'll use in this VC and its helpers
     */
    private lazy var themeService : ThemeService = {
        ThemeService(managedObjectContext: self.managedObjectContext)
    }()
    private lazy var managedObjectContext = {
        ContextManager.sharedInstance().mainContext
    }()
    private var retiredThemes = Set<Theme>()
    private var fetchAnimation = false
   
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Themes", comment: "Title of Themes browser page")
        
        WPStyleGuide.configureColorsForView(view, collectionView:collectionView)
        
        updateThemes()
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Updating the list of themes
    
    private func updateThemes() {
        if let fetchedThemes = themesController.fetchedObjects as? [Theme] where !fetchedThemes.isEmpty {
            retiredThemes = retiredThemes.union(Set(fetchedThemes))
        } else {
            fetchAnimation = true
            let title = NSLocalizedString("Fetching Themes...", comment:"Text displayed while fetching themes")
            WPNoResultsView.displayAnimatedBoxWithTitle(title, message: nil, view: self.view)
        }
        
        updateThemePage(1)
    }

    private func updateThemePage(page: NSInteger) {
        assert(page > 0)
        
        themeService.getThemesForBlog(blog,
            page: page,
            success: { [weak self] (themes: [Theme]?, hasMore: Bool) in
                guard let strongSelf = self else {
                    return
                }
                
                if let updatedThemes = themes where !updatedThemes.isEmpty {
                    strongSelf.retiredThemes = strongSelf.retiredThemes.subtract(updatedThemes)
                }
                
                if (hasMore) {
                    strongSelf.updateThemePage(page + 1)
                } else if !strongSelf.retiredThemes.isEmpty {
                    let retireContext = strongSelf.managedObjectContext
                    
                    retireContext.performBlock {
                        for theme in strongSelf.retiredThemes {
                            retireContext.deleteObject(theme)
                        }
                        
                        do {
                            try retireContext.save();
                        } catch let error as NSError {
                            DDLogSwift.logError("Error retiring themes: \(error.localizedDescription)")
                        }
                    }
                }
            },
            failure: { (error : NSError!) in
                DDLogSwift.logError("Error updating themes: \(error.localizedDescription)")
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
    
    private func isEmpty() -> Bool {
        let themeCount = collectionView(collectionView!, numberOfItemsInSection: 0)
        return themeCount == 0
    }

    // MARK: - UICollectionViewController protocol UICollectionViewDataSource
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themesController.fetchedObjects?.count ?? 0
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ThemeBrowserCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThemeBrowserCell", forIndexPath: indexPath) as! ThemeBrowserCell
        let theme = themesController.objectAtIndexPath(indexPath) as? Theme
        
        cell.theme = theme
        
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ThemeBrowserHeaderView.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserHeaderView
        header.configureWithTheme(currentTheme(), presenter: self)
        
        return header
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
        
        guard !isEmpty() else {
            return CGSize.zero
        }
        
        let height = isViewHorizontallyCompact() ? WPStyleGuide.Themes.currentBarHeightCompact : WPStyleGuide.Themes.currentBarHeightRegular
        
        return CGSize(width: 0, height: height)
    }

    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let parentViewWidth = collectionView.frame.size.width
        let width = cellWidthForFrameWidth(parentViewWidth)
        
        return CGSize(width: width, height: ThemeBrowserCell.heightForWidth(width))
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
        let numberOfColumns = max(1, trunc(parentViewWidth / WPStyleGuide.Themes.minimumColumnWidth))
        let numberOfMargins = numberOfColumns + 1
        let marginsWidth = numberOfMargins * WPStyleGuide.Themes.columnMargin
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
        dispatch_async(dispatch_get_main_queue(), { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.fetchAnimation {
                WPNoResultsView.removeFromView(strongSelf.view)
                strongSelf.fetchAnimation = false
            }

            strongSelf.collectionView?.reloadData()
        })
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
