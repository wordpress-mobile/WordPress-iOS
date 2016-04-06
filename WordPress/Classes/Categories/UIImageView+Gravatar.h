#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


#pragma mark - Constants

extern NSString *const GravatarRatingG;
extern NSString *const GravatarRatingPG;
extern NSString *const GravatarRatingR;
extern NSString *const GravatarRatingX;

@interface UIImageView (Gravatar)

#pragma mark - Gravatar Helpers

- (void)setImageWithGravatarEmail:(NSString *)emailAddress;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress gravatarRating:(NSString *)rating;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage gravatarRating:(NSString *)rating;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage gravatarRating:(NSString *)rating policy:(NSURLRequestCachePolicy)policy;
- (void)cacheGravatarImage:(UIImage *)gravatar gravatarRating:(NSString *)rating emailAddress:(NSString *)emailAddress;

#pragma mark - Site Icon Helpers

- (void)setImageWithSiteIcon:(NSString *)siteIcon;
- (void)setImageWithSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage;

#pragma mark - Blavatar Helpers

- (NSURL *)blavatarURLForHost:(NSString *)host;
- (NSURL *)blavatarURLForHost:(NSString *)host withSize:(NSInteger)size;

@end
