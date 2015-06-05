#import "UIImageView+Gravatar.h"
#import "UIImageView+AFNetworking.h"
#import "NSString+Helpers.h"

NSInteger const BlavatarDefaultSize = 40;
NSInteger const GravatarDefaultSize = 80;

NSString *const BlavatarBaseUrl = @"http://gravatar.com/blavatar";
NSString *const GravatarBaseUrl = @"http://gravatar.com/avatar";

NSString *const BlavatarDefault = @"blavatar-default";
NSString *const GravatarDefault = @"gravatar.png";

// More information on gravatar ratings: https://en.gravatar.com/site/implement/images/
NSString *const GravatarRatingG = @"g"; // default
NSString *const GravatarRatingPG = @"pg";
NSString *const GravatarRatingR = @"r";
NSString *const GravatarRatingX = @"x";

@implementation UIImageView (Gravatar)

- (void)setImageWithGravatarEmail:(NSString *)emailAddress
{
    [self setImageWithGravatarEmail:emailAddress gravatarRating:GravatarRatingG];
}

- (void)setImageWithGravatarEmail:(NSString *)emailAddress gravatarRating:(NSString *)rating
{
    static UIImage *gravatarDefaultImage;
    if (gravatarDefaultImage == nil) {
        gravatarDefaultImage = [UIImage imageNamed:GravatarDefault];
    }

    [self setImageWithURL:[self gravatarURLForEmail:emailAddress gravatarRating:rating] placeholderImage:gravatarDefaultImage];
}

- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage
{
    [self setImageWithGravatarEmail:emailAddress fallbackImage:fallbackImage gravatarRating:GravatarRatingG];
}

- (void)setImageWithGravatarEmail:(NSString *)emailAddress fallbackImage:(UIImage *)fallbackImage gravatarRating:(NSString *)rating
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self gravatarURLForEmail:emailAddress gravatarRating:rating]];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    __weak UIImageView *weakSelf = self;
    [self setImageWithURLRequest:request placeholderImage:fallbackImage success:nil failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
        weakSelf.image = fallbackImage;
    }];
}

- (void)setImageWithSiteIcon:(NSString *)siteIcon
{
    UIImage *blavatarDefaultImage = [UIImage imageNamed:BlavatarDefault];

    [self setImageWithSiteIcon:siteIcon placeholderImage:blavatarDefaultImage];
}

- (void)setImageWithSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage
{
    if ([self isPhotonURL:siteIcon]) {
        [self setImageWithURL:[self siteIconURLForSiteIconUrl:siteIcon] placeholderImage:placeholderImage];
    } else if ([siteIcon rangeOfString:@"gravatar.com/blavatar"].location != NSNotFound) {
        [self setImageWithURL:[self blavatarURLForBlavatarURL:siteIcon] placeholderImage:placeholderImage];
    } else {
        [self setImageWithURL:[self blavatarURLForHost:siteIcon] placeholderImage:placeholderImage];
    }
}

- (NSURL *)gravatarURLForEmail:(NSString *)email gravatarRating:(NSString *)rating
{
    return [self gravatarURLForEmail:email withSize:[self sizeForGravatarDownload] gravatarRating:rating];
}

- (NSURL *)gravatarURLForEmail:(NSString *)email withSize:(NSInteger)size gravatarRating:(NSString *)rating
{
    // fallback to "G" rating
    if (!rating) {
        rating = GravatarRatingG;
    }
    NSString *gravatarUrl = [NSString stringWithFormat:@"%@/%@?d=404&s=%d&r=%@", GravatarBaseUrl, [email md5], size, rating];
    return [NSURL URLWithString:gravatarUrl];
}

- (NSURL *)siteIconURLForSiteIconUrl:(NSString *)path
{
    NSInteger size = [self sizeForBlavatarDownload];
    NSString *siteIconUrl = [NSString stringWithFormat:@"%@?w=%d&h=%d", path, size, size];
    return [NSURL URLWithString:siteIconUrl];
}

- (NSURL *)blavatarURLForHost:(NSString *)host
{
    return [self blavatarURLForHost:host withSize:[self sizeForBlavatarDownload]];
}

- (NSURL *)blavatarURLForHost:(NSString *)host withSize:(NSInteger)size
{
    NSString *blavatarUrl = [NSString stringWithFormat:@"%@/%@?d=404&s=%d", BlavatarBaseUrl, [host md5], size];
    return [NSURL URLWithString:blavatarUrl];
}

- (NSURL *)blavatarURLForBlavatarURL:(NSString *)path
{
    NSInteger size = [self sizeForBlavatarDownload];
    NSString *blavatarURL = [NSString stringWithFormat:@"%@?d=404&s=%d", path, size];
    return [NSURL URLWithString:blavatarURL];
}

- (NSInteger)sizeForGravatarDownload
{
    NSInteger size = GravatarDefaultSize;
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        size = MAX(self.bounds.size.width, self.bounds.size.height);
    }

    size *= [[UIScreen mainScreen] scale];

    return size;
}

- (NSInteger)sizeForBlavatarDownload
{
    NSInteger size = BlavatarDefaultSize;
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        size = MAX(self.bounds.size.width, self.bounds.size.height);
    }

    size *= [[UIScreen mainScreen] scale];

    return size;
}

// Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
- (BOOL)isPhotonURL:(NSString *)path
{
    return [path rangeOfString:@".wp.com"].location != NSNotFound;
}

@end
