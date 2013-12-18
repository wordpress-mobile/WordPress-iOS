#import <UIKit/UIKit.h>

typedef enum _SelectionType {
    kRadio,
    kCheckbox
} WPSelectionType;

@interface WPSelectionTableViewController : UITableViewController

@property (nonatomic, assign) BOOL autoReturnInRadioSelectMode;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) NSMutableArray *selectionStatusOfObjects, *originalSelObjects;
@property (nonatomic, assign) void *curContext;
@property (nonatomic, assign) NSInteger selectionType;
@property (nonatomic, weak) id selectionDelegate;

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate;

- (void *)curContext;
- (BOOL)haveChanges;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL) animated;

- (void)clean;

@end
