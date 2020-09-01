#import <UIKit/UIKit.h>

extern const CGFloat PostHeaderViewAvatarSize;

@interface ReaderPostHeaderView : UIView

/**
 A ReaderPostHeaderCallback block to be executed whenever the user pressed this view.
 */
typedef void (^ReaderPostHeaderCallback)(void);
@property (nonatomic, copy) ReaderPostHeaderCallback onClick;

/**
 A ReaderPostHeaderFollowingCallback block to be executed whenever the user pressed this view.
 */
typedef void (^ReaderPostHeaderFollowingCallback)(void);
@property (nonatomic, copy) ReaderPostHeaderFollowingCallback onFollowConversationClick;

/**
 A BOOL indicating whether if this view should display a disclosure indicator, or not.
 */
@property (nonatomic, assign) BOOL showsDisclosureIndicator;

/**
 A BOOL indicating whether if this view should display a follow conversation button, or not.
 */
@property (nonatomic, assign) BOOL showsFollowConversationButton;

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

/**
 A BOOL indicating whether the User is subscribed to the post, or not.
 */
@property (nonatomic, assign, setter=setSubscribedToPost:) BOOL isSubscribedToPost;

@end
