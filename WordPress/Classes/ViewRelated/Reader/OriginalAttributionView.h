#import <UIKit/UIKit.h>

@interface OriginalAttributionView : UIView

/**
 Resets the view. 
 Clears the avatar image and the text shown.
 */
- (void)reset;

/**
 Sets the author and blog information for the Editor Pick attribution style
 */
- (void)setPostAttributionWithGravatar:(NSURL *)avatarURL
                             forAuthor:(NSString *)authorName
                                  blog:(NSString *)blogName;

/**
 Sets the blog information for the Site Pick attribution style
 */
- (void)setSiteAttributionWithBlavatar:(NSURL *)blavatarURL
                               forBlog:(NSString *)blogName;
@end
