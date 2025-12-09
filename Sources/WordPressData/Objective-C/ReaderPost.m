#import "ReaderPost.h"
#import "WPAccount.h"
#import "WordPressData-Swift.h"

@import WordPressKit;
@import WordPressKitModels;
@import WordPressShared;

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
@dynamic isBlogAtomic;
@dynamic isBlogPrivate;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic isWPCom;
@dynamic organizationID;
@dynamic likeCount;
@dynamic score;
@dynamic siteID;
@dynamic sortRank;
@dynamic sortDate;
@dynamic summary;
@dynamic comments;
@dynamic tags;
@dynamic topic;
@dynamic card;
@dynamic globalID;
@dynamic isLikesEnabled;
@dynamic isSharingEnabled;
@dynamic isSiteBlocked;
@dynamic sourceAttribution;
@dynamic isSavedForLater;
@dynamic isSeen;
@dynamic isSeenSupported;
@dynamic isSubscribedComments;
@dynamic canSubscribeComments;
@dynamic receivesCommentNotifications;

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

- (void)didSave {
    [super didSave];

    // A ReaderCard can have either a post, or a list of topics, but not both.
    // Since this card has a post, we can confidently set `topics` to NULL.
    if ([self respondsToSelector:@selector(card)] && self.card.count > 0) {
        self.card.allObjects[0].topics = NULL;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }
}

@end
