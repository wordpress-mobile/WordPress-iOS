#import <UIKit/UIKit.h>

typedef enum _SelectionType {
    kRadio,
    kCheckbox
} WPSelectionType;

@interface WPSelectionTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *tableView;

    NSArray *objects;
    NSMutableArray *selectionStatusOfObjects, *originalSelObjects;
    id selectionDelegate;
    void *curContext;

    int selectionType;
    BOOL autoReturnInRadioSelectMode;
}

@property (nonatomic, assign) BOOL autoReturnInRadioSelectMode;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) NSMutableArray *selectionStatusOfObjects;
@property (nonatomic, strong) NSMutableArray *originalSelObjects;

- (void)populateDataSource:(NSArray *)sourceObjects havingContext:(void *)context selectedObjects:(NSArray *)selObjects selectionType:(WPSelectionType)aType andDelegate:(id)delegate;

- (NSArray *)selectedObjects;
- (void *)curContext;
- (BOOL)haveChanges;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL) animated;

- (void)clean;

@end
