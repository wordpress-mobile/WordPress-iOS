import Foundation


/// Used by both NotificationsViewController and NotificationDetailsViewController.
///
struct NotificationDeletion
{
    typealias Request = (action: Action) -> Void
    typealias Action  = (completion: (Bool -> Void)) -> Void
}
