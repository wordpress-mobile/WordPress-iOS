#import <UIKit/UIKit.h>
#import "Post.h"

typedef enum {
    CategoriesSelectionModePost = 0,
    CategoriesSelectionModeParent
} CategoriesSelectionMode;

@protocol CategoriesViewControllerDelegate;


@interface CategoriesViewController : UITableViewController

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, weak) id<CategoriesViewControllerDelegate>delegate;

- (id)initWithPost:(Post *)post selectionMode:(CategoriesSelectionMode)selectionMode;
- (BOOL)hasChanges;

@end


@protocol CategoriesViewControllerDelegate <NSObject>

@optional
- (void)categoriesViewController:(CategoriesViewController *)controller didSelectCategory:(Category *)category;

@end
