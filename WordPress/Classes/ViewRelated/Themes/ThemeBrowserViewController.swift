import Foundation
import WordPressComAnalytics
import WordPressShared.WPStyleGuide
import WordPressShared.WPNoResultsView

/**
 *  @brief      Support for filtering themes by purchasability
 *  @details    Currently purchasing themes via native apps is unsupported
 */
public enum ThemeType
{
    case All
    case Free
    case Premium
    
    static let mayPurchase = false
    
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

/**
 *  @brief      Publicly exposed theme interaction support
 *  @details    Held as weak reference by owned subviews
 */
public protocol ThemePresenter: class
{
    var searchType: ThemeType { get set }
    
    var screenshotWidth: Int { get }

    func currentTheme() -> Theme?
    func activateTheme(theme: Theme?)

    func presentCustomizeForTheme(theme: Theme?)
    func presentPreviewForTheme(theme: Theme?)
    func presentDetailsForTheme(theme: Theme?)
    func presentSupportForTheme(theme: Theme?)
    func presentViewForTheme(theme: Theme?)
}

@objc public class ThemeBrowserViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, WPSearchControllerDelegate, WPSearchResultsUpdating, ThemePresenter, WPContentSyncHelperDelegate
{
    // MARK: - Properties: must be set by parent
    
    /**
     *  @brief      The blog this VC will work with.
     *  @details    Must be set by the creator of this VC.
     */
    public var blog : Blog!
    
    // MARK: - Properties
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchWrapperView: UIView!
    @IBOutlet weak var searchWrapperViewHeightConstraint: NSLayoutConstraint!

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

    /**
     *  @brief      Searching support
     */
    private lazy var searchController: WPSearchController = {
        let searchController = WPSearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self

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
    
    private var suspendedSearch = ""
    
    func resumingSearch() -> Bool {
        return !suspendedSearch.trim().isEmpty
    }
    
    public var searchType: ThemeType = ThemeType.mayPurchase ? .All : .Free {
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
    
    private enum Section
    {
        case Info
        case Themes
    }
    private var sections: [Section]!
    
    private func reloadThemes() {
        collectionView?.reloadData()
        updateResults()
    }
    
    private func themeAtIndex(index: Int) -> Theme? {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        return themesController.objectAtIndexPath(indexPath) as? Theme
    }
    
    private lazy var noResultsView: WPNoResultsView = {
        let noResultsView = WPNoResultsView()
        let drakeImage = UIImage(named: "theme-empty-results")
        noResultsView.accessoryView = UIImageView(image: drakeImage)
        
        return noResultsView
    }()
    
    private var noResultsShown: Bool {
        return noResultsView.superview != nil
    }
    private var presentingTheme: Theme?
   
    /**
     *  @brief      Load theme screenshots at maximum displayed width
     */
    public var screenshotWidth: Int = {
        let windowSize = UIApplication.sharedApplication().keyWindow!.bounds.size
        let vWidth = Styles.imageWidthForFrameWidth(windowSize.width)
        let hWidth = Styles.imageWidthForFrameWidth(windowSize.height)
        let maxWidth = Int(max(hWidth, vWidth))
        return maxWidth
    }()
    
    /**
     *  @brief      The themes service we'll use in this VC and its helpers
     */
    private let themeService = ThemeService(managedObjectContext: ContextManager.sharedInstance().mainContext)
    private var syncHelper: WPContentSyncHelper!
    private var syncingPage = 0
    private let syncPadding = 5

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
        sections = themesCount == 0 ? [.Themes] : [.Info, .Themes]

        configureSearchController()
       
        updateActiveTheme()
        setupSyncHelper()
    }
    
    private func configureSearchController() {
        let searchControllerConfigurator = WPSearchControllerConfigurator(searchController: searchController,
            withSearchWrapperView: searchWrapperView)
        searchControllerConfigurator.configureSearchControllerAndWrapperView()
        
        configureSearchBarPlaceholder()
    }
    
    private func configureSearchBarPlaceholder() {
        let placeholderText = NSLocalizedString("Search",  comment:"Placeholder text for the themes browser search bar")
        let placeholderAttributes = WPStyleGuide.defaultSearchBarTextAttributes(WPStyleGuide.wordPressBlue()) as! [String : AnyObject]
        let attrPlacholderText = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ThemeBrowserViewController.self]).attributedPlaceholder = attrPlacholderText

        let textAttributes = WPStyleGuide.defaultSearchBarTextAttributes(UIColor.whiteColor()) as! [String : AnyObject]
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self, ThemeBrowserViewController.self]).defaultTextAttributes = textAttributes
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ [weak self] context in
            self?.collectionView?.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        collectionView?.collectionViewLayout.invalidateLayout()
       
        if searchController.active {
            searchWrapperViewHeightConstraint.constant = heightForSearchWrapperView()
        }
    }
    
    private func heightForSearchWrapperView() -> CGFloat {
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let height = navBarHeight + statusBarHeight
        return max(height, Styles.minimumSearchHeight)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        registerForKeyboardNotifications()
        
        if resumingSearch() {
            beginSearchFor(suspendedSearch, animated: false)
            suspendedSearch = ""
        }
        
        guard let theme = presentingTheme else {
            return
        }
        presentingTheme = nil
        if !theme.isCurrentTheme() {
            // presented page may have activated this theme
            updateActiveTheme()
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        searchController.active = false
        super.viewWillDisappear(animated)

        unregisterForKeyboardNotifications()
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ThemeBrowserViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ThemeBrowserViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func unregisterForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    public func keyboardDidShow(notification: NSNotification) {
        guard let keyboardEnd = notification.userInfo![UIKeyboardFrameEndUserInfoKey]?
            .CGRectValue, tabBarHeight = tabBarController?.tabBar.bounds.size.height else {
                return
        }
    
        let newInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardEnd.height - tabBarHeight, right: 0)
        collectionView.contentInset = newInsets
        collectionView.scrollIndicatorInsets = newInsets
    }
    
    public func keyboardWillHide(notification: NSNotification) {
        collectionView.contentInset = UIEdgeInsetsZero
        collectionView.scrollIndicatorInsets = UIEdgeInsetsZero
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
        
        if syncHelper.syncContent() {
            updateResults()
        }
    }
    
    private func syncMoreIfNeeded(themeIndex: NSInteger) {
        let paddedCount = themeIndex + syncPadding
        if paddedCount >= themesCount && syncHelper.hasMoreContent && syncHelper.syncMoreContent() {
            updateResults()
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
    
    private func updateResults() {
        if themesCount == 0 {
            showNoResults()
        } else {
            hideNoResults()
        }
    }
    
    private func showNoResults() {
        guard !noResultsShown else {
            return
        }
        
        let title: String
        if searchController.active {
            title = NSLocalizedString("No Themes Found", comment:"Text displayed when theme name search has no matches")
        } else {
            title = NSLocalizedString("Fetching Themes...", comment:"Text displayed while fetching themes")
        }
        noResultsView.titleText = title
        view.addSubview(noResultsView)
        syncMoreIfNeeded(0)
    }
    
    private func hideNoResults() {
        guard noResultsShown else {
            return
        }
        
        noResultsView.removeFromSuperview()

        if searchController.active {
            collectionView?.reloadData()
        } else {
            sections = [.Info, .Themes]
            collectionView?.collectionViewLayout.invalidateLayout()
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
        updateResults()
        let lastVisibleTheme = collectionView?.indexPathsForVisibleItems().last?.row ?? 0
        syncMoreIfNeeded(lastVisibleTheme)
    }
    
    func hasNoMoreContent() {
        syncingPage = 0
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .Info:
            return 0
        case .Themes:
            return themesCount
        }
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ThemeBrowserCell.reuseIdentifier, forIndexPath: indexPath) as! ThemeBrowserCell
        
        cell.presenter = self
        cell.theme = themeAtIndex(indexPath.row)
        
        syncMoreIfNeeded(indexPath.row)
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
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
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    // MARK: - UICollectionViewDelegate

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let theme = themeAtIndex(indexPath.row) {
            if theme.isCurrentTheme() {
                presentCustomizeForTheme(theme)
            } else {
                presentViewForTheme(theme)
            }
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  referenceSizeForHeaderInSection section:NSInteger) -> CGSize {
        guard sections[section] == .Info else {
            return CGSize.zero
        }
        let horizontallyCompact = traitCollection.horizontalSizeClass == .Compact
        let height = Styles.headerHeight(horizontallyCompact)
        
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
        switch sections[section] {
        case .Themes:
            return Styles.themeMargins
        case .Info:
            return Styles.infoMargins
        }
    }

    // MARK: - Search support
    
    @IBAction func didTapSearchButton(sender: UIButton) {
        WPAppAnalytics.track(.ThemesAccessedSearch, withBlog: self.blog)
        beginSearchFor("", animated: true)
    }
    
    private func beginSearchFor(pattern: String, animated: Bool) {
        searchController.active = true
        searchController.searchBar.text = pattern
        searchName = pattern
        
        if animated {
            if sections.first == .Info {
                collectionView?.collectionViewLayout.invalidateLayout()
                collectionView?.performBatchUpdates({
                        self.collectionView?.deleteSections(NSIndexSet(index: 0))
                        self.sections = [.Themes]
                    }, completion: nil)
            }
        } else {
            self.sections = [.Themes]
            self.collectionView?.reloadData()
        }
    }

    // MARK: - WPSearchControllerDelegate

    public func willDismissSearchController(searchController: WPSearchController) {
    
        searchName = ""
        searchController.searchBar.text = ""
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        searchWrapperViewHeightConstraint.constant = 0
        
        UIView.animateWithDuration(Styles.searchAnimationDuration,
            animations: { [weak self] in
                self?.view.layoutIfNeeded()
            })

        if sections.first == .Themes {
            collectionView?.collectionViewLayout.invalidateLayout()
            collectionView?.performBatchUpdates({
                self.collectionView?.insertSections(NSIndexSet(index: 0))
                self.sections = [.Info, .Themes]
            }, completion: nil)
        }
    }

    public func presentSearchController(searchController: WPSearchController) {
        let animated = !resumingSearch()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        searchWrapperViewHeightConstraint.constant = heightForSearchWrapperView()
        searchController.searchBar.becomeFirstResponder()

        if animated {
            UIView.animateWithDuration(Styles.searchAnimationDuration,
                animations: { [weak self] in
                    self?.view.layoutIfNeeded()
                })
        }
    }

    // MARK: - WPSearchResultsUpdating

    public func updateSearchResultsForSearchController(searchController: WPSearchController) {
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
        } catch {
            DDLogSwift.logError("Error fetching themes: \(error)")
        }
    }
  
    // MARK: - NSFetchedResultsControllerDelegate

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        reloadThemes()
    }
    
    // MARK: - ThemePresenter
    
    public func activateTheme(theme: Theme?) {
        guard let theme = theme where !theme.isCurrentTheme() else {
            return
        }
        
        searchController.active = false
        themeService.activateTheme(theme,
            forBlog: blog,
            success: { [weak self] (theme: Theme?) in
                WPAppAnalytics.track(.ThemesChangedTheme, withProperties: ["themeId": theme?.themeId ?? ""], withBlog: self?.blog)

                self?.collectionView?.reloadData()
                
                let successTitle = NSLocalizedString("Theme Activated", comment:"Title of alert when theme activation succeeds")
                let successFormat = NSLocalizedString("Thanks for choosing %@ by %@", comment:"Message of alert when theme activation succeeds")
                let successMessage = String(format:successFormat, theme?.name ?? "", theme?.author ?? "")
                let manageTitle = NSLocalizedString("Manage site", comment:"Return to blog screen action when theme activation succeeds")
                let okTitle = NSLocalizedString("OK", comment:"Alert dismissal title")
                let alertController = UIAlertController(title: successTitle,
                    message: successMessage,
                    preferredStyle: .Alert)
                alertController.addActionWithTitle(manageTitle,
                    style: .Default,
                    handler: { [weak self] (action: UIAlertAction) in
                        self?.navigationController?.popViewControllerAnimated(true)
                    })
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)
                alertController.presentFromRootViewController()
            },
            failure: { (error : NSError!) in
                DDLogSwift.logError("Error activating theme \(theme.themeId): \(error.localizedDescription)")
                
                let errorTitle = NSLocalizedString("Activation Error", comment:"Title of alert when theme activation fails")
                let okTitle = NSLocalizedString("OK", comment:"Alert dismissal title")
                let alertController = UIAlertController(title: errorTitle,
                    message: error.localizedDescription,
                    preferredStyle: .Alert)
                alertController.addDefaultActionWithTitle(okTitle, handler: nil)
                alertController.presentFromRootViewController()
        })
    }

    public func presentCustomizeForTheme(theme: Theme?) {
        WPAppAnalytics.track(.ThemesCustomizeAccessed, withBlog: self.blog)
        presentUrlForTheme(theme, url: theme?.customizeUrl(), activeButton: false)
    }

    public func presentPreviewForTheme(theme: Theme?) {
        WPAppAnalytics.track(.ThemesPreviewedSite, withBlog: self.blog)
        presentUrlForTheme(theme, url: theme?.customizeUrl(), activeButton: false)
    }
    
    public func presentDetailsForTheme(theme: Theme?) {
        WPAppAnalytics.track(.ThemesDetailsAccessed, withBlog: self.blog)
        presentUrlForTheme(theme, url: theme?.detailsUrl())
    }
    
    public func presentSupportForTheme(theme: Theme?) {
        WPAppAnalytics.track(.ThemesSupportAccessed, withBlog: self.blog)
        presentUrlForTheme(theme, url: theme?.supportUrl())
    }
    
    public func presentViewForTheme(theme: Theme?) {
        WPAppAnalytics.track(.ThemesDemoAccessed, withBlog: self.blog)
        presentUrlForTheme(theme, url: theme?.viewUrl())
    }
    
    public func presentUrlForTheme(theme: Theme?, url: String?, activeButton: Bool = true) {
        guard let theme = theme, url = url where !url.isEmpty else {
            return
        }
        
        suspendedSearch = searchName
        searchController.active = false
        presentingTheme = theme
        let webViewController = ThemeWebViewController(theme: theme, url: url)

        webViewController.loadViewIfNeeded()
        webViewController.navigationItem.titleView = nil
        webViewController.title = theme.name
        var buttons: [UIBarButtonItem]?
        if activeButton && !theme.isCurrentTheme() {
           let activate = UIBarButtonItem(title: ThemeAction.Activate.title, style: .Plain, target: self, action: #selector(ThemeBrowserViewController.activatePresentingTheme))
            buttons = [activate]
        }
        webViewController.navigationItem.rightBarButtonItems = buttons

        navigationController?.pushViewController(webViewController, animated:true)
    }
    
    public func activatePresentingTheme() {
        suspendedSearch = ""
        navigationController?.popViewControllerAnimated(true)
        activateTheme(presentingTheme)
        presentingTheme = nil
    }
}
