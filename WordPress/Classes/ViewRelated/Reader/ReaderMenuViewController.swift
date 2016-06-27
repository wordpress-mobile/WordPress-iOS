import Foundation
import WordPressShared


/// The menu for the reader.
///
@objc class ReaderMenuViewController : UITableViewController
{
    let cellIdentifier = "MenuCellIdentifier"

    lazy var viewModel: ReaderMenuViewModel = {
        let vm = ReaderMenuViewModel()
        vm.delegate = self
        return vm
    }()


    /// A convenience method for instantiating the controller.
    ///
    /// - Returns: An instance of the controller.
    ///
    class func controller() -> ReaderMenuViewController {
        return ReaderMenuViewController(style: .Grouped)
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Reader", comment: "")

        configureTableView()
    }


    // MARK: - Configuration


    func configureTableView() {
        WPStyleGuide.resetReadableMarginsForTableView(tableView)
        tableView.registerClass(WPTableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: - Instance Methods


    /// Presents the detail view controller for the specified post on the specified
    /// blog. This is a convenience method for use with Notifications (for example).
    ///
    /// - Parameters:
    ///     - postID: The ID of the post on the specified blog.
    ///     - blogID: The ID of the blog.
    ///
    func openPost(postID: NSNumber, onBlog blogID: NSNumber) {
        let controller = ReaderDetailViewController.controllerWithPostID(postID, siteID: blogID)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Presents the post list for the specified topic.
    ///
    /// - Parameters:
    ///     - topic: The topic to show.
    ///
    func showPostsForTopic(topic: ReaderAbstractTopic) {
        let controller = ReaderStreamViewController.controllerWithTopic(topic)
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Presents the reader's search view controller.
    ///
    func showReaderSearch() {
        let controller = ReaderSearchViewController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - TableView Delegate Methods


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numberOfSectionsInMenu()
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }


    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = viewModel.titleForSection(section)
        let header = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        header.title = title
        return header
    }


    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = viewModel.titleForSection(section)
        return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: view.frame.width)
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }

        // TODO: Remember selection

        if let topic = menuItem.topic {
            showPostsForTopic(topic)
            return
        }

        if menuItem.type == .Search {
            showReaderSearch()
            return
        }
    }


    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let menuItem = viewModel.menuItemAtIndexPath(indexPath) else {
            return
        }
        WPStyleGuide.configureTableViewCell(cell)
        cell.accessoryType = .DisclosureIndicator
        cell.selectionStyle = .Default
        cell.textLabel?.text = menuItem.title
        cell.imageView?.image = menuItem.icon
    }

}


extension ReaderMenuViewController : ReaderMenuViewModelDelegate
{

    func menuDidReloadContent() {
        tableView.reloadData()
    }

    func menuSectionDidChangeContent(index: Int) {
        tableView.reloadData()
    }

}
