#import "PostListFilter.h"
#import "BasePost.h"

@interface PostListFilter ()

@end

@implementation PostListFilter

+ (NSArray *)newPostListFilters
{
    return @[
             [self newPublishedFilter],
             [self newDraftFilter],
             [self newScheduledFilter],
             [self newTrashedFilter]
             ];
}

+ (instancetype)newPublishedFilter
{
    PostListFilter *filter = [PostListFilter new];
    filter.title = NSLocalizedString(@"Published", @"Title of the published filter. This filter shows a list of posts that the user has published.");
    filter.statuses = @[PostStatusPublish, PostStatusPrivate];
    filter.filterType = PostListStatusFilterPublished;
    filter.predicateForFetchRequest = [NSPredicate predicateWithFormat:@"status IN %@", filter.statuses];
    return filter;
}

+ (instancetype)newDraftFilter
{
    PostListFilter *filter = [PostListFilter new];
    filter.title = NSLocalizedString(@"Draft", @"Title of the draft filter.  This filter shows a list of draft posts.");
    filter.statuses = @[PostStatusDraft, PostStatusPending];
    filter.filterType = PostListStatusFilterDraft;
    // Exclude known status values. This allows for pending and custom post status to be treated as draft.
    NSArray *excludeStatuses = @[PostStatusPublish, PostStatusPrivate, PostStatusScheduled, PostStatusTrash];
    filter.predicateForFetchRequest = [NSPredicate predicateWithFormat:@"NOT status IN %@", excludeStatuses];
    return filter;
}

+ (instancetype)newScheduledFilter
{
    PostListFilter *filter = [PostListFilter new];
    filter.title = NSLocalizedString(@"Scheduled", @"Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.");
    filter.statuses = @[PostStatusScheduled];
    filter.filterType = PostListStatusFilterScheduled;
    filter.predicateForFetchRequest = [NSPredicate predicateWithFormat:@"status = %@", PostStatusScheduled];
    return filter;
}

+ (instancetype)newTrashedFilter
{
    PostListFilter *filter = [PostListFilter new];
    filter.title = NSLocalizedString(@"Trashed", @"Title of the trashed filter. This filter shows posts that have been moved to the trash bin.");
    filter.statuses = @[PostStatusTrash];
    filter.filterType = PostListStatusFilterTrashed;
    filter.predicateForFetchRequest = [NSPredicate predicateWithFormat:@"status = %@", PostStatusTrash];
    return filter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hasMore = YES;
    }
    return self;
}

@end
