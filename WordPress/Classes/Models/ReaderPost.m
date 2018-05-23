#import "ReaderPost.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "SourcePostAttribution.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "WPAvatarSource.h"
#import <WordPressShared/NSString+Util.h>
#import <WordPressShared/NSString+XMLExtensions.h>
#import "WordPress-Swift.h"

// These keys are used in the getStoredComment method
NSString * const ReaderPostStoredCommentIDKey = @"commentID";
NSString * const ReaderPostStoredCommentTextKey = @"comment";

@implementation ReaderPost

@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic siteIconURL;
@dynamic blogName;
@dynamic blogDescription;
@dynamic blogURL;
@dynamic commentCount;
@dynamic commentsOpen;
@dynamic featuredImage;
@dynamic feedID;
@dynamic feedItemID;
@dynamic isBlogPrivate;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic isWPCom;
@dynamic likeCount;
@dynamic score;
@dynamic siteID;
@dynamic sortRank;
@dynamic sortDate;
@dynamic summary;
@dynamic comments;
@dynamic tags;
@dynamic topic;
@dynamic globalID;
@dynamic isLikesEnabled;
@dynamic isSharingEnabled;
@dynamic isSiteBlocked;
@dynamic sourceAttribution;
@dynamic isSavedForLater;

@dynamic primaryTag;
@dynamic primaryTagSlug;
@dynamic isExternal;
@dynamic isJetpack;
@dynamic wordCount;
@dynamic readingTime;
@dynamic crossPostMeta;
@dynamic railcar;
@dynamic inUse;

@synthesize rendered;


- (BOOL)isCrossPost
{
    return self.crossPostMeta != nil;
}

- (BOOL)isPrivate
{
    return self.isBlogPrivate;
}

- (NSString *)authorString
{
    if ([self.authorDisplayName length] > 0) {
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

    // Remove any query string params if needed (e.g. resize values)
    NSUInteger questionMarkLocation = [featuredImage rangeOfString:@"?" options:NSBackwardsSearch].location;
    if (questionMarkLocation != NSNotFound) {
        featuredImage = [featuredImage substringToIndex:questionMarkLocation];
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

#pragma mark - PostContentProvider protocol

- (NSString *)blogNameForDisplay
{
    if (self.blogName.length > 0) {
        return self.blogName;
    }
    return [[NSURL URLWithString:self.blogURL] host];
}

- (NSURL *)siteIconForDisplayOfSize:(NSInteger)size
{
    NSString *str;
    if ([self.siteIconURL length] > 0) {
        if ([self.siteIconURL rangeOfString:@"/blavatar/"].location == NSNotFound) {
            str = self.siteIconURL;
        } else {
            str = [NSString stringWithFormat:@"%@?s=%d&d=404", self.siteIconURL, size];
        }
        return [NSURL URLWithString:str];
    }
    return nil;
}

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
    return [self dateCreated];
}

- (NSString *)contentPreviewForDisplay
{
    return self.summary;
}

- (NSURL *)featuredImageURLForDisplay
{
    return [self featuredImageURL];
}

- (NSString *)likeCountForDisplay
{
    NSString *likeStr = NSLocalizedString(@"Like", @"Text for the 'like' button. Tapping marks a post in the reader as 'liked'.");
    NSString *likesStr = NSLocalizedString(@"Likes", @"Text for the 'like' button. Tapping removes the 'liked' status from a post.");

    NSInteger count = [self.likeCount integerValue];
    NSString *title;
    if (count == 0) {
        title = likeStr;
    } else if (count == 1) {
        title = [NSString stringWithFormat:@"%d %@", count, likeStr];
    } else {
        title = [NSString stringWithFormat:@"%d %@", count, likesStr];
    }

    return title;
}

- (SourceAttributionStyle)sourceAttributionStyle
{
    if ([self.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypePost]) {
        return SourceAttributionStylePost;
    } else if ([self.sourceAttribution.attributionType isEqualToString:SourcePostAttributionTypeSite]) {
        return SourceAttributionStyleSite;
    } else {
        return SourceAttributionStyleNone;
    }
}

- (NSString *)sourceAuthorNameForDisplay
{
    return self.sourceAttribution.authorName;
}

- (NSURL *)sourceAuthorURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.authorURL];
}

- (NSURL *)sourceAvatarURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.avatarURL];
}

- (NSString *)sourceBlogNameForDisplay
{
    return self.sourceAttribution.blogName;
}

- (NSURL *)sourceBlogURLForDisplay
{
    if (!self.sourceAttribution) {
        return nil;
    }
    return [NSURL URLWithString:self.sourceAttribution.blogURL];
}

- (BOOL)isSourceAttributionWPCom
{
    return (self.sourceAttribution.blogID) ? YES : NO;
}

- (NSURL *)avatarURLForDisplay
{
    return [NSURL URLWithString:self.authorAvatarURL];
}

- (NSString *)siteURLForDisplay
{
    return self.blogURL;
}

- (NSString *)crossPostOriginSiteURLForDisplay
{
    return self.crossPostMeta.siteURL;
}

- (BOOL)isCommentCrossPost
{
    return self.crossPostMeta.commentURL.length > 0;
}

- (NSDictionary *)railcarDictionary
{
    if (!self.railcar) {
        return nil;
    }

    NSData *jsonData = [self.railcar dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)jsonObj;
    }
    return nil;
}

@end
