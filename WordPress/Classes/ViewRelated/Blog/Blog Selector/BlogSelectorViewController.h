#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef void (^BlogSelectorSuccessHandler)(NSManagedObjectID *selectedObjectID);
typedef void (^BlogSelectorSuccessDotComHandler)(NSNumber *dotComId);
typedef void (^BlogSelectorDismissHandler)(void);

@interface BlogSelectorViewController : UITableViewController

- (instancetype)initWithSelectedBlogObjectID:(nullable NSManagedObjectID *)objectID
                              successHandler:(nullable BlogSelectorSuccessHandler)successHandler
                              dismissHandler:(nullable BlogSelectorDismissHandler)dismissHandler;

- (instancetype)initWithSelectedBlogDotComID:(nullable NSNumber *)dotComID
                              successHandler:(BlogSelectorSuccessDotComHandler)successHandler
                              dismissHandler:(nullable BlogSelectorDismissHandler)dismissHandler;

@property (nonatomic, assign) BOOL displaysOnlyDefaultAccountSites;
@property (nonatomic, assign) BOOL displaysNavigationBarWhenSearching;
@property (nonatomic, assign) BOOL displaysCancelButton;
@property (nonatomic, assign) BOOL dismissOnCancellation;
@property (nonatomic, assign) BOOL dismissOnCompletion;

@property (nonatomic, copy) BlogSelectorSuccessHandler successHandler;

@end

NS_ASSUME_NONNULL_END
