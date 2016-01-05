import Foundation


/// In this class, we'll encapsulate all of the code related to UIUserNotificationCategory and
/// UIUserNotificationAction instantiation, along with the required handlers.
///
final public class InteractiveNotificationsHandler : NSObject
{
    // MARK: - Public Properties
    
    
    /// Returns the shared PushNotificationsManager instance.
    ///
    static let sharedInstance = InteractiveNotificationsHandler()
    
    
    
    // MARK: - Public Methods
    
    
    /// Registers the device for User Notifications.
    ///
    func registerForUserNotifications() {
        let sharedApplication = UIApplication.sharedApplication()
        if sharedApplication.isRunningSimulator() || sharedApplication.isAlphaBuild() {
            return
        }
        
        // User Notifications Registration
        let categories  = supportedNotificationCategories()
        let settings    = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: categories)
        sharedApplication.registerUserNotificationSettings(settings)
    }
    
    
    
    // MARK: - Private Methods
    
    
    /// Returns a collection of *UIUserNotificationCategory* instances, for each one of the
    /// supported NoteCategoryDefinition enum case's.
    ///
    /// - Returns: A set of *UIUserNotificationCategory* instances.
    ///
    private func supportedNotificationCategories() -> Set<UIUserNotificationCategory> {
        return notificationCategories(NoteCategoryDefinition.allDefinitions)
    }
    
    
    
    /// Parses a given array of NoteCategoryDefinition, and returns a collection of their
    /// *UIUserNotificationCategory* counterparts.
    ///
    /// - Parameters:
    ///     - definitions: A collection of definitions to be instantiated.
    ///
    /// - Returns: A collection of UIUserNotificationCategory instances
    ///
    private func notificationCategories(definitions: [NoteCategoryDefinition]) -> Set<UIUserNotificationCategory> {
        var categories  = Set<UIUserNotificationCategory>()
        let rawActions  = definitions.flatMap { $0.actions }
        let actionsMap  = notificationActionsMap(rawActions)
        
        for definition in definitions {
            let category = UIMutableUserNotificationCategory()
            category.identifier = definition.identifier
            
            let actions = definition.actions.flatMap { actionsMap[$0] }
            category.setActions(actions, forContext: .Default)
            
            categories.insert(category)
        }
        
        return categories
    }
    
    
    
    /// Parses a given array of NoteActionDefinition, and returns a collection mapping them with their
    /// *UIUserNotificationAction* counterparts.
    ///
    /// - Parameters:
    ///     - definitions: A collection of definitions to be instantiated.
    ///
    /// - Returns: A map of Definition > NotificationAction instances
    ///
    private func notificationActionsMap(definitions: [NoteActionDefinition]) -> [NoteActionDefinition : UIUserNotificationAction] {
        var actionMap = [NoteActionDefinition : UIUserNotificationAction]()
        
        for definition in definitions {
            let action = UIMutableUserNotificationAction()
            action.identifier = definition.identifier
            action.title = definition.description
            action.activationMode = definition.requiresBackground ? .Background : .Foreground
            action.destructive = definition.destructive
            action.authenticationRequired = definition.requiresAuthentication
            
            actionMap[definition] = action
        }
        
        return actionMap
    }
    
    
    
    /// Describes information about Custom Actions that WPiOS can perform, as a response to
    /// a Push Notification event.
    ///
    private enum NoteCategoryDefinition : String {
        case CommentApprove         = "approve-comment"
        case CommentLike            = "like-comment"
        case CommentReply           = "replyto-comment"
        case CommentReplyWithLike   = "replyto-like-comment"
        
        var actions : [NoteActionDefinition] {
            return self.dynamicType.actionsMap[self] ?? [NoteActionDefinition]()
        }
        
        var identifier : String {
            return rawValue
        }
        
        static var allDefinitions = [CommentApprove, CommentLike, CommentReply, CommentReplyWithLike]
        
        private static let actionsMap = [
            CommentApprove          : [NoteActionDefinition.CommentApprove],
            CommentLike             : [NoteActionDefinition.CommentLike],
            CommentReply            : [NoteActionDefinition.CommentReply],
            CommentReplyWithLike    : [NoteActionDefinition.CommentLike, NoteActionDefinition.CommentReply]
        ]
    }
    
    
    
    /// Describes the custom actions that WPiOS can perform in response to a Push notification.
    ///
    private enum NoteActionDefinition : String {
        case CommentApprove = "COMMENT_MODERATE_APPROVE"
        case CommentLike    = "COMMENT_LIKE"
        case CommentReply   = "COMMENT_REPLY"
        
        var description : String {
            return self.dynamicType.descriptionMap[self] ?? String()
        }
        
        var destructive : Bool {
            return false
        }
        
        var identifier : String {
            return rawValue
        }
        
        var requiresAuthentication : Bool {
            return false
        }
        
        var requiresBackground : Bool {
            return self != .CommentReply
        }
        
        static var allDefinitions = [CommentApprove, CommentLike, CommentReply]
        
        private static let descriptionMap = [
            CommentApprove  : NSLocalizedString("Approve", comment: "Approve comment (verb)"),
            CommentLike     : NSLocalizedString("Like", comment: "Like (verb)"),
            CommentReply    : NSLocalizedString("Reply", comment: "Reply to a comment (verb)")
        ]
    }
}
