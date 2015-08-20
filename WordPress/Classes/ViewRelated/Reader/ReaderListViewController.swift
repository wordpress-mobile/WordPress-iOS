import Foundation

@objc public class ReaderListViewController : UIViewController, WPContentSyncHelperDelegate, WPTableViewHandlerDelegate
{
    // MARK: - Properties

    @IBOutlet private weak var footerView: UIView!

    private var tableView: UITableView?
    private var refreshControl: UIRefreshControl?
    private var tableViewHandler: WPTableViewHandler?
    private var syncHelper: WPContentSyncHelper?
    private var tableViewController: UITableViewController?

    private var cellForLayout: ReaderPostCardCell?


    // MARK: - LifeCycle Methods

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        tableViewController = segue.destinationViewController as? UITableViewController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureCellForLayout()
        configureTableView()
        configureTableViewHandler()
        configureSyncHelper()

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: -

    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }


    // MARK: - Configuration

    private func configureTableView() {
        tableView = tableViewController!.tableView
        refreshControl = tableViewController!.refreshControl!
    }

    private func configureHeaderView() {

    }

    private func configureFooterView() {

    }

    private func configureTableViewHandler() {
        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler!.cacheRowHeights = true
        tableViewHandler!.updateRowAnimation = .None
        tableViewHandler!.delegate = self
    }

    private func configureSyncHelper() {
        syncHelper = WPContentSyncHelper()
        syncHelper!.delegate = self
    }

    private func configureCellForLayout() {

    }


    // MARK: - Sync Methods

    func syncHelper(syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {

    }

    func syncHelper(syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((hasMore: Bool) -> Void)?, failure: ((error: NSError) -> Void)?) {

    }

    public func syncContentEnded() {

    }


    // MARK: - TableViewHandler Delegate Methods

    public func managedObjectContext() -> NSManagedObjectContext! {
        return nil
    }

    public func fetchRequest() -> NSFetchRequest! {
        return nil
    }

    public func tableView(tableView: UITableView!, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0.0
    }

    public func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0.0
    }

    public func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        return nil
    }

    public func configureCell(cell: UITableViewCell!, atIndexPath indexPath: NSIndexPath!) {

    }

    public func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {

    }


    // MARK: - ReaderCard Delegate Methods

    public func readerCell(cell: ReaderPostCardCell, headerActionForProvider provider: ReaderPostContentProvider) {

    }

    public func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider) {

    }

    public func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider) {

    }

    public func readerCell(cell: ReaderPostCardCell, visitActionForProvider provider: ReaderPostContentProvider) {

    }

    public func readerCell(cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView) {

    }

}