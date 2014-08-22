#import <Foundation/Foundation.h>

@protocol WPContentSyncHelperDelegate;

@interface WPContentSyncHelper : NSObject

@property (nonatomic, weak) id<WPContentSyncHelperDelegate>delegate;
@property (nonatomic, readonly) BOOL isSyncing;
@property (nonatomic, readonly) BOOL isLoadingMore;
@property (nonatomic, readonly) BOOL hasMoreContent;

- (BOOL)syncContent;
- (BOOL)syncContentViaUserInteraction;
- (BOOL)syncContentViaUserInteraction:(BOOL)userInteraction;
- (BOOL)syncMoreContent;

@end

@protocol WPContentSyncHelperDelegate <NSObject>

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userIntraction success:(void (^)(NSUInteger count))success failure:(void (^)(NSError *error))failure;
- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(NSUInteger count))success failure:(void (^)(NSError *error))failure;

@optional

- (void)syncContentEnded;
- (void)hasNoMoreContent;

@end
