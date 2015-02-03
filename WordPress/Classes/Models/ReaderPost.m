#import "ReaderPost.h"
#import "WordPressComApi.h"
#import "NSString+Helpers.h"
#import "NSString+Util.h"
#import "NSString+XMLExtensions.h"
#import "WPAvatarSource.h"
#import "NSString+Helpers.h"
#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"

// These keys are used in the getStoredComment method
NSString * const ReaderPostStoredCommentIDKey = @"commentID";
NSString * const ReaderPostStoredCommentTextKey = @"comment";

@implementation ReaderPost

@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic blogName;
@dynamic blogDescription;
@dynamic blogURL;
@dynamic commentCount;
@dynamic commentsOpen;
@dynamic dateCommentsSynced;
@dynamic featuredImage;
@dynamic isBlogPrivate;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic isWPCom;
@dynamic likeCount;
@dynamic siteID;
@dynamic sortDate;
@dynamic storedComment;
@dynamic summary;
@dynamic comments;
@dynamic tags;
@dynamic topic;
@dynamic globalID;
@dynamic isLikesEnabled;
@dynamic isSharingEnabled;
@dynamic isSiteBlocked;


- (BOOL)isPrivate
{
    return self.isBlogPrivate;
}

- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment
{
    self.storedComment = [NSString stringWithFormat:@"%i|storedcomment|%@", [commentID integerValue], comment];
}

- (NSDictionary *)getStoredComment
{
    if (!self.storedComment) {
        return nil;
    }

    NSArray *arr = [self.storedComment componentsSeparatedByString:@"|storedcomment|"];
    NSNumber *commentID = [[arr objectAtIndex:0] numericValue];
    NSString *commentText = [arr objectAtIndex:1];
    return @{ReaderPostStoredCommentIDKey:commentID, ReaderPostStoredCommentTextKey:commentText};
}

- (NSString *)authorString
{
    if ([self.blogName length] > 0) {
        return self.blogName;
    } else if ([self.authorDisplayName length] > 0) {
        return self.authorDisplayName;
    }

    return self.author;
}

- (NSString *)avatar
{
    return self.authorAvatarURL;
}

- (UIImage *)cachedAvatarWithSize:(CGSize)size
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];

    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash
{
    if (self.authorAvatarURL) {
        NSURL *avatarURL = [NSURL URLWithString:self.authorAvatarURL];
        if (avatarURL) {
            return [[WPAvatarSource sharedSource] parseURL:avatarURL forAvatarHash:hash];
        }
    }
    if (self.blogURL) {
        *hash = [[[NSURL URLWithString:self.blogURL] host] md5];
        return WPAvatarSourceTypeBlavatar;
    }
    return WPAvatarSourceTypeUnknown;
}

- (NSURL *)featuredImageURL
{
    if ([self.featuredImage length]) {
        return [NSURL URLWithString:self.featuredImage];
    }
    return nil;
}

- (BOOL)contentIncludesFeaturedImage
{
    NSURL *featuredImageURL = [self featuredImageURL];
    NSString *featuredImage = [featuredImageURL absoluteString];
    if (!featuredImage) {
        return NO;
    }

    // One URL might be http and the other https, so don't include the protocol in the check.
    NSString *scheme = [featuredImageURL scheme];
    if ([scheme length]) {
        NSInteger index = [scheme length] + 3; // protocol + ://
        featuredImage = [featuredImage substringFromIndex:index];
    }

    NSString *content = [self contentForDisplay];
    return ([content rangeOfString:featuredImage].location != NSNotFound);
}

#pragma mark - WPContentViewProvider protocol

- (NSString *)titleForDisplay
{
    NSString *title = [[self.postTitle trim] stringByDecodingXMLCharacters];
    if (!title) {
        title = @"";
    }
    return title;
}

- (NSString *)authorForDisplay
{
    return [self authorString];
}

- (NSDate *)dateForDisplay
{
    return [self sortDate];
}

- (NSString *)contentPreviewForDisplay
{
    return self.summary;
}

- (NSURL *)featuredImageURLForDisplay
{
    return [self featuredImageURL];
}


@end
