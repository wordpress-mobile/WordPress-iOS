//
//  UIImageView+Gravatar.m
//  WordPress
//
//  Created by Jorge Bernal on 11/4/11.
//  Copyright (c) 2011 WordPress. All rights reserved.
//

#import "UIImageView+Gravatar.h"
#import "UIImageView+AFNetworking.h"
#import "NSString+Helpers.h"

NSInteger const BlavatarDefaultSize = 86;
NSInteger const GravatarDefaultSize = 160;

NSString *const BlavatarBaseUrl = @"http://gravatar.com/blavatar";
NSString *const GravatarBaseUrl = @"http://gravatar.com/avatar";

NSString *const BlavatarDefaultWporg = @"blavatar-wporg.png";
NSString *const BlavatarDefaultWpcom = @"blavatar-wpcom.png";
NSString *const GravatarDefault = @"gravatar.png";

@implementation UIImageView (Gravatar)

- (void)setImageWithGravatarEmail:(NSString *)emailAddress {
    static UIImage *gravatarDefaultImage;
    if (gravatarDefaultImage == nil) {
        gravatarDefaultImage = [UIImage imageNamed:GravatarDefault];
    }

    [self setImageWithURL:[self gravatarURLForEmail:emailAddress] placeholderImage:gravatarDefaultImage];
}

- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl {
    BOOL wpcom = ([blavatarUrl rangeOfString:@".wordpress.com"].location != NSNotFound);
    [self setImageWithBlavatarUrl:blavatarUrl isWPcom:wpcom];
}

- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl isWPcom:(BOOL)wpcom {
    static UIImage *blavatarDefaultImageWPcom;
    static UIImage *blavatarDefaultImageWPorg;
    if (blavatarDefaultImageWPcom == nil) {
        blavatarDefaultImageWPcom = [UIImage imageNamed:BlavatarDefaultWpcom];
    }
    if (blavatarDefaultImageWPorg == nil) {
        blavatarDefaultImageWPorg = [UIImage imageNamed:BlavatarDefaultWporg];
    }
    
    UIImage *placeholderImage;
    if (wpcom) {
        placeholderImage = blavatarDefaultImageWPcom;
    } else {
        placeholderImage = blavatarDefaultImageWPorg;
    }
    [self setImageWithURL:[self blavatarURLForHost:blavatarUrl] placeholderImage:placeholderImage];
}

- (NSURL *)gravatarURLForEmail:(NSString *)email
{
    return [self gravatarURLForEmail:email withSize:[self sizeForGravatar]];
}

- (NSURL *)gravatarURLForEmail:(NSString *)email withSize:(NSInteger)size
{
    NSString *gravatarUrl = [NSString stringWithFormat:@"%@/%@?d=404&s=%d", GravatarBaseUrl, [email md5], size];
    return [NSURL URLWithString:gravatarUrl];
}

- (NSURL *)blavatarURLForHost:(NSString *)host
{
    return [self blavatarURLForHost:host withSize:[self sizeForBlavatar]];
}

- (NSURL *)blavatarURLForHost:(NSString *)host withSize:(NSInteger)size
{
    NSString *blavatarUrl = [NSString stringWithFormat:@"%@/%@?d=404&s=%d", BlavatarBaseUrl, [host md5], size];
    return [NSURL URLWithString:blavatarUrl];
}

- (NSInteger)sizeForGravatar
{
    NSInteger size = GravatarDefaultSize;
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        size = MAX(self.bounds.size.width, self.bounds.size.height);
        size *= [[UIScreen mainScreen] scale];
    }
    return size;
}

- (NSInteger)sizeForBlavatar
{
    NSInteger size = BlavatarDefaultSize;
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        size = MAX(self.bounds.size.width, self.bounds.size.height);
        size *= [[UIScreen mainScreen] scale];
    }
    return size;
}

@end
