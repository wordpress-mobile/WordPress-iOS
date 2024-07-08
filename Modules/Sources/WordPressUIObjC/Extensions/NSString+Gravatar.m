#import "NSString+Gravatar.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (Gravatar)

- (NSString *)sha256Hash
{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(cStr, (CC_LONG)strlen(cStr), result);

    NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x",result[i]];
    }
    return hashString;
}

@end
