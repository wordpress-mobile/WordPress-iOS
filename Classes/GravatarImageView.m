//
//  GravatarImageView.m
//  WordPress
//
//  Created by Josh Bassett on 16/07/09.
//

#import "GravatarImageView.h"

#import <CommonCrypto/CommonDigest.h>

#define GRAVATAR_DEFAULT_IMAGE  @"gravatar.jpg"
#define GRAVATAR_IMAGE_RADIUS   10
#define GRAVATAR_URL            @"http://www.gravatar.com/avatar/%@s=80?d=404"


@interface GravatarImageView (Private)

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float radius);
- (UIImage *)newRoundCornerImage:(UIImage *)image radius:(int)radius;
- (NSURL *)gravatarURLForEmail:(NSString *)emailString;
NSString *md5(NSString *str);

@end


@implementation GravatarImageView

@synthesize email;

#pragma mark Memory Management

- (void)dealloc {
    if (email) {
        [email release];
    }

    [super dealloc];
}

- (void)setEmail:(NSString *)value {
    email = [NSString stringWithString:value];
    NSURL *url = [self gravatarURLForEmail:email];
    [self loadImageFromURL:url];
}

#pragma mark -
#pragma mark Public Methods

- (void)setImage:(UIImage *)image {
    if (!image) {
        image = [UIImage imageNamed:GRAVATAR_DEFAULT_IMAGE];
    }

    image = [self newRoundCornerImage:image radius:GRAVATAR_IMAGE_RADIUS];
    [super setImage:image];
    [image release];
}

#pragma mark -
#pragma mark Private Methods

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float radius) {
    if (radius == 0) {
        CGContextAddRect(context, rect);
    } else {
        float width = CGRectGetWidth(rect) / radius;
        float height = CGRectGetHeight(rect) / radius;
        
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextScaleCTM(context, radius, radius);
        CGContextMoveToPoint(context, width, height / 2);
        CGContextAddArcToPoint(context, width, height, width / 2, height, 1);
        CGContextAddArcToPoint(context, 0, height, 0, height / 2, 1);
        CGContextAddArcToPoint(context, 0, 0, width / 2, 0, 1);
        CGContextAddArcToPoint(context, width, 0, width, height / 2, 1);
        CGContextClosePath(context);
        CGContextRestoreGState(context);
    }
}

- (UIImage *)newRoundCornerImage:(UIImage *)image radius:(int)radius {
    UIImage *newImage = nil;
    
    if (image) {
        int width = image.size.width;
        int height = image.size.height;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedFirst);
        
        CGContextBeginPath(context);
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        addRoundedRectToPath(context, rect, radius);
        CGContextClosePath(context);
        CGContextClip(context);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
        
        CGImageRef imageMasked = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        newImage = [[UIImage imageWithCGImage:imageMasked] retain];
        CGImageRelease(imageMasked);
    }
    
    return newImage;
}

- (NSURL *)gravatarURLForEmail:(NSString *)emailString {
    NSString *emailHash = [md5(emailString) lowercaseString];
    NSString *url = [NSString stringWithFormat:GRAVATAR_URL, emailHash];
    return [NSURL URLWithString:url];
}

NSString *md5(NSString *str) {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, strlen(cStr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

@end
