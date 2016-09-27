import Foundation


/// Used by both NotificationsViewController and NotificationDetailsViewController.
///
enum NotificationDeletionKind {
    case Spamming
    case Deletion
}


struct NotificationDeletionRequest
{
    let kind    : NotificationDeletionKind
    let action  : (completion: (Bool -> Void)) -> Void
}
