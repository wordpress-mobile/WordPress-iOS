#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PostListStatusFilter) {
    PostListStatusFilterPublished,
    PostListStatusFilterDraft,
    PostListStatusFilterScheduled,
    PostListStatusFilterTrashed
};

@interface PostListFilter : NSObject

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong, nullable) NSDate *oldestPostDate;
@property (nonatomic, assign) PostListStatusFilter filterType;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSArray<NSString*>* statuses;
@property (nonatomic, strong, nullable) NSPredicate *predicateForFetchRequest;

+ (nonnull NSArray<PostListFilter*>*)newPostListFilters;

@end
