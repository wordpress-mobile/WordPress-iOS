#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"


@class Notification;

@interface NoteTableViewCell : WPTableViewCell

@property (nonatomic, assign) BOOL                  read;
@property (nonatomic, strong) NSAttributedString    *attributedSubject;
@property (nonatomic, strong) NSURL                 *iconURL;
@property (nonatomic, strong) NSString              *noticon;
@property (nonatomic, strong) NSDate                *timestamp;

- (CGFloat)heightForWidth:(CGFloat)width;

+ (NSString *)reuseIdentifier;
+ (NSString *)layoutIdentifier;

@end
