#import "AbstractPost+HashHelpers.h"
#import "Media+WPMediaAsset.h"

@implementation AbstractPost (HashHelpers)

- (NSString *)changesConfirmedContentHashValue {
    // The list of the properties we're taking into account here broadly mirrors: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/f9e7fbae2479ad71bd2d1c7039f6f2bbbcc9444d/fluxc/src/main/java/org/wordpress/android/fluxc/model/PostModel.java#L443-L473
    // Note that some of the properties aren't found on `AbstractPost`, but rather on `Post` and/or `Page` —
    // that's the purpose of the `-additionalContentHashes` extension point.

    NSArray<NSData *> *hashedContents = @[
                                          [self hashForNSInteger:self.blog.dotComID.integerValue],
                                          [self hashForNSInteger:self.postID.integerValue],
                                          [self hashForString:self.postTitle],
                                          [self hashForString:self.content],
                                          [self hashForDouble:self.dateCreated.timeIntervalSinceReferenceDate],
                                          [self hashForString:self.permaLink],
                                          [self hashForString:self.mt_excerpt],
                                          [self hashForString:self.statusForDisplay],
                                          [self hashForNSInteger:self.remoteStatusNumber.integerValue],
                                          [self hashForString:self.password],
                                          [self hashForString:self.author],
                                          [self hashForString:self.featuredImage.identifier],
                                          [self hashForString:self.wp_slug]];


    NSArray<NSData *> *finalHashes = [hashedContents arrayByAddingObjectsFromArray:self.additionalContentHashes];

    NSMutableData *mutableData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];

    for (NSData *hash in finalHashes) {
        const char *finalHashBytes = [mutableData bytes];
        const char *currentIterationHashBytes = [hash bytes];

        for (int i = 0; i < mutableData.length; i++) {
            const char xorByte = finalHashBytes[i] ^ currentIterationHashBytes[i];
            [mutableData replaceBytesInRange:NSMakeRange(i, 1) withBytes:&xorByte];
        }
    }

    return [self sha256StringFromData:mutableData];
}


- (NSArray<NSData *> *)additionalContentHashes {
    return @[];
}

#pragma mark - SHA512 calculations

- (NSData *)hashForString:(NSString *) string {
    if (!string) {
        return [[NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH] copy];
    }

    NSData *encodedBytes = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(encodedBytes.bytes, (CC_LONG)encodedBytes.length, digest);

    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *)hashForNSInteger:(NSInteger)integer {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(&integer, sizeof(integer), digest);

    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

- (NSData *)hashForDouble:(double)dbl {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(&dbl, sizeof(dbl), digest);

    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

- (NSString *)sha256StringFromData:(NSData *)data {
    NSMutableString *mutableString = [NSMutableString string];

    const char *hashBytes = [data bytes];

    for (int i = 0; i < data.length; i++) {
        [mutableString appendFormat:@"%02.2hhx", hashBytes[i]];
    }

    return [mutableString copy];
}

@end
