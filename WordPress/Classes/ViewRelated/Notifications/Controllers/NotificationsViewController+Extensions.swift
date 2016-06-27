import Foundation
import Simperium
import WordPress_AppbotX
import WordPressShared


extension NotificationsViewController
{
    // MARK: - Setup Helpers

    func setupNavigationBar() {
        // Don't show 'Notifications' in the next-view back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)

        // This is only required for debugging:
        // If we're sync'ing against a custom bucket, we should let the user know about it!
        let simperium = WordPressAppDelegate.sharedInstance().simperium
        let bucketName = "\(Notification.classNameWithoutNamespaces())"

        guard let name = simperium.bucketOverrides[bucketName] as? String where name != WPNotificationsBucketName else {
            return
        }

        title = "Notifications from [\(name)]"
    }

    func setupConstraints() {
        precondition(ratingsTopConstraint != nil)
        precondition(ratingsHeightConstraint != nil)

        // Fix: contentInset breaks tableSectionViews. Let's just increase the headerView's height
        ratingsTopConstraint.constant = UIDevice.isPad() ? CGRectGetHeight(WPTableHeaderPadFrame) : 0.0

        // Ratings is initially hidden!
        ratingsHeightConstraint.constant = 0
    }

    func setupTableView() {
        // Register the cells
        let nibNames = [ NoteTableViewCell.classNameWithoutNamespaces() ]
        let bundle = NSBundle.mainBundle()

        for nibName in nibNames {
            let nib = UINib(nibName: nibName, bundle: bundle)
            tableView.registerNib(nib, forCellReuseIdentifier: nibName)
        }

        // UITableView
        tableView.accessibilityIdentifier  = "Notifications Table"
        WPStyleGuide.configureColorsForView(view, andTableView:tableView)
    }

    func setupTableHeaderView() {
        precondition(tableHeaderView != nil)

        // Fix: Update the Frame manually: Autolayout doesn't really help us, when it comes to Table Headers
        let requiredSize        = tableHeaderView.systemLayoutSizeFittingSize(view.bounds.size)
        var headerFrame         = tableHeaderView.frame
        headerFrame.size.height = requiredSize.height

        tableHeaderView.frame  = headerFrame
        tableHeaderView.layoutIfNeeded()

        // Due to iOS awesomeness, unless we re-assign the tableHeaderView, iOS might never refresh the UI
        tableView.tableHeaderView = tableHeaderView
        tableView.setNeedsLayout()
    }

    func setupTableFooterView() {
        //  Fix: Hide the cellSeparators, when the table is empty
        let footerFrame = UIDevice.isPad() ? CGRectZero : WPTableFooterPadFrame
        tableView.tableFooterView = UIView(frame: footerFrame)
    }

    func setupTableHandler() {
        let handler = WPTableViewHandler(tableView: tableView)
        handler.cacheRowHeights = true
        handler.delegate = self as? WPTableViewHandlerDelegate
        tableViewHandler = handler
    }

    func setupRatingsView() {
        precondition(ratingsView != nil)

        let ratingsFont = WPFontManager.systemRegularFontOfSize(CGFloat(15.0))

        ratingsView.label.font = ratingsFont
        ratingsView.leftButton.titleLabel?.font = ratingsFont
        ratingsView.rightButton.titleLabel?.font = ratingsFont
        ratingsView.delegate = self as? ABXPromptViewDelegate
        ratingsView.alpha = WPAlphaZero
    }

    func setupRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        refreshControl = control
    }

    func setupFiltersSegmentedControl() {
        precondition(filtersSegmentedControl != nil)

        let titles = [
            NSLocalizedString("All", comment: "Displays all of the Notifications, unfiltered"),
            NSLocalizedString("Unread", comment: "Filters Unread Notifications"),
            NSLocalizedString("Comments", comment: "Filters Comments Notifications"),
            NSLocalizedString("Follows", comment: "Filters Follows Notifications"),
            NSLocalizedString("Likes", comment: "Filters Likes Notifications")
        ]

        for (index, title) in titles.enumerate() {
            self.filtersSegmentedControl.setTitle(title, forSegmentAtIndex: index)
        }

        WPStyleGuide.configureSegmentedControl(filtersSegmentedControl)
    }

    func setupNotificationsBucketDelegate() {
        let simperium = WordPressAppDelegate.sharedInstance().simperium
        let notesBucket = simperium.bucketForName(entityName())
        notesBucket.delegate = self as? SPBucketDelegate
        notesBucket.notifyWhileIndexing = true
    }



    // MARK: - UIRefreshControl Methods

    func refresh() {
        // Yes. This is dummy. Simperium handles sync for us!
        refreshControl?.endRefreshing()
    }
}
