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
}
