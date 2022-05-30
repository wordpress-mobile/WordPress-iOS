#import "AbstractPost+HashHelpers.h"
#import "Media+WPMediaAsset.h"
#import "WordPress-Swift.h"

@implementation AbstractPost (HashHelpers)

- (NSString *)calculateConfirmedChangesContentHash {
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
                                          [self hashForString:self.status],
                                          [self hashForString:self.password],
                                          [self hashForString:self.author],
                                          [self hashForNSInteger:self.authorID.integerValue],
                                          [self hashForString:self.featuredImage.identifier],
                                          [self hashForString:self.wp_slug]];


    NSArray<NSData *> *finalHashes = [hashedContents arrayByAddingObjectsFromArray:self.additionalContentHashes];

    NSMutableData *mutableData = [NSMutableData data];

    // So, there are multiple ways of combining all those hashes. You need to be careful not to lose the entropy though.
    // Initially, I wanted to just XOR them together, which is totally reasonable thing to do!
    // ...however, things get tricky when you XOR things that might be similar/the same.
    // One important thing to keep in mind here is that a XOR a = 0;
    // e.g. imagine if `self.content` and `self.postTitle` would be both empty strings (most of our users probably don't
    // want to upload such posts, but stick with me for illustrations purposes).
    // If we were to then iterate over the list of hashes and xor them together, then at one point we'd
    // end up doing iteration where the result is 0, reducing the entropy.
    // Now, this _probably_ would be extremely rare and shouldn't _actually_ cause collisions, (
    // but better safe than sorry — tracking down those would be a nightmare.
    // What I'm doing here instead is just treating all the "partial" hashes as a dumb bag of bits,
    // combining them together and the final hash is SHA256 of _that_.
    // Hopefully that'll be enough.

    for (NSData *hash in finalHashes) {
        [mutableData appendData:hash];
    }

    unsigned char finalDigest[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(mutableData.bytes, (CC_LONG)mutableData.length, finalDigest);

    return [self sha256StringFromData:[NSData dataWithBytes:finalDigest length:CC_SHA256_DIGEST_LENGTH]];
}


- (NSArray<NSData *> *)additionalContentHashes {
    return @[];
}

#pragma mark - SHA256 calculations

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
