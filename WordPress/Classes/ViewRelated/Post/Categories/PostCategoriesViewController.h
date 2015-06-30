#import <UIKit/UIKit.h>
#import "Post.h"
#import "PostCategory.h"

typedef enum {
    CategoriesSelectionModePost = 0,
    CategoriesSelectionModeParent
} CategoriesSelectionMode;

@protocol PostCategoriesViewControllerDelegate;


@interface PostCategoriesViewController : UITableViewController

@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, weak) id<PostCategoriesViewControllerDelegate>delegate;

- (instancetype)initWithPost:(Post *)post selectionMode:(CategoriesSelectionMode)selectionMode;
- (BOOL)hasChanges;

@end


@protocol PostCategoriesViewControllerDelegate <NSObject>

@optional
- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didSelectCategory:(PostCategory *)category;

@end
