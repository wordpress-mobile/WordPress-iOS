//
//  HelpshiftInbox.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern double const HS_NO_EXPIRY_TIMESTAMP;

typedef enum HelpshiftInboxMessageActionType
{
    HelpshiftInboxMessageActionTypeUnknown = 0,
    HelpshiftInboxMessageActionTypeDeepLink,
    HelpshiftInboxMessageActionTypeFaqsScreen,
    HelpshiftInboxMessageActionTypeFaqSection,
    HelpshiftInboxMessageActionTypeFaq,
    HelpshiftInboxMessageActionTypeConversation,
    HelpshiftInboxMessageActionTypeReviewRequest
} HelpshiftInboxMessageActionType;

/**
 *  Get the information related to a Campaign message object.
 */
@protocol HelpshiftInboxMessage <NSObject>

- (NSString *) getIdentifier;
- (UIImage *) getCoverImage;
- (UIImage *) getIconImage;
- (NSString *) getTitle;
- (NSString *) getTitleColor;
- (NSString *) getBody;
- (NSString *) getBodyColor;
- (NSString *) getBackgroundColor;
- (BOOL) getReadStatus;
- (BOOL) getSeenStatus;
- (NSTimeInterval) getCreatedAt;
- (NSTimeInterval) getExpiryTimestamp;

- (NSInteger) getCountOfActions;
- (NSString *) getActionTitleAtIndex:(NSInteger)index;
- (NSString *) getActionTitleColorAtIndex:(NSInteger)index;
- (HelpshiftInboxMessageActionType) getActionTypeAtIndex:(NSInteger)index;
- (NSString *) getActionDataAtIndex:(NSInteger)index;
- (BOOL) getActionGoalCompletionAtIndex:(NSInteger)index;

/**
 *  Execute the action configured for a Campaign button
 *
 *  @param index          index of the button on which user clicked
 *  @param viewController viewController on which to execute the UI transition.
 */
- (void) executeActionAtIndex:(NSInteger)index onViewController:(UIViewController *)viewController;

@end

/**
 *  Protocol for getting callbacks when Campaigns inbox messages are updated.
 */
@protocol HelpshiftInboxDelegate <NSObject>

/**
 *  Callback triggered when a new Campaign message is added.
 *
 *  @param newMessage the new message object.
 */
- (void) inboxMessageAdded:(id<HelpshiftInboxMessage>)newMessage;

/**
 *  Callback triggered when Campaign message is deleted.
 *
 *  @param identifier identifier of the deleted campaign.
 */
- (void) inboxMessageDeleted:(NSString *)identifier;
@optional

/**
 *  Callback triggered when the Helpshift SDK fails to add a Campaign message.
 *
 *  @param identifier identifier of the failed message.
 */
- (void) failedToAddInboxMessageWithId:(NSString *)identifier;

/**
 *  Callback triggered when the icon image for a Campaign gets downloaded.
 *
 *  @param identifier identifier of the updated campaign.
 */
- (void) iconImageDownloadedForInboxMessage:(NSString *)identifier;

/**
 *  Callback triggered when the cover image for a Campaign gets downloaded.
 *
 *  @param identifier identifier of the updated campaign.
 */
- (void) coverImageDownloadedForInboxMessage:(NSString *)identifier;

/**
 *  Callback triggered when an Inbox message is seen by the user
 *
 *  @param identifier identifier of the campaign
 */
- (void) inboxMessageMarkedAsSeen:(NSString *)identifier;

/**
 *  Callback triggered when a Inbox message is marked as read by the user.
 *
 *  @param identifier identifier of the campaign.
 */
- (void) inboxMessageMarkedAsRead:(NSString *)identifier;
@end

/**
 *  Delegate to handle notifications received for In-app Campaign messages.
 */
@protocol HelpshiftInboxNotificationDelegate <NSObject>

/**
 *  Callback that is triggered when a new notification is tapped for an in-app campaign message.
 *
 *  @param identifier identifier of the campaign message.
 */
- (void) handleNotificationForInboxMessage:(NSString *)identifier;

@end

@interface HelpshiftInbox : NSObject

@property (weak, nonatomic) id<HelpshiftInboxDelegate> delegate;
@property (weak, nonatomic) id<HelpshiftInboxNotificationDelegate> hsInboxNotificationDelegate;

/**
 *  Get the shared instance object for HelpshiftInbox
 *
 *  @return object of class HelpshiftInbox
 */
+ (instancetype) sharedInstance;
- (id) init NS_UNAVAILABLE;

/**
 *  Clean up any local memory associated with the HelpshiftInbox object. To start using the class again,
 *  make sure to call the [HelpshiftInbox sharedInstance] API.
 */
- (void) cleanUp;

/**
 *  Get the array of id<HelpshiftInboxMessage> objects which represent the campaigns associated with the current user.
 *
 *  @return NSArray of id<HelpshiftInboxMessage> objects.
 */
- (NSArray *) getAllInboxMessages;

/**
 *  Get the id<HelpshiftInboxMessage> object associated with the given identifier.
 *
 *  @param identifier identifier of the object representing the Campaign message
 *
 *  @return Object representing the Campaign message.
 */
- (id<HelpshiftInboxMessage>) getInboxMessageForId:(NSString *)identifier;

/**
 *  Mark the inbox message as read
 *
 *  @param identifier identifier of the Campaign message
 */
- (void) markInboxMessageAsRead:(NSString *)identifier;

/**
 *  Mark the inbox message as seen.
 *
 *  @param identifier identifier of the campaign message.
 */
- (void) markInboxMessageAsSeen:(NSString *)identifier;

/**
 *  Delete the inbox message from Helpshift's storage.
 *
 *  @param identifier identifier of the campaign message.
 */
- (void) deleteInboxMessage:(NSString *)identifier;

@end
