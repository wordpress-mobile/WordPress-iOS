#import <Foundation/Foundation.h>



/// Shared Heper Definitions:
/// Used by both NotificationsViewController and NotificationDetailsViewController.
///

typedef void (^NotificationDeletionCompletionBlock)(BOOL success);
typedef void (^NotificationDeletionActionBlock)(NotificationDeletionCompletionBlock onCompletion);
typedef void (^NotificationDeletionRequestBlock)(NotificationDeletionActionBlock onUndoTimeout);
