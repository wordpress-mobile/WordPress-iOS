#import <UIKit/UIKit.h>

extern const CGFloat PostHeaderViewAvatarSize;

@interface ReaderPostHeaderView : UIView

/**
 A ReaderPostHeaderCallback block to be executed whenever the user pressed this view.
 */
typedef void (^ReaderPostHeaderCallback)(void);
@property (nonatomic, copy) ReaderPostHeaderCallback onClick;

/**
 A BOOL indicating whether if this view should display a disclosure indicator, or not.
 */
@property (nonatomic, assign) BOOL showsDisclosureIndicator;

/**
 A UIImage instance to be displayed as the User's avatar.
 */
@property (nonatomic, strong) UIImage *avatarImage;

/**
 A NSString representing the header's title.
 */
@property (nonatomic, strong) NSString *title;

/**
 A NSString representing the header's subtitle.
 */
@property (nonatomic, strong) NSString *subtitle;

@end
