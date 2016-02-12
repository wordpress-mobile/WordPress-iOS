#import <UIKit/UIKit.h>

@interface BlogSelectorViewController : UITableViewController

- (instancetype)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                          selectedCompletion:(void (^)(NSManagedObjectID *selectedObjectID))selected
                            cancelCompletion:(void (^)())cancel;

@property (nonatomic, assign) BOOL displaysCancelButton;
@property (nonatomic, assign) BOOL dismissOnCompletion;

@end
