#import "AbstractPost.h"

NS_ASSUME_NONNULL_BEGIN

@interface AbstractPost (HashHelpers)

// This value is used in Offline Posting — to calculate whether the post that the user _wanted_ to publish,
// hasn't changed in the meantime and still is the same post.
// It works by calculating a SHA256 hash for a subset of properties of a Post and then combining them together (including the hashes returned by the `additionalContentHashes` method, to let subclasses provide additional sources of truthfulness).
- (NSString *)calculateConfirmedChangesContentHash;

// This is an extension point for the subclasses to add additional sources of truthfulness.
- (NSArray<NSData *> *)additionalContentHashes;


- (NSData *)hashForString:(NSString *)string;
- (NSData *)hashForNSInteger:(NSInteger)integer;
- (NSData *)hashForDouble:(double)dbl;

@end

NS_ASSUME_NONNULL_END
