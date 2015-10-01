import Foundation

public class ThemeBrowserViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    // MARK: - Properties: must be set by parent
    
    /**
     *  @brief      The blog this VC will work with.
     *  @details    Must be set by the creator of this VC.
     */
    private var blog : Blog!
    
    // MARK: - Properties: managed object context & services
    
    /**
     *  @brief      The managed object context this VC will use for it's operations.
     */
    private let managedObjectContext : NSManagedObjectContext = {
       let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = ContextManager.sharedInstance()!.mainContext
        
        return context
    }()
    
    /**
     *  @brief      The themes service we'll use in this VC.
     */
    private lazy var themeService : ThemeService = {
        return ThemeService(managedObjectContext: self.managedObjectContext)
    }()
    
    // MARK: - Properties: Layout configuration
    private let marginWidth = CGFloat(10)
    private let minimumColumnWidth = CGFloat(250)
 
    // MARK: - Themes
    
    /**
     *  @brief      The array of themes to display on screen.
     *  @details    After set, will try to reload the collectionView
     */
    private var themes : [Theme] = [] {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: - Additional initialization
    
    public func configureWithBlog(blog: Blog) {
        self.blog = blog
    }
    
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Themes", comment: "Title of Themes browser page")
        
        WPStyleGuide.configureColorsForView(view, collectionView:collectionView)
        
        updateThemes()
    }

    public override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    @available(iOS 8.0, *)
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Updating the list of themes
    
    private func updateThemes() {
        self.themeService.getThemesForBlog(
            self.blog,
            success: { (themes : [AnyObject]?) -> Void in
                
                if let unwrappedThemes = themes as? [Theme] {
                    self.themes = unwrappedThemes
                } else {
                    self.themes = []
                }
                
            }) { (error : NSError!) -> Void in
                // Handle the error
        }
    }
    
    // MARK: - UICollectionViewController protocol UICollectionViewDataSource
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            
        return self.themes.count;
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ThemeBrowserCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThemeBrowserCell", forIndexPath: indexPath) as! ThemeBrowserCell
        let theme = themes[indexPath.row]
        
        cell.configureWithTheme(theme)
        
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "ThemeBrowserHeaderView", forIndexPath: indexPath)
        return header
    }
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let parentViewWidth = collectionView.frame.size.width
        let width = cellWidthForFrameWidth(parentViewWidth)
        
        return CGSize(width: width, height: width)
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
        let numberOfColumns = trunc(parentViewWidth / minimumColumnWidth)
        let numberOfMargins = numberOfColumns + 1
        let marginsWidth = numberOfMargins * marginWidth
        let columnsWidth = parentViewWidth - marginsWidth
        let columnWidth = trunc(columnsWidth / numberOfColumns)
        
        return columnWidth
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // SEARCH AWAY!!!
    }
}