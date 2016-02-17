#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PostListStatusFilter) {
    PostListStatusFilterPublished,
    PostListStatusFilterDraft,
    PostListStatusFilterScheduled,
    PostListStatusFilterTrashed
};

@interface PostListFilter : NSObject

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSDate *oldestPostDate;
@property (nonatomic, assign) PostListStatusFilter filterType;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *statuses;
@property (nonatomic, strong) NSPredicate *predicateForFetchRequest;

+ (NSArray *)newPostListFilters;

@end
