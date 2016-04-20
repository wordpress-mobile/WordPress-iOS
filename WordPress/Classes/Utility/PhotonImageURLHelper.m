#import "PhotonImageURLHelper.h"

@implementation PhotonImageURLHelper

static const NSUInteger DefaultPhotonImageQuality = 80;
static const NSInteger MaxPhotonImageQuality = 100;
static const NSInteger MinPhotonImageQuality = 1;

+ (NSURL *)photonURLWithSize:(CGSize)size forImageURL:(NSURL *)url
{
    return [self photonURLWithSize:size forImageURL:url forceResize:YES imageQuality:DefaultPhotonImageQuality];
}

+ (NSURL *)photonURLWithSize:(CGSize)size forImageURL:(NSURL *)url forceResize:(BOOL)forceResize imageQuality:(NSUInteger)quality
{
    // Photon will fail if the URL doesn't end in one of the accepted extensions
    NSArray *acceptedImageTypes = @[@"gif", @"jpg", @"jpeg", @"png"];
    if ([acceptedImageTypes indexOfObject:url.pathExtension] == NSNotFound) {
        if (![url scheme]) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
        }
        return url;
    }

    NSString *urlString = [url absoluteString];
    CGFloat scale = [[UIScreen mainScreen] scale];
    size.width *= scale;
    size.height *= scale;
    quality = MIN(MAX(quality, MinPhotonImageQuality), MaxPhotonImageQuality);

    // If the URL is already a Photon URL reject its photon params, and substitute our own.
    if ([self isURLPhotonURL:url]) {
        NSRange range = [urlString rangeOfString:@"?" options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            BOOL useSSL = ([urlString rangeOfString:@"ssl=1"].location != NSNotFound);
            urlString = [urlString substringToIndex:range.location];
            NSString *queryString = [self photonQueryStringForSize:size usingSSL:useSSL forceResize:forceResize quality:quality];
            urlString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
            return [NSURL URLWithString:urlString];
        }
        // Saftey net. Don't photon photon!
        return url;
    }

    // Compose the URL
    NSRange range = [urlString rangeOfString:@"://"];
    if (range.location != NSNotFound && range.location < 6) {
        urlString = [urlString substringFromIndex:(range.location + range.length)];
    }

    // Photon rejects resizing mshots
    if ([urlString rangeOfString:@"/mshots/"].location != NSNotFound) {
        if (size.height == 0) {
            urlString = [urlString stringByAppendingFormat:@"?w=%i", size.width];
        } else {
            urlString = [urlString stringByAppendingFormat:@"?w=%i&h=%i", size.width, size.height];
        }
        return [NSURL URLWithString:urlString];
    }

    // Strip original resizing parameters, or we might get an image too small
    NSRange imgpressRange = [urlString rangeOfString:@"?w="];
    if (imgpressRange.location != NSNotFound) {
        urlString = [urlString substringToIndex:imgpressRange.location];
    }

    BOOL useSSL = [[url scheme] isEqualToString:@"https"];
    NSString *queryString = [self photonQueryStringForSize:size usingSSL:useSSL forceResize:forceResize quality:quality];
    NSString *photonURLString = [NSString stringWithFormat:@"https://i0.wp.com/%@?%@", urlString, queryString];
    return [NSURL URLWithString:photonURLString];
}

/**
 Constructs a Photon query string from the  supplied parameters.
 */
+ (NSString *)photonQueryStringForSize:(CGSize)size usingSSL:(BOOL)useSSL forceResize:(BOOL)forceResize quality:(NSUInteger)quality
{
    NSString *queryString;
    if (size.height == 0) {
        queryString = [NSString stringWithFormat:@"w=%i", size.width];
    } else {
        NSString *method = forceResize ? @"resize" : @"fit";
        queryString = [NSString stringWithFormat:@"%@=%.0f,%.0f", method, size.width, size.height];
    }

    if (useSSL) {
        queryString = [NSString stringWithFormat:@"%@&ssl=1", queryString];
    }

    queryString = [NSString stringWithFormat:@"quality=%d&%@", quality, queryString];
    
    return queryString;
}

/**
 Inspects the specified URL to see if its uses Photon.
 
 @return True if the URL is a photon URL. False otherwise.
 */
+ (BOOL)isURLPhotonURL:(NSURL *)url
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"i\\d+\\.wp\\.com" options:NSRegularExpressionCaseInsensitive error:&error];
    });
    NSString *host = [url host];
    if ([host length] > 0) { // relative URLs may not have a host
        NSInteger count = [regex numberOfMatchesInString:host options:NSMatchingCompleted range:NSMakeRange(0, [host length])];
        if (count > 0) {
            return YES;
        }
    }
    return NO;
}

@end
