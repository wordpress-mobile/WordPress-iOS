#import <UIKit/UIKit.h>
#import "NoteBlockTableViewCell.h"



typedef void (^NotificationFollowHandler)();

@interface NoteBlockUserTableViewCell : NoteBlockTableViewCell

@property (nonatomic, strong) NSString                  *name;
@property (nonatomic, strong) NSURL                     *blogURL;
@property (nonatomic, strong) NSURL                     *gravatarURL;
@property (nonatomic, assign) BOOL                      actionEnabled;
@property (nonatomic, assign) BOOL                      following;
@property (nonatomic, copy)   NotificationFollowHandler onFollowClick;

@end
