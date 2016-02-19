#import <UIKit/UIKit.h>


typedef void (^BlogSelectorSuccessHandler)(NSManagedObjectID *selectedObjectID);
typedef void (^BlogSelectorSuccessDotComHandler)(NSNumber *dotComId);
typedef void (^BlogSelectorDismissHandler)();

@interface BlogSelectorViewController : UITableViewController

- (instancetype)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                          selectedCompletion:(void (^)(NSManagedObjectID *selectedObjectID))selected
                            cancelCompletion:(void (^)())cancel;

@property (nonatomic, assign) BOOL displaysCancelButton;
@property (nonatomic, assign) BOOL dismissOnCancellation;
@property (nonatomic, assign) BOOL dismissOnCompletion;

@end
