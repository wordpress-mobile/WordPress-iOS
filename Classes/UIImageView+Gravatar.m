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

#define BLAVATAR_DEFAULT_IMAGE_WPORG @"blavatar-wporg.png"
#define BLAVATAR_DEFAULT_IMAGE_WPCOM @"blavatar-wpcom.png"
#define BLAVATAR_URL @"http://gravatar.com/blavatar/%@?s=86&d=404"

#define GRAVATAR_DEFAULT_IMAGE  @"gravatar.jpg"
#define GRAVATAR_URL            @"http://www.gravatar.com/avatar/%@?s=160&d=404"

@implementation UIImageView (Gravatar)

- (void)setImageWithGravatarEmail:(NSString *)emailAddress {
    static UIImage *gravatarDefaultImage;
    if (gravatarDefaultImage == nil) {
        gravatarDefaultImage = [UIImage imageNamed:GRAVATAR_DEFAULT_IMAGE];
    }

    NSURL *emailURL = [NSURL URLWithString:[NSString stringWithFormat:GRAVATAR_URL, [[emailAddress lowercaseString] md5]]];

    [self setImageWithURL:emailURL placeholderImage:gravatarDefaultImage];
}

- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl {
    BOOL wpcom = ([blavatarUrl rangeOfString:@".wordpress.com"].location != NSNotFound);
    [self setImageWithBlavatarUrl:blavatarUrl isWPcom:wpcom];
}

- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl isWPcom:(BOOL)wpcom {
    static UIImage *blavatarDefaultImageWPcom;
    static UIImage *blavatarDefaultImageWPorg;
    if (blavatarDefaultImageWPcom == nil) {
        blavatarDefaultImageWPcom = [UIImage imageNamed:BLAVATAR_DEFAULT_IMAGE_WPCOM];
    }
    if (blavatarDefaultImageWPorg == nil) {
        blavatarDefaultImageWPorg = [UIImage imageNamed:BLAVATAR_DEFAULT_IMAGE_WPORG];
    }
    
    UIImage *placeholderImage;
    if (wpcom) {
        placeholderImage = blavatarDefaultImageWPcom;
    } else {
        placeholderImage = blavatarDefaultImageWPorg;
    }
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:BLAVATAR_URL, [blavatarUrl md5]]];
    [self setImageWithURL:imageURL placeholderImage:placeholderImage];    
}

@end
