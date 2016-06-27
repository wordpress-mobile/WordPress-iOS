import Foundation
import WordPressShared


extension NotificationsViewController
{

    // MARK: - Setup Helpers

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
}
