#import <UIKit/UIKit.h>


typedef void (^BlogSelectorSuccessHandler)(NSManagedObjectID *selectedObjectID);
typedef void (^BlogSelectorSuccessDotComHandler)(NSNumber *dotComId);
typedef void (^BlogSelectorDismissHandler)();

@interface BlogSelectorViewController : UITableViewController

- (instancetype)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                              successHandler:(BlogSelectorSuccessHandler)successHandler
                              dismissHandler:(BlogSelectorDismissHandler)dismissHandler;

- (instancetype)initWithSelectedBlogDotComID:(NSNumber *)dotComID
                              successHandler:(BlogSelectorSuccessDotComHandler)successHandler
                              dismissHandler:(BlogSelectorDismissHandler)dismissHandler;

@property (nonatomic, assign) BOOL displaysPrimaryBlogOnTop;
@property (nonatomic, assign) BOOL displaysOnlyDefaultAccountSites;
@property (nonatomic, assign) BOOL displaysCancelButton;
@property (nonatomic, assign) BOOL dismissOnCancellation;
@property (nonatomic, assign) BOOL dismissOnCompletion;

@end
