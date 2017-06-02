#import "UIImageView+Gravatar.h"
#import "UIImageView+AFNetworking.h"
#import "NSString+Helpers.h"
#import "Constants.h"


#pragma mark - Constants

NSInteger const BlavatarDefaultSize = 40;
NSString *const BlavatarDefault = @"blavatar-default";


#pragma mark - UIImageView Helpers

@implementation UIImageView (Gravatar)


#pragma mark - Site Icon Helpers

- (void)setImageWithSiteIcon:(NSString *)siteIcon
{
    UIImage *blavatarDefaultImage = [UIImage imageNamed:BlavatarDefault];

    [self setImageWithSiteIcon:siteIcon placeholderImage:blavatarDefaultImage];
}

- (void)setImageWithSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage
{
    if ([self isPhotonURL:siteIcon] || [self isWordPressComFilesURL:siteIcon]) {
        [self setImageWithURL:[self siteIconURLForSiteIconUrl:siteIcon] placeholderImage:placeholderImage];
    } else if ([self isBlavatarURL:siteIcon]) {
        [self setImageWithURL:[self blavatarURLForBlavatarURL:siteIcon] placeholderImage:placeholderImage];
    } else {
        [self setImageWithURL:[self blavatarURLForHost:siteIcon] placeholderImage:placeholderImage];
    }
}

- (void)setDefaultSiteIconImage
{
    self.image = [UIImage imageNamed:BlavatarDefault];
}

#pragma mark - Site Icon Private Methods

- (NSURL *)siteIconURLForSiteIconUrl:(NSString *)path
{
    NSInteger size = [self sizeForBlavatarDownload];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:path];
    urlComponents.query = [NSString stringWithFormat:@"w=%d&h=%d", size, size];
    return urlComponents.URL;
}


#pragma mark - Blavatar Helpers

- (NSURL *)blavatarURLForHost:(NSString *)host
{
    return [self blavatarURLForHost:host withSize:[self sizeForBlavatarDownload]];
}

- (NSURL *)blavatarURLForHost:(NSString *)host withSize:(NSInteger)size
{
    NSString *blavatarUrl = [NSString stringWithFormat:@"%@/%@?d=404&s=%d", WPBlavatarBaseURL, [host md5], size];
    return [NSURL URLWithString:blavatarUrl];
}


#pragma mark - Blavatar Private Methods

- (NSURL *)blavatarURLForBlavatarURL:(NSString *)path
{
    NSInteger size = [self sizeForBlavatarDownload];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:path];
    urlComponents.query = [NSString stringWithFormat:@"d=404&s=%d", size];
    return urlComponents.URL;
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

- (BOOL)isWordPressComFilesURL:(NSString *)path
{
    return [path containsString:@".files.wordpress.com"];
}

- (BOOL)isBlavatarURL:(NSString *)path
{
    return [path rangeOfString:@"gravatar.com/blavatar"].location != NSNotFound;
}

@end
