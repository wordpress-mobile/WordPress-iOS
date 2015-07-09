#import <UIKit/UIKit.h>

@protocol OriginalAttributionViewDelegate;

@interface OriginalAttributionView : UIView

@property (nonatomic, weak) id<OriginalAttributionViewDelegate>delegate;

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
                             authorURL:(NSURL *)authorURL
                                  blog:(NSString *)blogName
                               blogURL:(NSURL *)blogURL;

/**
 Sets the blog information for the Site Pick attribution style
 */
- (void)setSiteAttributionWithBlavatar:(NSURL *)blavatarURL
                               forBlog:(NSString *)blogName
                               blogURL:(NSURL *)blogURL;
@end

@protocol OriginalAttributionViewDelegate <NSObject>
@optional
- (void)originalAttributionView:(OriginalAttributionView *)view
              didTapLink:(NSURL *)link;
@end
