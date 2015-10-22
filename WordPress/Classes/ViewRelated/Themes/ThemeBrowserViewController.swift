import Foundation

public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
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
    
    /**
     *  @brief      The themes service we'll use in this VC and its helpers
     */
    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var retiredThemes = Set<Theme>()
    private var updatingPage = 0
    private var fetchAnimation = false
   
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
            showFetchAnimation()
        }
        
        updateThemePage(1)
    }

    private func updateThemePage(page: NSInteger) {
        assert(page > 0)
        
        updatingPage = page
        themeService.getThemesForBlog(blog,
            page: updatingPage,
            success: { [weak self] (themes: [Theme]?, hasMore: Bool) in
                self?.updatedThemes(themes, hasMore: hasMore)
            },
            failure: { (error : NSError!) in
                DDLogSwift.logError("Error updating themes: \(error.localizedDescription)")
            })
    }
 
    private func updatedThemes(themes: [Theme]?, hasMore: Bool) {
        if let updatedThemes = themes where !updatedThemes.isEmpty {
            retiredThemes = retiredThemes.subtract(updatedThemes)
        }
        
        if (hasMore) {
            updateThemePage(updatingPage + 1)
        } else if !retiredThemes.isEmpty {
            themeService.managedObjectContext.performBlock {
                for theme in self.retiredThemes {
                    self.themeService.managedObjectContext.deleteObject(theme)
                }
                
                do {
                    try self.themeService.managedObjectContext.save();
                } catch let error as NSError {
                    DDLogSwift.logError("Error retiring themes: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showFetchAnimation() {
        if !fetchAnimation {
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
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserHeaderView", forIndexPath: indexPath)
        return header
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
