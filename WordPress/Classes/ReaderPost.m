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

@dynamic authorAvatarURL;
@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic blogName;
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

- (BOOL)isFollowable {
    // TODO: We can improve this check. Make sure that this includes jetpack blogs but not feedbag blogs
    return self.isWPCom;
}

- (BOOL)isPrivate {
    return self.isBlogPrivate;
}

- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment {
    self.storedComment = [NSString stringWithFormat:@"%i|storedcomment|%@", [commentID integerValue], comment];
}

- (NSDictionary *)getStoredComment {
    if (!self.storedComment) {
        return nil;
    }
    
    NSArray *arr = [self.storedComment componentsSeparatedByString:@"|storedcomment|"];
    NSNumber *commentID = [[arr objectAtIndex:0] numericValue];
    NSString *commentText = [arr objectAtIndex:1];
    return @{ReaderPostStoredCommentIDKey:commentID, ReaderPostStoredCommentTextKey:commentText};
}

- (NSString *)authorString {
    if ([self.blogName length] > 0) {
        return self.blogName;
    } else if ([self.authorDisplayName length] > 0) {
        return self.authorDisplayName;
    } else {
        return self.author;
    }
}

- (NSString *)avatar {
    return self.authorAvatarURL;
}

- (UIImage *)cachedAvatarWithSize:(CGSize)size {
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success {
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];

    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash {
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

- (NSURL *)featuredImageURL {
    if (self.featuredImage && [self.featuredImage length] > 0) {
        return [NSURL URLWithString:self.featuredImage];
    }

    return nil;
}

- (NSString *)featuredImageForWidth:(NSUInteger)width height:(NSUInteger)height {
    NSString *fmt = nil;
    if ([self.featuredImage rangeOfString:@"mshots/"].location == NSNotFound) {
        fmt = @"https://i0.wp.com/%@?resize=%i,%i";
    } else {
        fmt = @"%@?w=%i&h=%i";
    }
    return [NSString stringWithFormat:fmt, self.featuredImage, width, height];
}

#pragma mark - WPContentViewProvider protocol

- (NSDate *)dateForDisplay {
    return [self sortDate];
}

@end


@implementation ReaderPost (WordPressComApi)

+ (void)getCommentsForPost:(NSUInteger)postID
                  fromSite:(NSString *)siteID
            withParameters:(NSDictionary*)params
                   success:(WordPressComApiRestSuccessResponseBlock)success
                   failure:(WordPressComApiRestSuccessFailureBlock)failure {
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%i/replies", siteID, postID];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if ([defaultAccount restApi].authToken) {
        [[defaultAccount restApi] GET:path parameters:params success:success failure:failure];
    } else {
        [[WordPressComApi anonymousApi] GET:path parameters:params success:success failure:failure];
    }
}

@end
