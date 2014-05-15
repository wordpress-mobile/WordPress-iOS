#import <UIKit/UIKit.h>

@interface BlogSelectorViewController : UITableViewController <NSFetchedResultsControllerDelegate>

- (id)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                selectedCompletion:(void (^)(NSManagedObjectID *selectedObjectID))selected
                  cancelCompletion:(void (^)())cancel;

@end
