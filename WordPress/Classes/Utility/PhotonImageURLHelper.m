#import "PhotonImageURLHelper.h"

@implementation PhotonImageURLHelper

+ (NSURL *)photonURLWithSize:(CGSize)size forImageURL:(NSURL *)url
{
    NSString *imagePath = [NSString stringWithFormat:@"%@%@", url.host, url.path];
    NSString *queryStr = [NSString stringWithFormat:@"resize=%.f,%.f&quality=80", size.width, size.height];
    NSString *photonStr = [NSString stringWithFormat:@"https://i0.wp.com/%@?%@", imagePath, queryStr];
    return [NSURL URLWithString:photonStr];
}

@end
