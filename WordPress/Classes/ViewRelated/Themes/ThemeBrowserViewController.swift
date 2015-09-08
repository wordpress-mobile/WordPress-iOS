import Foundation

public class ThemeBrowserViewController : UICollectionViewController, UISearchBarDelegate {
    
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
        
        updateThemes()
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

        var reuseIdentifier : String? = nil
        
        if kind == UICollectionElementKindSectionHeader {
            reuseIdentifier = "ThemeBrowserHeaderView"
        } else {
            reuseIdentifier = "ThemeBrowserFooterView"
        }
        
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: reuseIdentifier!, forIndexPath: indexPath) as! UICollectionReusableView
    }
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    // MARK: - UISearchBarDelegate
    
    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // SEARCH AWAY!!!
    }
}