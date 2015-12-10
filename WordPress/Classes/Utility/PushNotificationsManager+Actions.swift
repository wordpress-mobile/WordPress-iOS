import Foundation


/**
 *  @extension      PushNotificationsManager
 *  @details        In this Extension, we'll encapsulate all of the helpers related to
 *                  UIUserNotificationCategory + UIUserNotificationAction instantiation.
 */

extension PushNotificationsManager
{
    /**
    *  @brief      Parses a given array of NoteCategoryDefinition, and returns a set of
    *              *UIUserNotificationCategory* instances.
    *  @param      definitions     A collection of definitions to be instantiated.
    *  @returns                    A set of *UIUserNotificationCategory* instances.
    */
    
    internal func notificationCategories(definitions: [NoteCategoryDefinition]) -> Set<UIUserNotificationCategory> {
        var categories = Set<UIUserNotificationCategory>()
        let rawActions = definitions.flatMap { $0.actions }
        let actionsMap = notificationActionsMap(rawActions)
        
        for definition in definitions {
            let category = UIMutableUserNotificationCategory()
            category.identifier = definition.identifier
            
            let actions = definition.actions.flatMap { actionsMap[$0] }
            category.setActions(actions, forContext: .Default)
            
            categories.insert(category)
        }
        
        return categories
    }
    
    
    
    /**
     *  @brief      Parses a given array of NoteActionDefinition, and returns a collection mapping them
     *              with their *UIUserNotificationAction* counterparts.
     *
     *  @param      definitions     A collection of definitions to be instantiated.
     *  @returns                    A map of Definition > NotificationAction instances
     */
    internal func notificationActionsMap(definitions: [NoteActionDefinition]) -> [NoteActionDefinition : UIUserNotificationAction] {
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
    
    
    
    /**
     *  @enum       NoteCategoryDefinition
     *  @brief      Describes information about Custom Actions that WPiOS can perform, as a response to
     *              a Push Notification event.
     */
    internal enum NoteCategoryDefinition {
        case CommentApprove
        case CommentLike
        case CommentReply
        case CommentReplyWithLike
        
        var actions : [NoteActionDefinition] {
            return self.dynamicType.actionsMap[self] ?? [NoteActionDefinition]()
        }
        
        var identifier : String {
            return self.dynamicType.identifiersMap[self] ?? String()
        }
        
        static var allDefinitions = [CommentApprove, CommentLike, CommentReply, CommentReplyWithLike]
        
        private static let actionsMap = [
            CommentApprove          : [NoteActionDefinition.CommentApprove],
            CommentLike             : [NoteActionDefinition.CommentLike],
            CommentReply            : [NoteActionDefinition.CommentReply],
            CommentReplyWithLike    : [NoteActionDefinition.CommentLike, NoteActionDefinition.CommentReply]
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
    internal enum NoteActionDefinition {
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
        
        static var allDefinitions = [CommentApprove, CommentLike, CommentReply]
        
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
