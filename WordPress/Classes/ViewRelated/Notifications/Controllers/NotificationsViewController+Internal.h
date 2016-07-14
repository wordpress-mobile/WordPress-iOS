#import "NotificationsViewController.h"


@class ABXPromptView;
@class NSManagedObjectID;
@class WPTableViewHandler;
@class WPNoResultsView;

@protocol WPTableViewHandlerDelegate;


#pragma mark - Private Properties

@interface NotificationsViewController ()

@property (nonatomic, strong) IBOutlet UIView               *tableHeaderView;
@property (nonatomic, strong) IBOutlet UISegmentedControl   *filtersSegmentedControl;
@property (nonatomic, strong) IBOutlet ABXPromptView        *ratingsView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint   *ratingsHeightConstraint;
@property (nonatomic, strong) WPTableViewHandler            *tableViewHandler;
@property (nonatomic, strong) WPNoResultsView               *noResultsView;
@property (nonatomic, strong) NSString                      *pushNotificationID;
@property (nonatomic, strong) NSDate                        *pushNotificationDate;
@property (nonatomic, strong) NSDate                        *lastReloadDate;
@property (nonatomic, strong) NSMutableDictionary<NSManagedObjectID *, NotificationDeletionActionBlock> *notificationDeletionBlocks;
@property (nonatomic, strong) NSMutableSet                  *notificationIdsBeingDeleted;

- (void)setDeletionBlock:(NotificationDeletionActionBlock)deletionBlock forNoteObjectID:(NSManagedObjectID *)noteObjectID;

@end
