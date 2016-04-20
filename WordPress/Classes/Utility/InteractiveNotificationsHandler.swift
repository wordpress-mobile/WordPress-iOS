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
    
    
    /// Returns the SharedApplication instance. This is meant for Unit Testing purposes.
    ///
    var sharedApplication : UIApplication {
        return UIApplication.sharedApplication()
    }
    
    
    
    // MARK: - Public Methods
    
    
    /// Registers the device for User Notifications.
    ///
    public func registerForUserNotifications() {
        if sharedApplication.isRunningSimulator() || sharedApplication.isAlphaBuild() {
            return
        }
        
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: supportedNotificationCategories())
        sharedApplication.registerUserNotificationSettings(settings)
    }
    
    
    /// Handle an action taken from a remote notification
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the action
    ///     - remoteNotification: the notification object
    ///
    public func handleActionWithIdentifier(identifier: String, remoteNotification: NSDictionary) {
        guard defaultAccountAvailable() else {
            return
        }
        
        guard let action = NoteActionDefinition(rawValue: identifier) else {
            return
        }
        
        guard let noteId = remoteNotification.objectForKey("note_id") as? NSNumber else {
            return
        }

        guard let siteID = remoteNotification.objectForKey("blog_id") as? NSNumber else {
            return
        }
        
        guard let commentID = remoteNotification.objectForKey("comment_id") as? NSNumber else {
            return
        }
        
        switch action {
        case .CommentApprove:
            approveCommentWithCommentID(commentID, siteID: siteID)
        case .CommentLike:
            likeCommentWithCommentID(commentID, siteID: siteID)
        case .CommentReply:
            showDetailsWithNoteID(noteId)
        }
    }
    
    

    // MARK: - Private Helpers
    
    
    /// Likes a comment
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///
    private func likeCommentWithCommentID(commentID: NSNumber, siteID: NSNumber) {
        let context = ContextManager.sharedInstance().newDerivedContext()
        let service = CommentService(managedObjectContext: context)
        
        service.likeCommentWithID(commentID, siteID: siteID, success: {
                DDLogSwift.logInfo("Liked comment from push notification")
            },
            failure: { (error: NSError!) -> Void in
                DDLogSwift.logInfo("Couldn't like comment from push notification")
            })
    }
    
    
    /// Approves a comment
    ///
    /// - Parameters:
    ///     - commentID: The comment identifier
    ///     - siteID: The site identifier
    ///
    private func approveCommentWithCommentID(commentID: NSNumber, siteID: NSNumber) {
        let context = ContextManager.sharedInstance().newDerivedContext()
        let service = CommentService(managedObjectContext: context)
        
        service.approveCommentWithID(commentID, siteID: siteID, success: {
                DDLogSwift.logInfo("Successfully moderated comment from push notification")
            },
            failure: { (error: NSError!) -> Void in
                DDLogSwift.logInfo("Couldn't moderate comment from push notification")
            })
    }
    
    
    /// Opens the details for a given notificationID
    ///
    /// - Parameters:
    ///     - noteID: The Notification's Identifier
    ///
    private func showDetailsWithNoteID(noteId: NSNumber) {
        WPTabBarController.sharedInstance().showNotificationsTabForNoteWithID(noteId.stringValue)
    }


    
    /// Checks whether there is a default WordPress.com account available, or not
    ///
    private func defaultAccountAvailable() -> Bool {
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return service.defaultWordPressComAccount() != nil
    }
    
    
    
    
    // MARK: - Private: UIUserNotification Helpers
    
    
    /// Returns a collection of *UIUserNotificationCategory* instances, for each one of the
    /// supported NoteCategoryDefinition enum case's.
    ///
    /// - Returns: A set of *UIUserNotificationCategory* instances.
    ///
    private func supportedNotificationCategories() -> Set<UIUserNotificationCategory> {
        return notificationCategoriesWithDefinitions(NoteCategoryDefinition.allDefinitions)
    }
    
    
    
    /// Parses a given array of NoteCategoryDefinition, and returns a collection of their
    /// *UIUserNotificationCategory* counterparts.
    ///
    /// - Parameters:
    ///     - definitions: A collection of definitions to be instantiated.
    ///
    /// - Returns: A collection of UIUserNotificationCategory instances
    ///
    private func notificationCategoriesWithDefinitions(definitions: [NoteCategoryDefinition]) -> Set<UIUserNotificationCategory> {
        var categories  = Set<UIUserNotificationCategory>()
        let rawActions  = definitions.flatMap { $0.actions }
        let actionsMap  = notificationActionsMapWithDefinitions(rawActions)
        
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
    private func notificationActionsMapWithDefinitions(definitions: [NoteActionDefinition]) -> [NoteActionDefinition : UIUserNotificationAction] {
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
