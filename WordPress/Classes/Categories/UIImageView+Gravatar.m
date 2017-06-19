#import "UIImageView+Gravatar.h"
#import "UIImageView+AFNetworking.h"
#import "NSString+Helpers.h"
#import "Constants.h"
#import "PhotonImageURLHelper.h"
#import "PrivateSiteURLProtocol.h"


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
    [self setImageWithURL:[self URLWithSiteIcon:siteIcon] placeholderImage:placeholderImage];
}

- (void)setImageWithSiteIconForBlog:(Blog *)blog
{
    UIImage *blavatarDefaultImage = [UIImage imageNamed:BlavatarDefault];

    [self setImageWithSiteIconForBlog:blog placeholderImage:blavatarDefaultImage];
}

- (void)setImageWithSiteIconForBlog:(Blog *)blog placeholderImage:(UIImage *)placeholderImage
{
    if (blog.isHostedAtWPcom && blog.isPrivate) {
        [self setImageWithPrivateSiteIcon:blog.icon placeholderImage:placeholderImage];
    } else {
        [self setImageWithSiteIcon:blog.icon placeholderImage:placeholderImage];
    }
}

- (void)setDefaultSiteIconImage
{
    self.image = [UIImage imageNamed:BlavatarDefault];
}

#pragma mark - Site Icon Private Methods

- (NSURL *)URLWithSiteIcon:(NSString *)siteIcon
{
    if ([self isPhotonURL:siteIcon] || [self isWordPressComFilesURL:siteIcon]) {
        return [self siteIconURLForSiteIconUrl:siteIcon];
    } else if ([self isBlavatarURL:siteIcon]) {
        return [self blavatarURLForBlavatarURL:siteIcon];
    } else {
        return [self URLForResizedImageURL:siteIcon];
    }
}

- (NSURL *)siteIconURLForSiteIconUrl:(NSString *)path
{
    NSInteger size = [self sizeForBlavatarDownload];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:path];
    urlComponents.query = [NSString stringWithFormat:@"w=%d&h=%d", size, size];
    return urlComponents.URL;
}

- (void)setImageWithPrivateSiteIcon:(NSString *)siteIcon placeholderImage:(UIImage *)placeholderImage
{
    NSURLRequest *imageRequest = [PrivateSiteURLProtocol requestForPrivateSiteFromURL:[self URLWithSiteIcon:siteIcon]];
    [self setImageWithURLRequest:imageRequest
                placeholderImage:placeholderImage
                         success:nil
                         failure:nil];
}

#pragma mark - Photon Helpers

- (nullable NSURL *)URLForResizedImageURL:(NSString *)urlString
{
    CGSize size = CGSizeMake(BlavatarDefaultSize, BlavatarDefaultSize);
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return nil;
    }
    return [PhotonImageURLHelper photonURLWithSize:size forImageURL:url];
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
