#import "UIImageView+Gravatar.h"

#import "Constants.h"
#import "NSString+Helpers.h"
#import "UIImageView+AFNetworking.h"
#import "WordPress-Swift.h"


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
    if ([WPImageURLHelper isPhotonURL:siteIcon]) {
        [self setImageWithURL:[WPImageURLHelper siteIconURLForSiteIconURL:siteIcon size:[self sizeForBlavatarDownload]] placeholderImage:placeholderImage];
    } else if ([WPImageURLHelper isBlavatarURL:siteIcon]) {
        [self setImageWithURL:[WPImageURLHelper blavatarURLForBlavatarURL:siteIcon size:[self sizeForBlavatarDownload]] placeholderImage:placeholderImage];
    } else {
        [self setImageWithURL:[WPImageURLHelper blavatarURLForHost:siteIcon size:[self sizeForBlavatarDownload]] placeholderImage:placeholderImage];
    }
}


#pragma mark - Blavatar Private Methods

- (NSInteger)sizeForBlavatarDownload
{
    NSInteger size = BlavatarDefaultSize;
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        size = MAX(self.bounds.size.width, self.bounds.size.height);
    }

    size *= [[UIScreen mainScreen] scale];

    return size;
}

@end
