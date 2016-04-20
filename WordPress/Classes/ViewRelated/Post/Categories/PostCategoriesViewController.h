#import <UIKit/UIKit.h>
#import "Post.h"
#import "PostCategory.h"

typedef enum {
    CategoriesSelectionModePost = 0,
    CategoriesSelectionModeParent,
    CategoriesSelectionModeBlogDefault
} CategoriesSelectionMode;

@protocol PostCategoriesViewControllerDelegate;


@interface PostCategoriesViewController : UITableViewController

@property (nonatomic, weak) id<PostCategoriesViewControllerDelegate>delegate;

- (instancetype)initWithBlog:(Blog *)blog
            currentSelection:(NSArray *)originalSelection
               selectionMode:(CategoriesSelectionMode)selectionMode;

- (BOOL)hasChanges;

@end


@protocol PostCategoriesViewControllerDelegate <NSObject>

@optional
- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didSelectCategory:(PostCategory *)category;

- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didUpdateSelectedCategories:(NSSet *)categories;

@end
