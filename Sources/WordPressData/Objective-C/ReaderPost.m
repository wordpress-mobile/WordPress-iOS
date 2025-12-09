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
