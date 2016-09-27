import Foundation


/// Used by both NotificationsViewController and NotificationDetailsViewController.
///
enum NotificationDeletionKind {
    case Spamming
    case Deletion

    var legendText: String {
        switch self {
        case .Deletion:
            return NSLocalizedString("Comment has been deleted", comment: "Displayed when a Comment is deleted")
        case .Spamming:
            return NSLocalizedString("Comment has been marked as Spam", comment: "Displayed when a Comment is spammed")
        }
    }
}


struct NotificationDeletionRequest
{
    let kind    : NotificationDeletionKind
    let action  : (completion: (Bool -> Void)) -> Void
}
