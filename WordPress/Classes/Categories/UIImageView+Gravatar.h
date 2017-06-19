#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Blog.h"

@interface UIImageView (Gravatar)

#pragma mark - Site Icon Helpers

- (void)setImageWithSiteIcon:(NSString *)siteIcon;
- (void)setImageWithSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage;
- (void)setImageWithSiteIconForBlog:(Blog *)blog;
- (void)setImageWithSiteIconForBlog:(Blog *)blog placeholderImage:(UIImage *)placeholderImage;
- (void)setDefaultSiteIconImage;

@end
