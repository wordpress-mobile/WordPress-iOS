#import <UIKit/UIKit.h>

@class Blog;

@interface BlogDetailsViewController : UITableViewController <UIViewControllerRestoration> {
    
}

@property (nonatomic, strong) Blog *blog;

@end
