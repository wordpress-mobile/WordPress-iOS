extern NSString *const GravatarRatingG;
extern NSString *const GravatarRatingPG;
extern NSString *const GravatarRatingR;
extern NSString *const GravatarRatingX;

@interface UIImageView (Gravatar)

- (NSURL *)blavatarURLForHost:(NSString *)host;
- (NSURL *)blavatarURLForHost:(NSString *)host withSize:(NSInteger)size;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress gravatarRating:(NSString *)rating;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage;
- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage gravatarRating:(NSString *)rating;
- (void)setImageWithSiteIcon:(NSString *)siteIcon;
- (void)setImageWithSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage;

@end
