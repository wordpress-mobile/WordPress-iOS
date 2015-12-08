import Foundation


/**
 *  @class          PushNotificationsManager
 *  @details        The purpose of this helper is to encapsulate all the tasks related to
 *                  Push Notifications Registration + Handling, including iOS "Actionable" Notifications.
 */

public class PushNotificationsManager : NSObject
{
    /**
     *  @details    Returns the shared PushNotificationsManager instance.
     */
    static let sharedInstance = PushNotificationsManager()
    
    
    
    /**
     *  @details    Returns the SharedApplication instance. This is meant for mock-replacement, to aid
     *              in the unit testing process.
     */
    public var sharedApplication : UIApplication {
        return UIApplication.sharedApplication()
    }
    
    
    
    /**
     *  @brief      Registers the device for Remote + User Notifications.
     *  @details    We'll wire Badge + Sound + Alert notifications, along with support for
     *              iOS User Notifications Actions.
     */
    public func registerForPushNotifications() {
        if sharedApplication.isRunningSimulator() || sharedApplication.isAlphaBuild() {
            return;
        }
        
        // Remote Notifications Registration
        sharedApplication.registerForRemoteNotifications()
        
        // User Notifications Registration
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: noteUserCategories)
        sharedApplication.registerUserNotificationSettings(settings)
    }
    
    
    
    /**
     *  @brief      Returns whether the app has Push Notifications Enabled in Settings.app
     *  @return     True if Push Notifications are enabled in the Settings.app
     */
    public func pushNotificationsEnabledInSettings() -> Bool {
        guard let settings = sharedApplication.currentUserNotificationSettings() else {
            return false
        }
        
        return settings.types != .None
    }
    
    
    
    // MARK: - Private Helpers
    
    /**
     *  @brief      Contains a Set of UIUserNotificationCategory instances, which, in turn, encapsulate
     *              all of the UIUserNotificationAction that our app can deal with.
     */
    private var noteUserCategories : Set<UIUserNotificationCategory>? {
        var categories = Set<UIUserNotificationCategory>()
        var actionMap = noteUserActions
        
        for category in NoteCategory.allCategories {
            let noteCategory = UIMutableUserNotificationCategory()
            noteCategory.identifier = category.identifier
            
            let noteActions = category.actions.flatMap { actionMap[$0] }
            noteCategory.setActions(noteActions, forContext: .Default)
            
            categories.insert(noteCategory)
        }
        
        return categories
    }
    
    
    
    /**
     *  @brief      Returns a map of [NoteAction > UserNotificationAction], which describe all of the
     *              actions that WPiOS can perform in response to a Push Notification event.
     */
    private var noteUserActions : [NoteAction : UIUserNotificationAction] {
        var actionMap = [NoteAction : UIUserNotificationAction]()
        
        for action in NoteAction.allActions {
            let noteAction = UIMutableUserNotificationAction()
            noteAction.identifier = action.identifier
            noteAction.title = action.description
            noteAction.activationMode = action.requiresBackground ? .Background : .Foreground
            noteAction.destructive = action.destructive
            noteAction.authenticationRequired = action.requiresAuthentication
            
            actionMap[action] = noteAction
        }
        
        return actionMap
    }
    
    
    
    /**
     *  @enum       NoteCategory
     *  @brief      Encapsulates information about Custom Actions that WPiOS can perform, as a response to
     *              a Push Notification event.
     */
    private enum NoteCategory {
        case CommentApprove
        case CommentLike
        case CommentReply
        case CommentReplyWithLike
        
        var actions : [NoteAction] {
            return self.dynamicType.actionsMap[self] ?? [NoteAction]()
        }
        
        var identifier : String {
            return self.dynamicType.identifiersMap[self] ?? String()
        }
        
        static var allCategories = [CommentApprove, CommentLike, CommentReply, CommentReplyWithLike]
        
        private static let actionsMap = [
            CommentApprove          : [NoteAction.CommentApprove],
            CommentLike             : [NoteAction.CommentLike],
            CommentReply            : [NoteAction.CommentReply],
            CommentReplyWithLike    : [NoteAction.CommentLike, NoteAction.CommentReply]
        ]
        
        private static let identifiersMap = [
            CommentApprove          : "approve-comment",
            CommentLike             : "like-comment",
            CommentReply            : "replyto-comment",
            CommentReplyWithLike    : "replyto-like-comment"
        ]
    }
    
    
    
    /**
     *  @enum       NoteAction
     *  @brief      Describes the custom actions that WPiOS can perform in response to a Push notification.
     */
    private enum NoteAction {
        case CommentApprove
        case CommentLike
        case CommentReply
        
        var description : String {
            return self.dynamicType.descriptionMap[self] ?? String()
        }
        
        var destructive : Bool {
            return false
        }
        
        var identifier : String {
            return self.dynamicType.identifiersMap[self] ?? String()
        }
        
        var requiresAuthentication : Bool {
            return false
        }
        
        var requiresBackground : Bool {
            return self != .CommentReply
        }
        
        static var allActions = [CommentApprove, CommentLike, CommentReply]
        
        private static let descriptionMap = [
            CommentApprove  : NSLocalizedString("Approve", comment: "Approve comment (verb)"),
            CommentLike     : NSLocalizedString("Like", comment: "Like (verb)"),
            CommentReply    : NSLocalizedString("Reply", comment: "Reply to a comment (verb)")
        ]
        
        private static let identifiersMap = [
            CommentApprove  : "COMMENT_MODERATE_APPROVE",
            CommentLike     : "COMMENT_LIKE",
            CommentReply    : "COMMENT_REPLY"
        ]
    }
}
