//import Foundation
//
//
///// Used by both NotificationsViewController and NotificationDetailsViewController.
/////
//enum NotificationDeletionKind {
//    case spamming
//    case deletion
//
//    var legendText: String {
//        switch self {
//        case .deletion:
//            return NSLocalizedString("Comment has been deleted", comment: "Displayed when a Comment is deleted")
//        case .spamming:
//            return NSLocalizedString("Comment has been marked as Spam", comment: "Displayed when a Comment is spammed")
//        }
//    }
//}
//
//
//struct NotificationDeletionRequest {
//    let kind: NotificationDeletionKind
//    let action  : (_ completion: @escaping ((Bool) -> Void)) -> Void
//}
