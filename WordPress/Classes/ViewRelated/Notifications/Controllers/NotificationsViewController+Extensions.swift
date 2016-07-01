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
        let bucketName = Notification.classNameWithoutNamespaces()
        let overridenName = simperium.bucketOverrides[bucketName] as? String ?? WPNotificationsBucketName

        guard overridenName != WPNotificationsBucketName else {
            return
        }

        title = "Notifications from [\(overridenName)]"
    }

    func setupConstraints() {
        precondition(ratingsHeightConstraint != nil)

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
        tableView.tableFooterView = UIView()
    }

    func setupTableHandler() {
        let handler = WPTableViewHandler(tableView: tableView)
        handler.cacheRowHeights = true
        handler.delegate = tableViewHandlerDelegate()
        tableViewHandler = handler
    }

    func setupRatingsView() {
        precondition(ratingsView != nil)

        let ratingsSize = CGFloat(15.0)
        let ratingsFont = WPFontManager.systemRegularFontOfSize(ratingsSize)

        ratingsView.label.font = ratingsFont
        ratingsView.leftButton.titleLabel?.font = ratingsFont
        ratingsView.rightButton.titleLabel?.font = ratingsFont
        ratingsView.delegate = appbotViewDelegate()
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
            filtersSegmentedControl.setTitle(title, forSegmentAtIndex: index)
        }

        WPStyleGuide.configureSegmentedControl(filtersSegmentedControl)
    }

    func setupNotificationsBucketDelegate() {
        let notesBucket = simperium.bucketForName(entityName())
        notesBucket.delegate = simperiumBucketDelegate()
        notesBucket.notifyWhileIndexing = true
    }



    // MARK: - UIRefreshControl Methods

    func refresh() {
        // Yes. This is dummy. Simperium handles sync for us!
        refreshControl?.endRefreshing()
    }



    // MARK: - UISegmentedControl Methods

    func segmentedControlDidChange(sender: UISegmentedControl) {
        reloadResultsController()

        // It's a long way, to the top (if you wanna rock'n roll!)
        guard tableViewHandler.resultsController.fetchedObjects?.count != 0 else {
            return
        }

        let path = NSIndexPath(forRow: 0, inSection: 0)
        tableView.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
    }




    // MARK: - Private Properties

    private var simperium: Simperium {
        return WordPressAppDelegate.sharedInstance().simperium
    }
}
