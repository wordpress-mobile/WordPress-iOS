#import <UIKit/UIKit.h>

extern const CGFloat PostHeaderViewAvatarSize;

@interface ReaderPostHeaderView : UIView

/**
 Set's the image to display as the avatar.

 @param image A UIImage with a width and height equal to `WPContentAttributionViewAvatarSize`
 */
- (void)setAvatarImage:(UIImage *)image;

/**
 Set's the title to display.

 @param image A UIImage with a width and height equal to `WPContentAttributionViewAvatarSize`
 */
- (void)setTitle:(NSString *)title;

/**
 Set's the title to display.

 @param image A UIImage with a width and height equal to `WPContentAttributionViewAvatarSize`
 */
- (void)setSubtitle:(NSString *)title;

@end
